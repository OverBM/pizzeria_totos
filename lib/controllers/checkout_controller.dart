import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../core/format/money.dart';
import '../core/pizza/pizza_timing.dart';
import '../core/pricing/order_pricing.dart';
import '../core/time/lima_time.dart';
import '../core/validation/validators.dart';
import '../models/account.dart';
import '../models/branch.dart';
import '../models/cart_item.dart';
import '../models/checkout_step.dart';
import '../models/delivery_quote.dart';
import '../models/order.dart';
import '../models/payment_method.dart';
import '../repositories/order_repository.dart';
import '../repositories/repository_exception.dart';
import '../services/maps/maps_service.dart';
import '../services/settings_service.dart';
import 'auth_controller.dart';
import 'branch_controller.dart';
import 'cart_controller.dart';
import 'coupon_controller.dart';
import 'subscription_controller.dart';

/// Motivo por el que no se puede confirmar el pedido.
enum CheckoutIssue {
  emptyCart,
  noSession,
  noPhone,
  noAddress,
  noBranch,
  branchWithoutDelivery,
  branchClosed,
  noPaymentMethod,
  noRecipientName,
  noRecipientPhone,
  noDeliveryPoint,
  outOfCoverage,
  routeUnavailable,
  couponInvalid;

  String get message => switch (this) {
    CheckoutIssue.emptyCart => 'Agrega al menos un producto a tu pedido.',
    CheckoutIssue.noSession => 'Inicia sesión para confirmar tu pedido.',
    CheckoutIssue.noPhone =>
      'Completa tu teléfono en el perfil para coordinar la entrega.',
    CheckoutIssue.noAddress => 'Elige o confirma una dirección de entrega.',
    CheckoutIssue.noBranch => 'Elige una sede para tu pedido.',
    CheckoutIssue.branchWithoutDelivery =>
      'La sede elegida no tiene delivery. Elige recojo en tienda.',
    CheckoutIssue.branchClosed =>
      'La sede está cerrada en este horario. Elige otra sede o vuelve dentro '
          'del horario de atención.',
    CheckoutIssue.noPaymentMethod =>
      'No hay medios de pago configurados. Inténtalo de nuevo en un momento.',
    CheckoutIssue.noRecipientName =>
      'Escribe el nombre de la persona que recibe el pedido.',
    CheckoutIssue.noRecipientPhone =>
      'El teléfono del destinatario debe tener 9 dígitos y empezar por 9.',
    CheckoutIssue.noDeliveryPoint =>
      'Confirma el punto de entrega en el mapa para calcular el envío.',
    CheckoutIssue.outOfCoverage =>
      'El punto está fuera del rango de delivery. Elige recojo u otra sede.',
    CheckoutIssue.routeUnavailable =>
      'No pudimos calcular la ruta. Revisa tu conexión e inténtalo de nuevo.',
    CheckoutIssue.couponInvalid =>
      'El cupón ya no es válido. Quítalo o corrige el carrito.',
  };
}

/// Destinatario del pedido.
enum OrderRecipientMode { self, other }

/// Datos del checkout derivados del perfil y del punto de entrega.
class CheckoutController extends ChangeNotifier {
  CheckoutController({
    required OrderRepository orders,
    required CartController cart,
    required AuthController auth,
    required BranchController branches,
    required SettingsService settings,
    required CouponController coupons,
    required SubscriptionController subscriptions,
    MapsService maps = mapsService,
    DateTime Function()? now,
  }) : _orders = orders,
       _cart = cart,
       _auth = auth,
       _branches = branches,
       _settings = settings,
       _coupons = coupons,
       _subscriptions = subscriptions,
       _maps = maps,
       _now = now ?? LimaTime.now;

  final OrderRepository _orders;
  final CartController _cart;
  final AuthController _auth;
  final BranchController _branches;
  final SettingsService _settings;
  final CouponController _coupons;
  final SubscriptionController _subscriptions;
  final MapsService _maps;

