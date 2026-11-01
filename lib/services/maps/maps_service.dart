import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/delivery_quote.dart';

/// Centro de Huancayo, usado como encuadre inicial del mapa.
const LatLng huancayoCenter = LatLng(-12.0651, -75.2049);

/// Resultado de una búsqueda de direcciones o de una geocodificación inversa.
class PlaceResult {
  const PlaceResult({required this.label, required this.point, this.detail});

  /// Texto corto para la lista (p. ej. «Av. Giráldez, Huancayo»).
  final String label;

  /// Contexto adicional (provincia, región, país).
  final String? detail;

  final LatLng point;

  String get fullLabel => detail == null ? label : '$label · $detail';
}

/// Contrato de mapas y búsquedas.
///
/// Hoy lo implementa OpenStreetMap (gratis y sin API key). Para migrar a
/// Google Maps basta con crear otra implementación y cambiar [mapsService];
/// las vistas no conocen al proveedor.
abstract class MapsService {
  const MapsService();

  /// Texto de atribución que exige el proveedor.
  String get attribution;

  /// Plantilla de teselas `{z}/{x}/{y}`.
  String get tileUrlTemplate;

  /// Busca direcciones o lugares. Devuelve una lista vacía si no hay
  /// resultados o si el servicio falla (nunca lanza).
  Future<List<PlaceResult>> search(String query, {int limit = 5});

  /// Convierte coordenadas en una dirección legible.
  Future<PlaceResult?> reverse(LatLng point);

  /// Calcula la ruta por calles entre dos puntos.
  ///
  /// Devuelve [MapRoute.empty] si el servicio falla o no hay red.
  Future<MapRoute> route(LatLng from, LatLng to);
}

/// OpenStreetMap: teselas estándar + Nominatim para búsquedas.
///
/// Respeta la política de uso de Nominatim: User-Agent identificable, resultados
/// en caché y como máximo una petición por segundo. La app es una beta de bajo
/// volumen; al migrar a Google Maps esta clase se reemplaza.
class OsmMapsService implements MapsService {
  const OsmMapsService();

  static const String _host = 'nominatim.openstreetmap.org';
  static const String _userAgent = 'TOTOS-Pizza/1.1.1 (com.totos.pizzeria)';

  /// Caja aproximada de Huancayo para priorizar resultados locales.
  static const String _viewbox = '-75.45,-11.95,-75.05,-12.20';

  static final Map<String, List<PlaceResult>> _cache = {};
  static final Map<String, MapRoute> _routeCache = {};
  static const String _osrmHost = 'router.project-osrm.org';

  @override
  String get attribution => '© OpenStreetMap contributors';

  @override
  String get tileUrlTemplate => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  Future<List<PlaceResult>> search(String query, {int limit = 5}) async {
    final text = query.trim();
    if (text.length < 3) return const [];
    final key = '${text.toLowerCase()}|$limit';
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final uri = Uri.https(_host, '/search', {
        'q': text,
        'format': 'jsonv2',
        'limit': '$limit',
        'countrycodes': 'pe',
        'viewbox': _viewbox,
        'bounded': '1',
        'addressdetails': '1',
      });
      final response = await http
          .get(
            uri,
            headers: const {
              'User-Agent': _userAgent,
              'Accept-Language': 'es',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return const [];
      final results = decoded
          .whereType<Map<String, dynamic>>()
          .map(_fromJson)
          .whereType<PlaceResult>()
          .toList();
      _cache[key] = results;

      // Nominatim limita a una petición por segundo.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return results;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<PlaceResult?> reverse(LatLng point) async {
    try {
      final uri = Uri.https(_host, '/reverse', {
        'lat': '${point.latitude}',
        'lon': '${point.longitude}',
        'format': 'jsonv2',
        'addressdetails': '1',
      });
      final response = await http
          .get(
            uri,
            headers: const {
              'User-Agent': _userAgent,
              'Accept-Language': 'es',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return _fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MapRoute> route(LatLng from, LatLng to) async {
    final key =
        '${from.latitude},${from.longitude};${to.latitude},${to.longitude}';
    final cached = _routeCache[key];
    if (cached != null) return cached;
    try {
      final uri = Uri.https(
        _osrmHost,
        '/route/v1/driving/'
            '${from.longitude},${from.latitude};'
            '${to.longitude},${to.latitude}',
        {'overview': 'full', 'geometries': 'geojson'},
      );
      final response = await http
          .get(
            uri,
            headers: const {
              'User-Agent': _userAgent,
              'Accept-Language': 'es',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return MapRoute.empty;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return MapRoute.empty;
      final route = MapRoute.fromOsrmJson(
        Map<String, dynamic>.from(decoded),
      );
      if (route == null) return MapRoute.empty;
      if (_routeCache.length > 50) {
        _routeCache.remove(_routeCache.keys.first);
      }
      _routeCache[key] = route;
      return route;
    } catch (_) {
      return MapRoute.empty;
    }
  }

  PlaceResult? _fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse('${json['lat'] ?? ''}');
    final lng = double.tryParse('${json['lon'] ?? ''}');
    if (lat == null || lng == null) return null;

    final display = (json['display_name'] as String? ?? '').trim();
    if (display.isEmpty) return null;

    final parts = display
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;

    return PlaceResult(
      label: parts.take(2).join(', '),
      detail: parts.length > 2 ? parts.skip(2).join(', ') : null,
      point: LatLng(lat, lng),
    );
  }
}

/// Implementación activa. Cambiar esta línea es todo lo necesario para pasar a
/// Google Maps cuando la API key esté resuelta.
const MapsService mapsService = OsmMapsService();
