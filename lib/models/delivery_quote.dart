import 'package:latlong2/latlong.dart';

import '../core/format/money.dart';
import 'model_utils.dart';

/// Tramo de costo de delivery por distancia.
class DeliveryBand {
  const DeliveryBand({
    required this.desdeKm,
    required this.hastaKm,
    required this.costoSoles,
    this.numero = 0,
  });

  final int numero;
  final double desdeKm;
  final double hastaKm;
  final double costoSoles;

  bool contains(double km) => km >= desdeKm && km <= hastaKm;

  String get rangeLabel => '${_km(desdeKm)}–${_km(hastaKm)} km';

  String get label =>
      numero > 0 ? 'Tramo $numero · $rangeLabel' : 'Tramo · $rangeLabel';

  factory DeliveryBand.fromMap(Map<String, dynamic> json, {int numero = 0}) =>
      DeliveryBand(
        numero: ModelUtils.asInt(json['numero'] ?? json['index'], fallback: numero),
        desdeKm: ModelUtils.asDouble(json['desdeKm'] ?? json['fromKm']),
        hastaKm: ModelUtils.asDouble(json['hastaKm'] ?? json['toKm']),
        costoSoles: ModelUtils.asMoney(
          json,
          'costo',
          centsKey: 'costoCents',
        ),
      );

  Map<String, dynamic> toMap() => {
    if (numero > 0) 'numero': numero,
    'desdeKm': desdeKm,
    'hastaKm': hastaKm,
    'costo': Money.round(costoSoles),
  };

  static String _km(double value) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return text.replaceAll('.', ',');
  }
}

enum DeliveryQuoteSource { route, flatFee, pickup }

/// Resultado de cotizar el envío para un punto.
class DeliveryQuote {
  const DeliveryQuote({
    required this.distanceKm,
    required this.feeSoles,
    required this.deliverable,
    required this.etaMinutes,
    required this.isEstimated,
    required this.source,
    this.band,
  });

  final double distanceKm;
  final double feeSoles;
  final bool deliverable;
  final int etaMinutes;
  final bool isEstimated;
  final DeliveryQuoteSource source;
  final DeliveryBand? band;

  static const DeliveryQuote pickup = DeliveryQuote(
    distanceKm: 0,
    feeSoles: 0,
    deliverable: true,
    etaMinutes: 0,
    isEstimated: false,
    source: DeliveryQuoteSource.pickup,
  );

  String get bandLabel => band?.label ?? '';

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';
}

/// Punto de entrega elegido en el mapa o guardado en una dirección.
class DeliveryPoint {
  const DeliveryPoint({
    required this.lat,
    required this.lng,
    this.label = '',
  });

  final double lat;
  final double lng;
  final String label;

  LatLng get latLng => LatLng(lat, lng);

  bool get hasCoordinates => lat != 0 || lng != 0;

  factory DeliveryPoint.fromMap(Map<String, dynamic> json) => DeliveryPoint(
    lat: ModelUtils.asDouble(json['lat']),
    lng: ModelUtils.asDouble(json['lng']),
    label: ModelUtils.asString(json['label'] ?? json['etiqueta']),
  );

  Map<String, dynamic> toMap() => {
    'lat': lat,
    'lng': lng,
    if (label.isNotEmpty) 'label': label,
  };
}

/// Ruta por calles devuelta por OSRM.
class MapRoute {
  const MapRoute({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.points,
  });

  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> points;

  double get distanceKm => distanceMeters / 1000;

  int get durationMinutes => (durationSeconds / 60).ceil();

  bool get isEmpty => points.isEmpty;

  static const MapRoute empty = MapRoute(
    distanceMeters: 0,
    durationSeconds: 0,
    points: [],
  );

  /// Lee la respuesta de OSRM (`route/v1/driving` con GeoJSON).
  static MapRoute? fromOsrmJson(Map<String, dynamic> json) {
    final routes = json['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final route = routes.first;
    if (route is! Map) return null;
    final distance = (route['distance'] as num?)?.toDouble();
    final duration = (route['duration'] as num?)?.toDouble();
    final geometry = route['geometry'];
    final coordinates = geometry is Map ? geometry['coordinates'] : null;
    if (distance == null || duration == null || coordinates is! List) {
      return null;
    }
    final points = <LatLng>[];
    for (final item in coordinates) {
      if (item is List && item.length >= 2) {
        final lng = (item[0] as num?)?.toDouble();
        final lat = (item[1] as num?)?.toDouble();
        if (lat != null && lng != null) points.add(LatLng(lat, lng));
      }
    }
    return MapRoute(
      distanceMeters: distance,
      durationSeconds: duration,
      points: points,
    );
  }
}