  /// Reloj inyectable: en producción usa la hora de Lima; los tests fijan un
  /// instante para que el horario de la sede no vuelva flaky la validación.
  final DateTime Function() _now;

  CheckoutStep _step = CheckoutStep.pedido;
  CheckoutStep _maxStep = CheckoutStep.pedido;
  OrderRecipientMode _recipientMode = OrderRecipientMode.self;
  String _recipientName = '';
  String _recipientPhone = '';

  OrderType _type = OrderType.delivery;
  String? _branchId;
  String? _addressId;
  String? _paymentMethodId;
  DeliveryPoint? _deliveryPoint;
  DeliveryQuote? _deliveryQuote;
  MapRoute? _deliveryRoute;
  bool _quoting = false;
  String? _routeError;
  String _note = '';
  bool _submitting = false;
  String? _error;
  Order? _lastOrder;

  /// ¿El usuario ya eligió (o quitó) una dirección a mano?
  ///
  /// Mientras sea `false`, [initDefaults] puede autoseleccionar la primera
  /// dirección del perfil sin pisar una decisión explícita.
  bool _addressTouched = false;

  /// Descarta respuestas viejas de ruta cuando el punto cambia rápido.
  int _quoteToken = 0;

  /// Mientras se geocodifica una dirección guardada sin coordenadas.
  bool _resolvingAddress = false;
  String? _addressError;

  /// Última dirección para la que ya se pidió geocodificación automática.
  String? _geocodeRequestedFor;

  CheckoutStep get step => _step;

  /// Paso más lejano alcanzado: limita a qué pasos se puede volver.
  CheckoutStep get maxStep => _maxStep;

  OrderRecipientMode get recipientMode => _recipientMode;
  String get recipientName => _recipientName;
  String get recipientPhone => _recipientPhone;
  OrderType get type => _type;
  String? get branchId => _branchId;
  String? get addressId => _addressId;
  String? get paymentMethodId => _paymentMethodId;
  DeliveryPoint? get deliveryPoint => _deliveryPoint;
  DeliveryQuote? get deliveryQuote => _deliveryQuote;
  MapRoute? get deliveryRoute => _deliveryRoute;
  bool get isQuoting => _quoting;
  String? get routeError => _routeError;

  /// ¿Se está ubicando en el mapa la dirección guardada?
  bool get isResolvingAddress => _resolvingAddress;

  /// Problema al ubicar una dirección sin coordenadas.
  String? get addressError => _addressError;

  String get note => _note;
  bool get isSubmitting => _submitting;
  String? get error => _error;
  Order? get lastOrder => _lastOrder;

  Account? get account => _auth.account;
  List<Branch> get branches => _branches.branches;
  List<PaymentMethod> get paymentMethods =>
      _settings.settings.activePaymentMethods;

  Branch? get selectedBranch {
    final id = _branchId;
    if (id != null) {
      final branch = _branches.byId(id);
      if (branch != null) return branch;
    }
    return _branches.defaultBranch;
  }

  Address? get selectedAddress {
    final account = _auth.account;
    if (account == null || account.addresses.isEmpty) return null;
    final id = _addressId;
    if (id == null) return null;
    for (final address in account.addresses) {
      if (address.id == id) return address;
    }
    return null;
  }

  PaymentMethod get selectedPaymentMethod {
    final methods = paymentMethods;
    final id = _paymentMethodId;
    for (final method in methods) {
      if (method.id == id) return method;
    }
    return methods.first;
  }

  String get effectiveRecipientName {
    if (_recipientMode == OrderRecipientMode.other) {
      return _recipientName.trim();
    }
    return _auth.account?.name.trim() ?? '';
  }

  String get effectiveRecipientPhone {
    if (_recipientMode == OrderRecipientMode.other) {
      return _recipientPhone.trim();
    }
    return _auth.account?.phone.trim() ?? '';
  }

