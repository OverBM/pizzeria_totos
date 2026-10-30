import 'media_ref.dart';
import 'model_utils.dart';
import 'variant.dart';

/// Producto de la carta con una o más variantes.
///
/// En Firestore vive en `productos/{id}` con los campos en español.
class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.variants,
    this.image,
    this.tags = const [],
    this.available = true,
    this.featured = false,
    this.ingredients = const [],
    this.allergens = const [],
    this.calories,
    this.portion,
    this.summary,
    this.gallery = const [],
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;

  /// Imagen principal (Drive o asset de respaldo).
  final MediaRef? image;
  final List<String> tags;
  final bool available;
  final bool featured;
  final List<Variant> variants;

  /// Datos opcionales de la ficha de producto.
  final List<String> ingredients;
  final List<String> allergens;
  final int? calories;
  final String? portion;

  /// Resumen corto para la tarjeta, distinto de [description].
  final String? summary;

  /// Imágenes extra para la galería del detalle.
  final List<MediaRef> gallery;

  bool get hasVariants => variants.length > 1;

  /// Texto corto de la tarjeta; si no hay `resumen`, usa la descripción.
  String get displaySummary {
    final short = summary?.trim();
    if (short != null && short.isNotEmpty) return short;
    return description;
  }

  bool get hasDetail =>
      ingredients.isNotEmpty ||
      allergens.isNotEmpty ||
      calories != null ||
      (portion != null && portion!.isNotEmpty);

  /// Imágenes a mostrar en el detalle: la principal más la galería.
  List<MediaRef> get images => [
    if (image != null && image!.isNotEmpty) image!,
    ...gallery.where((g) => g.isNotEmpty),
  ];

  /// ¿Se puede agregar al carrito?
  ///
  /// Un producto disponible sin variantes no es vendible: se muestra con el
  /// estado «No disponible», pero no inventa un precio ni una acción de compra.
  bool get isSellable => available && variants.isNotEmpty;

  /// Variante a usar cuando no hay elección, o `null` si no hay variantes.
  ///
  /// Evita la excepción de `variants.first` con documentos incompletos.
  Variant? get defaultVariantOrNull => variants.isEmpty ? null : variants.first;

  /// Variante más barata, o `null` si no hay variantes.
  Variant? get cheapestVariant {
    if (variants.isEmpty) return null;
    return variants.reduce(
      (a, b) => b.priceSoles < a.priceSoles ? b : a,
    );
  }

  /// Variante con [label] (sin distinguir mayúsculas), o `null`.
  Variant? variantForLabel(String? label) {
    if (label == null) return null;
    final target = label.toLowerCase();
    for (final variant in variants) {
      if (variant.label.toLowerCase() == target) return variant;
    }
    return null;
  }

  /// Precio más bajo en soles, para mostrar en la tarjeta.
  double get minPriceSoles => cheapestVariant?.priceSoles ?? 0;

  factory Product.fromMap(Map<String, dynamic> json) => Product(
    id: ModelUtils.asString(json['id']),
    categoryId: ModelUtils.asString(json['categoriaId'] ?? json['categoryId']),
    name: ModelUtils.asString(json['nombre'] ?? json['name']),
    description: ModelUtils.asString(
      json['descripcion'] ?? json['description'],
    ),
    image: MediaRef.fromValue(json['imagen'] ?? json['image']),
    tags: ModelUtils.asStringList(json['etiquetas'] ?? json['tags']),
    available: ModelUtils.asBool(
      json['disponible'] ?? json['available'],
      fallback: true,
    ),
    featured: ModelUtils.asBool(json['destacado'] ?? json['featured']),
    ingredients: ModelUtils.asStringList(
      json['ingredientes'] ?? json['ingredients'],
    ),
    allergens: ModelUtils.asStringList(json['alergenos'] ?? json['allergens']),
    calories: ModelUtils.asIntOrNull(json['calorias'] ?? json['calories']),
    portion: ModelUtils.asStringOrNull(json['porcion'] ?? json['portion']),
    summary: ModelUtils.asStringOrNull(json['resumen'] ?? json['summary']),
    gallery: ModelUtils.asMapList(json['galeria'] ?? json['gallery'])
        .map(MediaRef.fromMap)
        .whereType<MediaRef>()
        .toList(),
    variants: ModelUtils.asMapList(
      json['variantes'] ?? json['variants'],
    ).map(Variant.fromMap).toList(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'categoriaId': categoryId,
    'nombre': name,
    'descripcion': description,
    if (image != null) 'imagen': image!.toMap(),
    'etiquetas': tags,
    'disponible': available,
    'destacado': featured,
    if (ingredients.isNotEmpty) 'ingredientes': ingredients,
    if (allergens.isNotEmpty) 'alergenos': allergens,
    if (calories != null) 'calorias': calories,
    if (portion != null) 'porcion': portion,
    if (summary != null) 'resumen': summary,
    if (gallery.isNotEmpty) 'galeria': gallery.map((g) => g.toMap()).toList(),
    'variantes': variants.map((v) => v.toMap()).toList(),
  };
}
