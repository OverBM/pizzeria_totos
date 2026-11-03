import '../core/format/money.dart';
import 'custom_pizza.dart';
import 'masa.dart';
import 'model_utils.dart';
import 'product_option.dart';

/// Ítem del carrito: producto + variante + masa + extras + cantidad.
class CartItem {
  const CartItem({
    required this.productId,
    required this.name,
    required this.variantLabel,
    required this.unitPriceSoles,
    required this.quantity,
    this.image,
    this.originalUnitPriceSoles,
    this.masa,
    this.extras = const [],
    this.componentes = const [],
    this.customPizza,
    this.preparationMinutes = 0,
  });

  final String productId;
  final String name;
  final String variantLabel;

  /// Precio unitario final en soles (con IGV, promoción y extras).
  final double unitPriceSoles;
  final int quantity;

  /// Referencia de imagen (URL, Drive o asset) para el placeholder/foto.
  final String? image;

  /// Precio unitario original en soles cuando hay promoción aplicada.
  final double? originalUnitPriceSoles;

  /// Masa elegida, si el producto la ofrece.
  final MasaType? masa;

  /// Extras elegidos para esta línea.
  final List<ProductExtra> extras;

  /// Componentes elegidos de un combo.
  final List<SelectedComponent> componentes;

  /// Pizza personalizada, si esta línea no viene del catálogo.
  final CustomPizzaSelection? customPizza;

  /// Minutos de preparación del lote de esta línea.
  final int preparationMinutes;

  bool get isCustomPizza => customPizza != null;

  /// Suma de extras por unidad.
  double get extrasSoles =>
      Money.sum(extras.map((extra) => extra.precioSoles));

  /// Clave única de la línea. Conserva el formato histórico cuando no hay
  /// configuración extra para no romper carritos guardados.
  String get key {
    final base = '$productId|$variantLabel';
    final parts = <String>[
      if (masa != null) 'masa=${masa!.value}',
      if (extras.isNotEmpty)
        'extras=${extras.map((e) => e.nombre).join(',')}',
      if (componentes.isNotEmpty)
        'componentes=${componentes.map((c) => '${c.nombre}:${c.opcion ?? ''}').join(',')}',
      if (customPizza != null) 'custom=${customPizza!.signature}',
    ];
    return parts.isEmpty ? base : '$base|${parts.join('|')}';
  }

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
    MasaType? masa,
    List<ProductExtra>? extras,
    List<SelectedComponent>? componentes,
  }) => CartItem(
    productId: productId,
    name: name,
    variantLabel: variantLabel,
    unitPriceSoles: unitPriceSoles ?? this.unitPriceSoles,
    quantity: quantity ?? this.quantity,
    image: image,
    originalUnitPriceSoles:
        originalUnitPriceSoles ?? this.originalUnitPriceSoles,
    masa: masa ?? this.masa,
    extras: extras ?? this.extras,
    componentes: componentes ?? this.componentes,
    customPizza: customPizza,
    preparationMinutes: preparationMinutes,
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
    masa: MasaType.fromValue(
      ModelUtils.asStringOrNull(json['masa'] ?? json['dough']),
    ),
    extras: ModelUtils.asMapList(json['extras'])
        .map(ProductExtra.fromMap)
        .toList(),
    componentes: ModelUtils.asMapList(json['componentes'] ?? json['components'])
        .map(SelectedComponent.fromMap)
        .toList(),
    customPizza: json['customPizza'] is Map
        ? CustomPizzaSelection.fromMap(
            Map<String, dynamic>.from(json['customPizza'] as Map),
          )
        : null,
    preparationMinutes: ModelUtils.asInt(
      json['preparationMinutes'] ?? json['minutosPreparacion'],
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
    if (masa != null) 'masa': masa!.value,
    if (extras.isNotEmpty) 'extras': extras.map((e) => e.toMap()).toList(),
    if (componentes.isNotEmpty)
      'componentes': componentes.map((c) => c.toMap()).toList(),
    if (customPizza != null) 'customPizza': customPizza!.toMap(),
    if (preparationMinutes > 0) 'preparationMinutes': preparationMinutes,
  };
}
