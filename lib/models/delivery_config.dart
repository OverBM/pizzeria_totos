import '../core/format/money.dart';
import 'model_utils.dart';

/// Fórmula de costo de delivery.
///
/// El costo se estima con la distancia en línea recta desde la sede.
/// En Firestore vive en `configuracion/app.delivery`.
class DeliveryConfig {
  const DeliveryConfig({
    required this.baseSoles,
    required this.perKmSoles,
    required this.freeAboveKm,
    this.maxKm,
  });

  static const DeliveryConfig fallback = DeliveryConfig(
    baseSoles: 3,
    perKmSoles: 1.5,
    freeAboveKm: 8,
    maxKm: 15,
  );

  /// Tarifa base en soles.
  final double baseSoles;

  /// Tarifa por kilómetro en soles.
  final double perKmSoles;

  /// Distancia a partir de la cual el envío es gratis.
  final double freeAboveKm;

  /// Distancia máxima de cobertura (opcional).
  final double? maxKm;

  factory DeliveryConfig.fromMap(Map<String, dynamic> json) => DeliveryConfig(
    baseSoles: ModelUtils.asMoney(json, 'base', centsKey: 'baseCents'),
    perKmSoles: ModelUtils.asMoney(json, 'porKm', centsKey: 'perKmCents'),
    freeAboveKm: ModelUtils.asDouble(
      json['gratisDesdeKm'] ?? json['freeAboveKm'],
      fallback: double.infinity,
    ),
    maxKm: ModelUtils.asDoubleOrNull(json['maxKm']),
  );

  /// ¿La distancia está dentro de la cobertura?
  bool isDeliverable(double km) => maxKm == null || km <= maxKm!;

  /// Costo de envío en soles para una distancia dada (km).
  double feeForKm(double km) {
    if (km >= freeAboveKm) return 0;
    final kmCharged = km.ceil();
    return Money.round(baseSoles + kmCharged * perKmSoles);
  }

  Map<String, dynamic> toMap() => {
    'base': Money.round(baseSoles),
    'porKm': Money.round(perKmSoles),
    'gratisDesdeKm': freeAboveKm,
    if (maxKm != null) 'maxKm': maxKm,
  };
}
