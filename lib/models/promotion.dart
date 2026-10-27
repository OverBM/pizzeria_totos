import '../core/format/money.dart';
import '../core/time/lima_time.dart';
import 'media_ref.dart';
import 'model_utils.dart';
import 'product.dart';
import 'variant.dart';

/// Promoción de la carta cargada desde `promociones` de Firestore.
///
/// El descuento puede ser un porcentaje (`descuentoPorcentaje`) o un precio fijo
/// (`precio`). La vigencia se evalúa en hora `America/Lima`.
class Promotion {
  const Promotion({
    required this.id,
    required this.title,
    required this.productId,
    this.subtitle,
    this.variantLabel,
    this.discountPercent,
    this.priceSoles,
    this.image,
    this.startsAt,
    this.endsAt,
    this.banner = true,
    this.active = true,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String productId;

  /// Variante concreta a la que aplica; si es null, aplica a cualquier variante.
  final String? variantLabel;

  /// Porcentaje de descuento (0-100) o null.
  final int? discountPercent;

  /// Precio promocional fijo en soles o null.
  final double? priceSoles;

  /// Imagen editorial (Drive o asset de respaldo).
  final MediaRef? image;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// ¿Se muestra como banner en el inicio/pantalla de promociones?
  final bool banner;
  final bool active;

  /// ¿Modifica el precio del producto?
  bool get appliesToPrice => discountPercent != null || priceSoles != null;

  bool get hasImage => image != null && image!.isNotEmpty;

  /// Precio promocional en soles para un precio base dado.
  ///
  /// Un precio fijo manda sobre el porcentaje.
  double discountedPrice(double basePriceSoles) {
    final fixed = priceSoles;
    if (fixed != null) return Money.round(fixed);
    final percent = discountPercent;
    if (percent == null) return Money.round(basePriceSoles);
    return Money.applyDiscountPercent(
      basePriceSoles,
      percent.clamp(0, 100),
    );
  }

  /// ¿La promoción aplica a esta variante del producto?
  bool matches(String productId, String variantLabel) =>
      this.productId == productId &&
      (this.variantLabel == null || this.variantLabel == variantLabel);

  /// ¿El descuento sirve para cualquier variante del producto?
  bool get appliesToAnyVariant => variantLabel == null;

  /// Variante del producto sobre la que se calcula el precio promocional.
  ///
  /// Si la promoción fija una variante existente, se usa esa. Si no fija
  /// variante —o si la variante ya no existe en el catálogo— se usa la más
  /// barata, para que el precio tachado y el promocional correspondan siempre
  /// a la misma variante que se agrega al carrito.
  Variant? variantFor(Product product) {
    final label = variantLabel;
    if (label != null) {
      final target = product.variantForLabel(label);
      if (target != null) return target;
    }
    return product.cheapestVariant;
  }

  /// Precio sin descuento que corresponde a esta promoción.
  double basePriceFor(Product product) =>
      variantFor(product)?.priceSoles ?? 0;

  /// Precio promocional del producto, ya aplicado sobre su variante.
  double priceFor(Product product) => discountedPrice(basePriceFor(product));

  /// ¿Está vigente en una hora de pared de Lima (`DateTime` sin zona)?
  bool isActive(DateTime limaWallClock) {
    if (!active) return false;
    final start = startsAt;
    if (start != null && limaWallClock.isBefore(start)) return false;
    final end = endsAt;
    if (end != null && limaWallClock.isAfter(end)) return false;
    return true;
  }

  /// ¿Está vigente ahora, en hora de Lima?
  bool get isActiveNow => isActive(LimaTime.now());

  /// Copia con otra imagen, para la herencia desde el producto.
  Promotion withImage(MediaRef? next) => Promotion(
    id: id,
    title: title,
    subtitle: subtitle,
    productId: productId,
    variantLabel: variantLabel,
    discountPercent: discountPercent,
    priceSoles: priceSoles,
    image: next ?? image,
    startsAt: startsAt,
    endsAt: endsAt,
    banner: banner,
    active: active,
  );

  factory Promotion.fromMap(Map<String, dynamic> json) => Promotion(
    id: ModelUtils.asString(json['id']),
    title: ModelUtils.asString(json['titulo'] ?? json['title']),
    subtitle: ModelUtils.asStringOrNull(json['subtitulo'] ?? json['subtitle']),
    productId: ModelUtils.asString(json['productoId'] ?? json['productId']),
    variantLabel: ModelUtils.asStringOrNull(
      json['etiquetaVariante'] ?? json['variantLabel'],
    ),
    discountPercent: ModelUtils.asIntOrNull(
      json['descuentoPorcentaje'] ?? json['discountPercent'],
    ),
    priceSoles: ModelUtils.asMoneyOrNull(
      json,
      'precio',
      centsKey: 'priceCents',
    ),
    image: MediaRef.fromValue(json['imagen'] ?? json['image']),
    startsAt: ModelUtils.asDateTime(json['desde'] ?? json['startsAt']),
    endsAt: ModelUtils.asDateTime(json['hasta'] ?? json['endsAt']),
    banner: ModelUtils.asBool(json['banner'], fallback: true),
    active: ModelUtils.asBool(json['activa'] ?? json['active'], fallback: true),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'titulo': title,
    if (subtitle != null) 'subtitulo': subtitle,
    'productoId': productId,
    if (variantLabel != null) 'etiquetaVariante': variantLabel,
    if (discountPercent != null) 'descuentoPorcentaje': discountPercent,
    if (priceSoles != null) 'precio': Money.round(priceSoles!),
    if (image != null) 'imagen': image!.toMap(),
    if (startsAt != null) 'desde': startsAt!.toIso8601String(),
    if (endsAt != null) 'hasta': endsAt!.toIso8601String(),
    'banner': banner,
    'activa': active,
  };
}
