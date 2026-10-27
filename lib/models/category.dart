import 'model_utils.dart';

/// Categoría de la carta (`categorias/{id}`).
class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    required this.order,
    this.active = true,
  });

  final String id;
  final String name;
  final int order;
  final bool active;

  /// Categoría virtual de destacados (no tiene productos propios).
  static const String featuredId = 'mas-pedidas';

  bool get isFeatured => id == featuredId;

  factory MenuCategory.fromMap(Map<String, dynamic> json) => MenuCategory(
    id: ModelUtils.asString(json['id']),
    name: ModelUtils.asString(json['nombre'] ?? json['name']),
    order: ModelUtils.asInt(json['orden'] ?? json['order']),
    active: ModelUtils.asBool(json['activa'] ?? json['active'], fallback: true),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': name,
    'orden': order,
    'activa': active,
  };
}