  /// Contacto que debe usar el repartidor.
  String get contactName {
    if (_recipientMode == OrderRecipientMode.other &&
        effectiveRecipientPhone.isNotEmpty) {
      return effectiveRecipientName;
    }
    return _auth.account?.name.trim() ?? effectiveRecipientName;
  }

  String get contactPhone {
    if (_recipientMode == OrderRecipientMode.other &&
        effectiveRecipientPhone.isNotEmpty) {
      return effectiveRecipientPhone;
    }
    return _auth.account?.phone.trim() ?? effectiveRecipientPhone;
  }

  String get deliveryAddressLabel {
    if (_type != OrderType.delivery) return '';
    final line = selectedAddress?.line.trim() ?? '';
    if (line.isNotEmpty) return line;
    return _deliveryPoint?.label.trim() ?? '';
  }

  double get shippingOriginalSoles {
    if (_type == OrderType.pickup) return 0;
    final quote = _deliveryQuote;
    if (quote != null) return quote.feeSoles;
    return selectedBranch?.deliveryFeeSoles ?? 0;
  }

  /// Compra mínima del plan pago; 0 si no hay plan.
  double get subscriptionMinimumSoles =>
      _subscriptions.paidPlan?.minimumOrderSoles ?? 20;

  bool get subscriptionBenefitApplies {
    if (_type != OrderType.delivery) return false;
    if (_subscriptions.paidSubscription == null) return false;
    if (_deliveryQuote != null && !_deliveryQuote!.deliverable) return false;
    if (_deliveryPoint == null) return false;
    return _cart.subtotalAfterPromotionsSoles >= subscriptionMinimumSoles;
  }

  double get shippingSoles =>
      subscriptionBenefitApplies ? 0 : shippingOriginalSoles;

  double get subtotalSoles => _cart.subtotalSoles;
  double get promotionDiscountSoles => _cart.discountSoles;
  double get discountSoles => _cart.discountSoles;
  double get savingsSoles => _cart.savingsSoles;
  double get couponDiscountSoles =>
      _coupons.discountFor(_cart.subtotalAfterPromotionsSoles);

  OrderPricing get pricing => OrderPricing.calculate(
    subtotalSoles: subtotalSoles,
    promotionDiscountSoles: promotionDiscountSoles,
    couponDiscountSoles: couponDiscountSoles,
    shippingOriginalSoles: shippingOriginalSoles,
    shippingCovered: subscriptionBenefitApplies,
  );

  double get totalSoles => pricing.totalSoles;
  List<CartItem> get items => _cart.items;

  /// Minutos de preparación del pedido, con capacidad por sede.
  int get preparationMinutes {
    if (!_cart.hasCustomPizza) {
      return _settings.settings.delivery.preparationMinutes;
    }
    final branch = selectedBranch;
    return PizzaTiming.preparationMinutes(
      batchMinutes: _cart.items
          .where((item) => item.isCustomPizza)
          .map((item) => item.preparationMinutes)
          .toList(),
      ovenWeight: _cart.customPizzaWeight,
      ovenCapacity: branch?.ovenCapacity ?? 4,
      recoveryMinutes: branch?.recoveryMinutes ?? 0,
      baseMinutes: _settings.settings.delivery.preparationMinutes,
      measured: branch?.hasOvenMeasurement ?? false,
    );
  }

  int? get effectiveEtaMinutes => _deliveryQuote?.etaMinutes;

  double? get deliveryDistanceKm => _deliveryQuote?.distanceKm;
  String get deliveryBandLabel => _deliveryQuote?.bandLabel ?? '';
  int? get deliveryEtaMinutes => _deliveryQuote?.etaMinutes;
  bool get deliveryEstimated => _deliveryQuote?.isEstimated ?? false;

