import 'package:flutter/foundation.dart';

import '../core/format/money.dart';
import '../core/storage/cart_storage.dart';
import '../models/cart_item.dart';
import '../models/custom_pizza.dart';
import '../models/masa.dart';
import '../models/product.dart';
import '../models/product_option.dart';
import '../models/variant.dart';
import 'promotion_controller.dart';

/// Carrito local del dispositivo.
///
/// Se conserva al iniciar sesión, al ir al perfil y al cerrar la app.
class CartController extends ChangeNotifier {
  CartController({
    required CartStorage storage,
    required PromotionController promotions,
  }) : _storage = storage,
       _promotions = promotions;

  final CartStorage _storage;
  final PromotionController _promotions;

  List<CartItem> _items = const [];
  bool _loaded = false;
  int _feedbackId = 0;
  String? _feedbackMessage;

  List<CartItem> get items => _items;
  bool get isLoaded => _loaded;
  int get feedbackId => _feedbackId;
  String? get feedbackMessage => _feedbackMessage;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  int get count => _items.fold(0, (total, item) => total + item.quantity);

  /// Subtotal en soles con precios de lista (antes de promociones).
  double get subtotalSoles =>
      Money.sum(_items.map((item) => item.lineSubtotalSoles));

  /// Descuento total por promociones.
  double get discountSoles =>
      Money.sum(_items.map((item) => item.lineDiscountSoles));

  /// Ahorro total en soles. Alias de [discountSoles].
  double get savingsSoles => discountSoles;

  /// Subtotal de productos después de promociones, antes de cupón y envío.
  double get subtotalAfterPromotionsSoles =>
      Money.round(subtotalSoles - discountSoles);

  bool get hasCustomPizza => _items.any((item) => item.isCustomPizza);

  /// Carga del horno en unidades de pizza mediana.
  double get customPizzaWeight => _items.fold<double>(
    0,
    (total, item) =>
        total + (item.customPizza?.ovenWeight ?? 0) * item.quantity,
  );

  /// Tiempo del lote más largo de pizzas personalizadas.
  int get customPizzaBatchMinutes {
    var minutes = 0;
    for (final item in _items) {
      final line = item.customPizza?.preparationMinutes ?? 0;
      if (line > minutes) minutes = line;
    }
    return minutes;
  }

  /// Total en soles: subtotal de lista − descuento + envío.
  double totalSoles({double shippingSoles = 0}) =>
      Money.sum([subtotalSoles, -discountSoles, shippingSoles]);

  Future<void> load() async {
    _items = await _storage.load();
    _loaded = true;
    notifyListeners();
  }

  /// Agrega una variante, aplicando la promoción vigente y los extras.
  void add(
    Product product,
    Variant variant, {
    int quantity = 1,
    MasaType? masa,
    List<ProductExtra> extras = const [],
    List<SelectedComponent> componentes = const [],
  }) {
    final priced = _promotions.priceFor(product, variant);
    final extrasTotal = Money.sum(
      extras.map((extra) => extra.precioSoles),
    );
    final original = Money.round(priced.baseSoles + extrasTotal);
    final price = Money.round(priced.finalSoles + extrasTotal);
    final image =
        product.image?.url ??
        product.image?.driveId ??
        product.image?.assetName;

    final label = variant.label.toUpperCase();
    final candidate = CartItem(
      productId: product.id,
      name: product.name,
      variantLabel: label,
      unitPriceSoles: price,
      quantity: quantity,
      image: image,
      originalUnitPriceSoles: price < original ? original : null,
      masa: masa,
      extras: List.unmodifiable(extras),
      componentes: List.unmodifiable(componentes),
    );
    final index = _items.indexWhere((item) => item.key == candidate.key);
    if (index >= 0) {
      final current = _items[index];
      final next = [..._items];
      next[index] = current.copyWith(quantity: current.quantity + quantity);
      _items = next;
    } else {
      _items = [..._items, candidate];
    }
    _emitFeedback('${product.name} agregado al carrito');
    _persist();
  }

  /// Agrega una pizza personalizada como línea propia.
  void addCustomPizza(
    CustomPizzaSelection selection, {
    int quantity = 1,
  }) {
    final candidate = CartItem(
      productId: 'pizza-personalizada',
      name: 'Pizza personalizada',
      variantLabel: selection.label.toUpperCase(),
      unitPriceSoles: selection.unitPriceSoles,
      quantity: quantity,
      customPizza: selection,
      masa: MasaType.fromValue(selection.dough.id),
      preparationMinutes: selection.preparationMinutes,
    );
    final index = _items.indexWhere((item) => item.key == candidate.key);
    if (index >= 0) {
      final current = _items[index];
      final next = [..._items];
      next[index] = current.copyWith(quantity: current.quantity + quantity);
      _items = next;
    } else {
      _items = [..._items, candidate];
    }
    _emitFeedback('Pizza personalizada agregada al carrito');
    _persist();
  }

  /// Reemplaza una línea personalizada existente.
  void replaceCustomPizza(
    String key,
    CustomPizzaSelection selection, {
    int quantity = 1,
  }) {
    _items = _items.where((item) => item.key != key).toList();
    addCustomPizza(selection, quantity: quantity);
  }

  /// Restaura una línea eliminada (deshacer).
  void restore(CartItem item) {
    if (_items.any((current) => current.key == item.key)) return;
    _items = [..._items, item];
    _persist();
  }

  /// Reemplaza una línea existente por una nueva configuración.
  void replaceLine(
    String key,
    Product product,
    Variant variant, {
    int quantity = 1,
    MasaType? masa,
    List<ProductExtra> extras = const [],
    List<SelectedComponent> componentes = const [],
  }) {
    _items = _items.where((item) => item.key != key).toList();
    add(
      product,
      variant,
      quantity: quantity,
      masa: masa,
      extras: extras,
      componentes: componentes,
    );
  }

  void setQuantity(String key, int quantity) {
    if (quantity <= 0) {
      remove(key);
      return;
    }
    _items = _items
        .map(
          (item) => item.key == key ? item.copyWith(quantity: quantity) : item,
        )
        .toList();
    _persist();
  }

  void increment(String key) {
    final item = _find(key);
    if (item != null) setQuantity(key, item.quantity + 1);
  }

  void decrement(String key) {
    final item = _find(key);
    if (item != null) setQuantity(key, item.quantity - 1);
  }

  void remove(String key) {
    _items = _items.where((item) => item.key != key).toList();
    _persist();
  }

  void _emitFeedback(String message) {
    _feedbackMessage = message;
    _feedbackId += 1;
  }

  Future<void> clear() async {
    _items = const [];
    notifyListeners();
    await _storage.clear();
  }

  CartItem? _find(String key) {
    for (final item in _items) {
      if (item.key == key) return item;
    }
    return null;
  }

  void _persist() {
    notifyListeners();
    _storage.save(_items);
  }
}
