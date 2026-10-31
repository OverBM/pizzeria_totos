import 'package:flutter/foundation.dart';

import '../core/format/money.dart';
import '../core/storage/cart_storage.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
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

  List<CartItem> get items => _items;
  bool get isLoaded => _loaded;
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

  /// Total en soles: subtotal de lista − descuento + envío.
  double totalSoles({double shippingSoles = 0}) =>
      Money.sum([subtotalSoles, -discountSoles, shippingSoles]);

  Future<void> load() async {
    _items = await _storage.load();
    _loaded = true;
    notifyListeners();
  }

  /// Agrega una variante, aplicando la promoción vigente si existe.
  void add(Product product, Variant variant, {int quantity = 1}) {
    final priced = _promotions.priceFor(product, variant);
    final original = priced.baseSoles;
    final price = priced.finalSoles;
    final image =
        product.image?.url ??
        product.image?.driveId ??
        product.image?.assetName;

    final label = variant.label.toUpperCase();
    final key = '${product.id}|$label';
    final index = _items.indexWhere((item) => item.key == key);
    if (index >= 0) {
      final current = _items[index];
      final next = [..._items];
      next[index] = current.copyWith(quantity: current.quantity + quantity);
      _items = next;
    } else {
      _items = [
        ..._items,
        CartItem(
          productId: product.id,
          name: product.name,
          variantLabel: label,
          unitPriceSoles: price,
          quantity: quantity,
          image: image,
          originalUnitPriceSoles: price < original ? original : null,
        ),
      ];
    }
    _persist();
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