  void setStep(CheckoutStep step) {
    if (_step == step) return;
    _step = step;
    if (step.index > _maxStep.index) _maxStep = step;
    notifyListeners();
  }

  /// Marca un paso como alcanzado para habilitar la navegación hacia atrás.
  void reachStep(CheckoutStep step) {
    if (_step == step && step.index <= _maxStep.index) return;
    _step = step;
    if (step.index > _maxStep.index) _maxStep = step;
    notifyListeners();
  }

  void setRecipientMode(OrderRecipientMode mode) {
    if (_recipientMode == mode) return;
    _recipientMode = mode;
    notifyListeners();
  }

  void setRecipientName(String value) {
    _recipientName = value;
  }

  void setRecipientPhone(String value) {
    _recipientPhone = value;
  }

  /// Selecciona valores iniciales cuando las sedes ya están cargadas.
  ///
  /// La dirección del perfil se autoselecciona solo si el usuario no eligió ni
  /// quitó una dirección a mano; así puede deseleccionarla y usar el mapa.
  void initDefaults() {
    _branchId ??= _branches.defaultBranch?.id;
    var changed = false;
    if (!_addressTouched) {
      final addresses = _auth.account?.addresses ?? const <Address>[];
      if (addresses.isEmpty) {
        if (_addressId != null) {
          _addressId = null;
          changed = true;
        }
      } else {
        final current = _addressId;
        final hasCurrent =
            current != null && addresses.any((a) => a.id == current);
        final address = hasCurrent
            ? addresses.firstWhere((a) => a.id == current)
            : addresses.first;
        if (_addressId != address.id) {
          _addressId = address.id;
          changed = true;
        }
        if (_deliveryPoint == null && address.hasPoint) {
          _deliveryPoint = DeliveryPoint(
            lat: address.lat!,
            lng: address.lng!,
            label: address.line,
          );
          changed = true;
        } else if (_deliveryPoint == null &&
            _geocodeRequestedFor != address.id) {
          _geocodeRequestedFor = address.id;
          _locateAddress(address);
        }
      }
    }
    if (_paymentMethodId == null && paymentMethods.isNotEmpty) {
      _paymentMethodId = paymentMethods.first.id;
    }
    if (_type == OrderType.pickup) {
      _deliveryQuote = DeliveryQuote.pickup;
    }
    notifyListeners();
    if (_type == OrderType.delivery && (changed || _deliveryQuote == null)) {
      quoteDelivery();
    }
  }

  void setType(OrderType type) {
    if (_type == type) return;
    _type = type;
    _deliveryRoute = null;
    _deliveryQuote = type == OrderType.pickup ? DeliveryQuote.pickup : null;
    _routeError = null;
    notifyListeners();
    if (type == OrderType.delivery) quoteDelivery();
  }

  void selectBranch(String branchId) {
    _branchId = branchId;
    final branch = _branches.byId(branchId);
    if (_type == OrderType.delivery && branch != null && !branch.delivers) {
      _type = OrderType.pickup;
    }
    _deliveryRoute = null;
    _deliveryQuote = _type == OrderType.pickup ? DeliveryQuote.pickup : null;
    _routeError = null;
    notifyListeners();
    if (_type == OrderType.delivery) quoteDelivery();
  }

  Future<void> selectAddress(String addressId) async {
    _addressId = addressId;
    _addressTouched = true;
    _addressError = null;
    _resolvingAddress = false;
    final address = selectedAddress;
    if (address == null) {
      _deliveryPoint = null;
      _deliveryRoute = null;
      _deliveryQuote = null;
      _routeError = null;
      notifyListeners();
      return;
    }
    if (address.hasPoint) {
      _applyDeliveryPoint(
        DeliveryPoint(
          lat: address.lat!,
          lng: address.lng!,
          label: address.line,
        ),
      );
      return;
    }
    await _locateAddress(address);
  }

