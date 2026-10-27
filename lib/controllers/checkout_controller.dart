import 'package:flutter/foundation.dart';

import '../core/format/money.dart';
import '../core/time/lima_time.dart';
import '../models/account.dart';
import '../models/branch.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/payment_method.dart';
import '../repositories/order_repository.dart';
import '../repositories/repository_exception.dart';
import '../services/settings_service.dart';
import 'auth_controller.dart';
import 'branch_controller.dart';
import 'cart_controller.dart';

/// Motivo por el que no se puede confirmar el pedido.
enum CheckoutIssue {
  emptyCart,
  noSession,
  noPhone,
  noAddress,
  noBranch,
  branchWithoutDelivery,
  branchClosed;

  String get message => switch (this) {
    CheckoutIssue.emptyCart => 'Agrega al menos un producto a tu pedido.',
    CheckoutIssue.noSession => 'Inicia sesión para confirmar tu pedido.',
    CheckoutIssue.noPhone =>
      'Completa tu teléfono en el perfil para coordinar la entrega.',
    CheckoutIssue.noAddress => 'Agrega una dirección de entrega en tu perfil.',
    CheckoutIssue.noBranch => 'Elige una sede para tu pedido.',
    CheckoutIssue.branchWithoutDelivery =>
      'La sede elegida no tiene delivery. Elige recojo en tienda.',
    CheckoutIssue.branchClosed =>
      'La sede está cerrada en este horario. Elige otra sede o vuelve dentro '
          'del horario de atención.',
  };
}

/// Datos del checkout derivados del perfil: no se piden de nuevo aquí.
class CheckoutController extends ChangeNotifier {
  CheckoutController({
    required OrderRepository orders,
    required CartController cart,
    required AuthController auth,
    required BranchController branches,
    required SettingsService settings,
    DateTime Function()? now,
  }) : _orders = orders,
       _cart = cart,
       _auth = auth,
       _branches = branches,
       _settings = settings,
       _now = now ?? LimaTime.now;

  final OrderRepository _orders;
  final CartController _cart;
  final AuthController _auth;
  final BranchController _branches;
  final SettingsService _settings;

  /// Reloj inyectable: en producción usa la hora de Lima; los tests fijan un
  /// instante para que el horario de la sede no vuelva flaky la validación.
  final DateTime Function() _now;

  OrderType _type = OrderType.delivery;
  String? _branchId;
  String? _addressId;
  String? _paymentMethodId;
  String _note = '';
  bool _submitting = false;
  String? _error;
  Order? _lastOrder;

  OrderType get type => _type;
  String? get branchId => _branchId;
  String? get addressId => _addressId;
  String? get paymentMethodId => _paymentMethodId;
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
    if (id == null) return account.defaultAddress;
    for (final address in account.addresses) {
      if (address.id == id) return address;
    }
    return account.defaultAddress;
  }

  PaymentMethod get selectedPaymentMethod {
    final methods = paymentMethods;
    final id = _paymentMethodId;
    for (final method in methods) {
      if (method.id == id) return method;
    }
    return methods.first;
  }

  double get shippingSoles {
    if (_type == OrderType.pickup) return 0;
    return selectedBranch?.deliveryFeeSoles ?? 0;
  }

  double get subtotalSoles => _cart.subtotalSoles;
  double get savingsSoles => _cart.savingsSoles;
  double get totalSoles => _cart.totalSoles(shippingSoles: shippingSoles);
  List<CartItem> get items => _cart.items;

  /// Selecciona valores iniciales cuando las sedes ya están cargadas.
  void initDefaults() {
    _branchId ??= _branches.defaultBranch?.id;
    if (_addressId == null) {
      final addresses = _auth.account?.addresses ?? const <Address>[];
      if (addresses.isNotEmpty) _addressId = addresses.first.id;
    }
    if (_paymentMethodId == null && paymentMethods.isNotEmpty) {
      _paymentMethodId = paymentMethods.first.id;
    }
    notifyListeners();
  }

  void setType(OrderType type) {
    if (_type == type) return;
    _type = type;
    notifyListeners();
  }

  void selectBranch(String branchId) {
    _branchId = branchId;
    final branch = _branches.byId(branchId);
    if (_type == OrderType.delivery && branch != null && !branch.delivers) {
      _type = OrderType.pickup;
    }
    notifyListeners();
  }

  void selectAddress(String addressId) {
    _addressId = addressId;
    notifyListeners();
  }

  void selectPaymentMethod(String methodId) {
    _paymentMethodId = methodId;
    notifyListeners();
  }

  void setNote(String note) {
    _note = note;
  }

  /// Comprueba los datos derivados del perfil antes de confirmar.
  List<CheckoutIssue> validate() {
    final issues = <CheckoutIssue>[];
    if (_cart.isEmpty) issues.add(CheckoutIssue.emptyCart);
    if (!_auth.isSignedIn) issues.add(CheckoutIssue.noSession);
    final branch = selectedBranch;
    if (branch == null) issues.add(CheckoutIssue.noBranch);
    if (branch != null && !branch.isOpenAt(_now())) {
      issues.add(CheckoutIssue.branchClosed);
    }
    if (_type == OrderType.delivery) {
      if (!_auth.hasPhone) issues.add(CheckoutIssue.noPhone);
      if (!_auth.hasAddress) issues.add(CheckoutIssue.noAddress);
      if (branch != null && !branch.delivers) {
        issues.add(CheckoutIssue.branchWithoutDelivery);
      }
    }
    return issues;
  }

  bool get canSubmit => validate().isEmpty;

  /// Registra el pedido en Firestore y vacía el carrito.
  ///
  /// Devuelve `null` si falta algún dato o falla la escritura.
  Future<Order?> submit() async {
    final issues = validate();
    if (issues.isNotEmpty) {
      _error = issues.first.message;
      notifyListeners();
      return null;
    }
    final account = _auth.account!;
    final branch = selectedBranch!;
    final address = selectedAddress;
    final payment = selectedPaymentMethod;

    _submitting = true;
    _error = null;
    notifyListeners();
    try {
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
        totalSoles: totalSoles,
        customerName: account.name,
        phone: account.phone,
        paymentMethodId: payment.id,
        paymentMethodLabel: payment.label,
        address: _type == OrderType.delivery ? address?.line : null,
        reference: _type == OrderType.delivery ? address?.reference : null,
        note: _note.trim().isEmpty ? null : _note.trim(),
        savingsSoles: savingsSoles,
      );
      final id = await _orders.createOrder(order);
      final saved = Order.fromMap({...order.toMap(), 'id': id}, id: id);
      await _cart.clear();
      _lastOrder = saved;
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
