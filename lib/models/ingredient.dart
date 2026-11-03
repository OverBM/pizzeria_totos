import 'model_utils.dart';

/// Ingrediente disponible para la pizza personalizada.
///
/// En Firestore vive en `ingredientes/{id}`.
class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.category,
    required this.priceSoles,
    this.available = true,
    this.allergens = const [],
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String category;
  final double priceSoles;
  final bool available;
  final List<String> allergens;
  final int sortOrder;

  factory Ingredient.fromMap(Map<String, dynamic> json) => Ingredient(
    id: ModelUtils.asString(json['id']),
    name: ModelUtils.asString(json['nombre'] ?? json['name']),
    category: ModelUtils.asString(
      json['categoria'] ?? json['category'],
      fallback: 'otros',
    ),
    priceSoles: ModelUtils.asMoney(json, 'precio', centsKey: 'priceCents'),
    available: ModelUtils.asBool(
      json['disponible'] ?? json['available'],
      fallback: true,
    ),
    allergens: ModelUtils.asStringList(
      json['alergenos'] ?? json['allergens'],
    ),
    sortOrder: ModelUtils.asInt(json['orden'] ?? json['sortOrder']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': name,
    'categoria': category,
    'precio': priceSoles,
    'disponible': available,
    'alergenos': allergens,
    'orden': sortOrder,
  };

  @override
  bool operator ==(Object other) =>
      other is Ingredient && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