  /// Busca en el mapa una dirección guardada que no tiene coordenadas.
  ///
  /// Las direcciones antiguas solo guardaban el texto; al elegirlas se
  /// geocodifican para poder dibujar la ruta.
  Future<void> _locateAddress(Address address) async {
    final id = address.id;
    _resolvingAddress = true;
    _addressError = null;
    _deliveryPoint = null;
    _deliveryRoute = null;
    _deliveryQuote = null;
    _routeError = null;
    notifyListeners();
    final results = await _maps.search(address.line, limit: 1);
    if (_addressId != id) return;
    _resolvingAddress = false;
    if (results.isEmpty) {
      _addressError =
          'No pudimos ubicar «${address.line}» en el mapa. '
          'Elige el punto manualmente.';
      notifyListeners();
      return;
    }
    final place = results.first;
    _applyDeliveryPoint(
      DeliveryPoint(
        lat: place.point.latitude,
        lng: place.point.longitude,
        label: address.line,
      ),
    );
  }

  void _applyDeliveryPoint(DeliveryPoint point) {
    _deliveryPoint = point;
    _deliveryRoute = null;
    _routeError = null;
    notifyListeners();
    if (_type == OrderType.delivery) quoteDelivery();
  }

  /// Quita la dirección guardada para elegir otro punto en el mapa.
  void clearAddress() {
    if (_addressId == null && _deliveryPoint == null) return;
    _addressId = null;
    _addressTouched = true;
    setDeliveryPoint(null);
  }

  void setDeliveryPoint(DeliveryPoint? point) {
    _deliveryPoint = point;
    _addressId = null;
    _addressTouched = true;
    _addressError = null;
    _resolvingAddress = false;
    _deliveryRoute = null;
    _routeError = null;
    if (point == null) {
      _deliveryQuote = _type == OrderType.pickup ? DeliveryQuote.pickup : null;
      notifyListeners();
      return;
    }
    notifyListeners();
    if (_type == OrderType.delivery) quoteDelivery();
  }

  void selectPaymentMethod(String methodId) {
    _paymentMethodId = methodId;
    notifyListeners();
  }

  Future<bool> applyCoupon(String code) async {
    final ok = await _coupons.apply(
      code: code,
      baseSoles: _cart.subtotalAfterPromotionsSoles,
      uid: _auth.uid.isEmpty ? null : _auth.uid,
    );
    notifyListeners();
    return ok;
  }

  void removeCoupon() {
    _coupons.clear();
    notifyListeners();
  }

  void setNote(String note) {
    _note = note;
  }

  /// Calcula ruta, tramo, envío y ETA para el punto actual.
  Future<void> quoteDelivery() async {
    final token = ++_quoteToken;
    if (_type == OrderType.pickup) {
      _deliveryQuote = DeliveryQuote.pickup;
      _deliveryRoute = null;
      _routeError = null;
      _quoting = false;
      notifyListeners();
      return;
    }
    final branch = selectedBranch;
    if (branch == null) {
      _deliveryQuote = null;
      _routeError = null;
      notifyListeners();
      return;
    }
    final point = _deliveryPoint;
    if (point == null) {
      _deliveryQuote = DeliveryQuote(
        distanceKm: 0,
        feeSoles: branch.deliveryFeeSoles,
        deliverable: true,
        etaMinutes: 0,
        isEstimated: true,
        source: DeliveryQuoteSource.flatFee,
      );
      _deliveryRoute = null;
      _routeError = null;
      _quoting = false;
      notifyListeners();
      return;
    }
    _quoting = true;
    _routeError = null;
    notifyListeners();
    final route = await _maps.route(
      LatLng(branch.lat, branch.lng),
      point.latLng,
    );
    if (token != _quoteToken) return;
    if (route.isEmpty) {
      _quoting = false;
      _deliveryRoute = null;
      _deliveryQuote = null;
      _routeError = CheckoutIssue.routeUnavailable.message;
      notifyListeners();
      return;
    }
    _deliveryRoute = route;
    _deliveryQuote = _settings.settings.delivery.quoteForKm(
      route.distanceKm,
      routeMinutes: route.durationMinutes,
      preparationMinutesOverride: preparationMinutes,
    );
    _quoting = false;
    notifyListeners();
  }

