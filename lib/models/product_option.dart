import '../core/format/money.dart';
import 'model_utils.dart';

/// Ingrediente adicional que se puede agregar a un producto.
class ProductExtra {
  const ProductExtra({required this.nombre, required this.precioSoles});

  final String nombre;
  final double precioSoles;

  factory ProductExtra.fromMap(Map<String, dynamic> json) => ProductExtra(
    nombre: ModelUtils.asString(json['nombre'] ?? json['name']),
    precioSoles: ModelUtils.asMoney(
      json,
      'precio',
      centsKey: 'precioCents',
    ),
  );

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'precio': Money.round(precioSoles),
  };

  @override
  bool operator ==(Object other) =>
      other is ProductExtra &&
      other.nombre == nombre &&
      Money.equals(other.precioSoles, precioSoles);

  @override
  int get hashCode => Object.hash(nombre, Money.round(precioSoles));
}

/// Parte que compone un combo (pizza, bebida, etc.).
class ProductComponent {
  const ProductComponent({
    required this.nombre,
    required this.cantidad,
    this.opciones = const [],
  });

  final String nombre;
  final int cantidad;
  final List<String> opciones;

  factory ProductComponent.fromMap(Map<String, dynamic> json) =>
      ProductComponent(
        nombre: ModelUtils.asString(json['nombre'] ?? json['name']),
        cantidad: ModelUtils.asInt(json['cantidad'] ?? json['quantity'], fallback: 1),
        opciones: ModelUtils.asStringList(json['opciones'] ?? json['options']),
      );

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'cantidad': cantidad,
    if (opciones.isNotEmpty) 'opciones': opciones,
  };
}

/// Componente de un combo ya elegido por el usuario.
class SelectedComponent {
  const SelectedComponent({
    required this.nombre,
    required this.cantidad,
    this.opcion,
  });

  final String nombre;
  final int cantidad;
  final String? opcion;

  factory SelectedComponent.fromMap(Map<String, dynamic> json) =>
      SelectedComponent(
        nombre: ModelUtils.asString(json['nombre'] ?? json['name']),
        cantidad: ModelUtils.asInt(
          json['cantidad'] ?? json['quantity'],
          fallback: 1,
        ),
        opcion: ModelUtils.asStringOrNull(json['opcion'] ?? json['option']),
      );

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'cantidad': cantidad,
    if (opcion != null) 'opcion': opcion,
  };

  @override
  bool operator ==(Object other) =>
      other is SelectedComponent &&
      other.nombre == nombre &&
      other.cantidad == cantidad &&
      other.opcion == opcion;

  @override
  int get hashCode => Object.hash(nombre, cantidad, opcion);
}
