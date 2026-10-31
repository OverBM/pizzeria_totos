import '../core/format/money.dart';
import 'model_utils.dart';

/// Ítem del carrito: producto + variante + cantidad + precio unitario.
class CartItem {
  const CartItem({
    required this.productId,
    required this.name,
    required this.variantLabel,
    required this.unitPriceSoles,
    required this.quantity,
    this.image,
    this.originalUnitPriceSoles,
  });

  final String productId;
  final String name;
  final String variantLabel;

  /// Precio unitario en soles (con IGV incluido). Incluye promoción.
  final double unitPriceSoles;
  final int quantity;

  /// Referencia de imagen (URL, Drive o asset) para el placeholder/foto.
  final String? image;

  /// Precio unitario original en soles cuando hay promoción aplicada.
  final double? originalUnitPriceSoles;

  /// Clave única de la línea (producto + variante).
  String get key => '$productId|$variantLabel';

  /// Total de la línea, derivado (no se guarda en Firestore).
  double get lineTotalSoles => Money.multiply(unitPriceSoles, quantity);

  /// Subtotal de la línea con el precio de lista (sin promoción).
  double get lineSubtotalSoles =>
      Money.multiply(originalUnitPriceSoles ?? unitPriceSoles, quantity);

  /// Descuento aplicado a la línea por promoción.
  double get lineDiscountSoles =>
      Money.round(lineSubtotalSoles - lineTotalSoles);

  /// ¿La línea tiene precio promocional?
  bool get isOnPromo =>
      originalUnitPriceSoles != null &&
      Money.round(originalUnitPriceSoles!) > Money.round(unitPriceSoles);

  /// Ahorro de la línea en soles (0 si no hay promoción).
  double get savingsSoles => lineDiscountSoles;

  CartItem copyWith({
    int? quantity,
    double? unitPriceSoles,
    double? originalUnitPriceSoles,
  }) => CartItem(
    productId: productId,
    name: name,
    variantLabel: variantLabel,
    unitPriceSoles: unitPriceSoles ?? this.unitPriceSoles,
    quantity: quantity ?? this.quantity,
    image: image,
    originalUnitPriceSoles:
        originalUnitPriceSoles ?? this.originalUnitPriceSoles,
  );

  factory CartItem.fromMap(Map<String, dynamic> json) => CartItem(
    productId: ModelUtils.asString(json['productoId'] ?? json['productId']),
    name: ModelUtils.asString(json['nombre'] ?? json['name']),
    variantLabel: ModelUtils.asString(
      json['etiquetaVariante'] ?? json['variantLabel'],
    ),
    unitPriceSoles: ModelUtils.asMoney(
      json,
      'precioUnitario',
      centsKey: 'unitPriceCents',
    ),
    quantity: ModelUtils.asInt(json['cantidad'] ?? json['quantity'], fallback: 1),
    image: ModelUtils.asStringOrNull(json['imagen'] ?? json['image']),
    originalUnitPriceSoles: ModelUtils.asMoneyOrNull(
      json,
      'precioUnitarioOriginal',
      centsKey: 'originalUnitPriceCents',
    ),
  );

  Map<String, dynamic> toMap() => {
    'productoId': productId,
    'nombre': name,
    'etiquetaVariante': variantLabel,
    'precioUnitario': Money.round(unitPriceSoles),
    'cantidad': quantity,
    if (image != null) 'imagen': image,
    if (originalUnitPriceSoles != null)
      'precioUnitarioOriginal': Money.round(originalUnitPriceSoles!),
  };
}