  /// Valida solo el paso indicado.
  List<CheckoutIssue> validateStep(CheckoutStep step) {
    switch (step) {
      case CheckoutStep.pedido:
        final issues = <CheckoutIssue>[];
        if (_cart.isEmpty) issues.add(CheckoutIssue.emptyCart);
        if (_recipientMode == OrderRecipientMode.other) {
          if (Validators.nameError(_recipientName) != null) {
            issues.add(CheckoutIssue.noRecipientName);
          }
          if (_recipientPhone.trim().isNotEmpty &&
              Validators.phoneError(_recipientPhone) != null) {
            issues.add(CheckoutIssue.noRecipientPhone);
          }
        }
        return issues;
      case CheckoutStep.entrega:
        return _deliveryIssues();
      case CheckoutStep.confirmar:
        return validate();
    }
  }

  List<CheckoutIssue> _deliveryIssues() {
    final issues = <CheckoutIssue>[];
    final branch = selectedBranch;
    if (branch == null) {
      issues.add(CheckoutIssue.noBranch);
      return issues;
    }
    if (!branch.isOpenAt(_now())) {
      issues.add(CheckoutIssue.branchClosed);
    }
    if (_type == OrderType.delivery) {
      if (!branch.delivers) {
        issues.add(CheckoutIssue.branchWithoutDelivery);
      }
      if (deliveryAddressLabel.trim().isEmpty) {
        issues.add(CheckoutIssue.noAddress);
      }
      if (_deliveryPoint == null) {
        issues.add(CheckoutIssue.noDeliveryPoint);
      }
      final quote = _deliveryQuote;
      if (quote != null && !quote.deliverable) {
        issues.add(CheckoutIssue.outOfCoverage);
      }
      if (_routeError != null || quote == null) {
        issues.add(CheckoutIssue.routeUnavailable);
      }
    }
    return issues;
  }

  /// Comprueba todos los datos antes de confirmar.
  List<CheckoutIssue> validate() {
    final issues = <CheckoutIssue>[];
    issues.addAll(validateStep(CheckoutStep.pedido));
    issues.addAll(_deliveryIssues());
    if (!_auth.isSignedIn) issues.add(CheckoutIssue.noSession);
    if (contactPhone.trim().isEmpty) issues.add(CheckoutIssue.noPhone);
    if (paymentMethods.isEmpty) issues.add(CheckoutIssue.noPaymentMethod);
    if (_coupons.hasCoupon &&
        _coupons.validate(_cart.subtotalAfterPromotionsSoles) != null) {
      issues.add(CheckoutIssue.couponInvalid);
    }
    return issues;
  }

  bool get canSubmit => validate().isEmpty;

