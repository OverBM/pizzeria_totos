import 'model_utils.dart';

/// Medio de pago declarado en Firestore (`configuracion/app.mediosPago`).
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.label,
    this.active = true,
  });

  final String id;
  final String label;
  final bool active;

  static const List<PaymentMethod> fallback = [
    PaymentMethod(id: 'efectivo', label: 'EFECTIVO'),
    PaymentMethod(id: 'yape-plin', label: 'YAPE / PLIN'),
  ];

  factory PaymentMethod.fromMap(Map<String, dynamic> json) => PaymentMethod(
    id: ModelUtils.asString(json['id']),
    label: ModelUtils.asString(json['etiqueta'] ?? json['label']),
    active: ModelUtils.asBool(json['activo'] ?? json['active'], fallback: true),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'etiqueta': label,
    'activo': active,
  };
}
