import '../core/format/money.dart';
import 'delivery_quote.dart';
import 'model_utils.dart';

/// Fórmula de costo de delivery.
///
/// El costo se estima con la distancia real por calles desde la sede. En
/// Firestore vive en `configuracion/app.delivery`.
class DeliveryConfig {
  const DeliveryConfig({
    required this.baseSoles,
    required this.perKmSoles,
    required this.freeAboveKm,
    this.maxKm,
    this.tramos = const [],
    this.preparationMinutes = 20,
    this.marginMinutes = 5,
  });

  static const DeliveryConfig fallback = DeliveryConfig(
    baseSoles: 3,
    perKmSoles: 1.5,
    freeAboveKm: double.infinity,
    maxKm: 8,
    tramos: [
      DeliveryBand(numero: 1, desdeKm: 0, hastaKm: 2, costoSoles: 4),
      DeliveryBand(numero: 2, desdeKm: 2, hastaKm: 4, costoSoles: 6),
      DeliveryBand(numero: 3, desdeKm: 4, hastaKm: 6, costoSoles: 8),
      DeliveryBand(numero: 4, desdeKm: 6, hastaKm: 8, costoSoles: 10),
    ],
  );

  /// Tarifa base en soles.
  final double baseSoles;

  /// Tarifa por kilómetro en soles.
  final double perKmSoles;

  /// Distancia a partir de la cual el envío es gratis.
  final double freeAboveKm;

  /// Distancia máxima de cobertura (opcional).
  final double? maxKm;

  /// Tramos configurados. Si está vacío se usa base + por km.
  final List<DeliveryBand> tramos;

  /// Minutos de preparación que se suman al ETA.
  final int preparationMinutes;

  /// Margen de seguridad que se suma al ETA.
  final int marginMinutes;

  factory DeliveryConfig.fromMap(Map<String, dynamic> json) {
    final rawTramos = ModelUtils.asMapList(json['tramos']);
    final tramos = <DeliveryBand>[];
    for (var i = 0; i < rawTramos.length; i++) {
      final band = DeliveryBand.fromMap(rawTramos[i], numero: i + 1);
      if (band.hastaKm > band.desdeKm) tramos.add(band);
    }
    tramos.sort((a, b) => a.desdeKm.compareTo(b.desdeKm));
    return DeliveryConfig(
      baseSoles: ModelUtils.asMoney(json, 'base', centsKey: 'baseCents'),
      perKmSoles: ModelUtils.asMoney(
        json,
        'porKm',
        centsKey: 'perKmCents',
      ),
      freeAboveKm: ModelUtils.asDouble(
        json['gratisDesdeKm'] ?? json['freeAboveKm'],
        fallback: double.infinity,
      ),
      maxKm: ModelUtils.asDoubleOrNull(json['maxKm']),
      tramos: tramos,
      preparationMinutes: ModelUtils.asInt(
        json['preparacionMin'] ?? json['preparationMinutes'],
        fallback: 20,
      ),
      marginMinutes: ModelUtils.asInt(
        json['margenMin'] ?? json['marginMinutes'],
        fallback: 5,
      ),
    );
  }

  /// ¿La distancia está dentro de la cobertura?
  bool isDeliverable(double km) => maxKm == null || km <= maxKm!;

  /// Costo de envío en soles para una distancia dada (km).
  double feeForKm(double km) {
    if (km >= freeAboveKm) return 0;
    final kmCharged = km.ceil();
    return Money.round(baseSoles + kmCharged * perKmSoles);
  }

  /// Cotiza el envío para [km] de ruta.
  ///
  /// [routeMinutes] es la duración de la ruta; [estimated] marca la tarifa
  /// plana de respaldo cuando todavía no hay un punto confirmado.
  DeliveryQuote quoteForKm(
    double km, {
    int routeMinutes = 0,
    bool estimated = false,
    int? preparationMinutesOverride,
  }) {
    final prep = preparationMinutesOverride ?? preparationMinutes;
    if (!isDeliverable(km)) {
      return DeliveryQuote(
        distanceKm: km,
        feeSoles: 0,
        deliverable: false,
        etaMinutes: _roundEta(routeMinutes + prep + marginMinutes),
        isEstimated: estimated,
        source: estimated
            ? DeliveryQuoteSource.flatFee
            : DeliveryQuoteSource.route,
      );
    }
    final band = _bandFor(km);
    final fee = km >= freeAboveKm
        ? 0.0
        : band?.costoSoles ?? feeForKm(km);
    return DeliveryQuote(
      distanceKm: km,
      feeSoles: Money.round(fee),
      deliverable: true,
      etaMinutes: _roundEta(routeMinutes + prep + marginMinutes),
      isEstimated: estimated,
      source: estimated
          ? DeliveryQuoteSource.flatFee
          : DeliveryQuoteSource.route,
      band: band,
    );
  }

  DeliveryBand? _bandFor(double km) {
    for (final band in tramos) {
      if (band.contains(km)) return band;
    }
    return null;
  }

  static int _roundEta(int minutes) {
    if (minutes <= 0) return 0;
    return ((minutes + 4) ~/ 5) * 5;
  }

  Map<String, dynamic> toMap() => {
    'base': Money.round(baseSoles),
    'porKm': Money.round(perKmSoles),
    'gratisDesdeKm': freeAboveKm,
    if (maxKm != null) 'maxKm': maxKm,
    if (tramos.isNotEmpty) 'tramos': tramos.map((t) => t.toMap()).toList(),
    if (preparationMinutes != 20) 'preparacionMin': preparationMinutes,
    if (marginMinutes != 5) 'margenMin': marginMinutes,
  };
}