  /// Registra el pedido en Firestore y vacía el carrito.
  Future<Order?> submit() async {
    final issues = validate();
    if (issues.isNotEmpty) {
      _error = issues.first.message;
      notifyListeners();
      return null;
    }

    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      final account = _auth.account;
      final branch = selectedBranch;
      if (account == null) {
        _error = CheckoutIssue.noSession.message;
        return null;
      }
      if (branch == null) {
        _error = CheckoutIssue.noBranch.message;
        return null;
      }
      if (paymentMethods.isEmpty) {
        _error = CheckoutIssue.noPaymentMethod.message;
        return null;
      }

      final address = selectedAddress;
      final payment = selectedPaymentMethod;
      final quote = _deliveryQuote;
      final point = _deliveryPoint;
      final now = DateTime.now();
      final order = Order(
        id: '',
        code: _codeFor(now),
        uid: account.uid,
        createdAt: now,
        type: _type,
        branchId: branch.id,
        branchName: branch.name,
        items: List.unmodifiable(_cart.items),
        subtotalSoles: subtotalSoles,
        shippingSoles: shippingSoles,
        discountSoles: Money.sum([promotionDiscountSoles, couponDiscountSoles]),
        savingsSoles: promotionDiscountSoles,
        totalSoles: totalSoles,
        couponCode: _coupons.applied?.coupon.code,
        promotionDiscountSoles: promotionDiscountSoles,
        couponDiscountSoles: couponDiscountSoles,
        shippingOriginalSoles: shippingOriginalSoles,
        subscriptionApplied: subscriptionBenefitApplies,
        subscriptionPlanId: subscriptionBenefitApplies
            ? _subscriptions.paidSubscription?.planId
            : null,
        preparationMinutes: preparationMinutes,
        customerName: account.name,
        phone: contactPhone,
        paymentMethodId: payment.id,
        paymentMethodLabel: payment.label,
        address: _type == OrderType.delivery ? deliveryAddressLabel : null,
        reference: _type == OrderType.delivery ? address?.reference : null,
        note: _note.trim().isEmpty ? null : _note.trim(),
        paraOtraPersona: _recipientMode == OrderRecipientMode.other,
        receptorNombre: effectiveRecipientName.isEmpty
            ? null
            : effectiveRecipientName,
        receptorTelefono: effectiveRecipientPhone.isEmpty
            ? null
            : effectiveRecipientPhone,
        contactoPrincipalNombre: contactName.isEmpty ? null : contactName,
        contactoPrincipalTelefono: contactPhone.isEmpty ? null : contactPhone,
        lat: point?.lat,
        lng: point?.lng,
        distanciaKm: quote?.distanceKm,
        tramo: quote?.bandLabel,
        etaMinutos: quote?.etaMinutes,
        envioEstimado: quote?.isEstimated ?? false,
      );
      final appliedCoupon = _coupons.applied;
      final id = await _orders.createOrder(
        order,
        couponCode: appliedCoupon?.coupon.code,
        couponUid: appliedCoupon == null ? null : account.uid,
        registerShipment: subscriptionBenefitApplies,
      );
      final saved = Order.fromMap({...order.toMap(), 'id': id}, id: id);
      await _cart.clear();
      _coupons.clear();
      _lastOrder = saved;
      _resetDraft(keepLastOrder: true);
      return saved;
    } catch (error) {
      _error = error is RepositoryException
          ? error.message
          : 'No se pudo registrar el pedido.';
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// Limpia el borrador sin tocar el carrito.
  void resetDraft() => _resetDraft();

  void _resetDraft({bool keepLastOrder = false}) {
    _step = CheckoutStep.pedido;
    _maxStep = CheckoutStep.pedido;
    _recipientMode = OrderRecipientMode.self;
    _recipientName = '';
    _recipientPhone = '';
    _deliveryPoint = null;
    _deliveryQuote = null;
    _deliveryRoute = null;
    _routeError = null;
    _quoting = false;
    _quoteToken++;
    _note = '';
    _addressId = null;
    _addressTouched = false;
    _addressError = null;
    _resolvingAddress = false;
    _geocodeRequestedFor = null;
    _coupons.clear();
    if (!keepLastOrder) _lastOrder = null;
    initDefaults();
  }

  Future<void> markWhatsappSent(Order order) =>
      _orders.markWhatsappSent(order.id);

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  String _codeFor(DateTime instant) {
    final lima = LimaTime.at(instant);
    final date = '${lima.year}${_two(lima.month)}${_two(lima.day)}';
    final suffix = (instant.millisecondsSinceEpoch % 10000).toString().padLeft(
      4,
      '0',
    );
    return 'TOT-$date-$suffix';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// Texto de resumen reutilizable por la vista de confirmación.
  String get totalLabel => Money.format(totalSoles);
}
