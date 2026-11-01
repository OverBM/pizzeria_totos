import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Motivo por el que no se pudo obtener la ubicaciÃ³n.
enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unavailable;

  String get message => switch (this) {
    LocationFailure.serviceDisabled =>
      'Activa la ubicaciÃ³n del dispositivo para usar el mapa.',
    LocationFailure.permissionDenied =>
      'No diste permiso de ubicaciÃ³n. Puedes buscar tu direcciÃ³n manualmente.',
    LocationFailure.permissionDeniedForever =>
      'El permiso de ubicaciÃ³n estÃ¡ bloqueado. Ãbrelo en los ajustes.',
    LocationFailure.timeout =>
      'No pudimos obtener tu ubicaciÃ³n. IntÃ©ntalo de nuevo.',
    LocationFailure.unavailable =>
      'La ubicaciÃ³n no estÃ¡ disponible en este momento.',
  };
}

/// Resultado de pedir la ubicaciÃ³n actual.
class LocationResult {
  const LocationResult({this.point, this.failure});

  final LatLng? point;
  final LocationFailure? failure;

  bool get isSuccess => point != null;

  LocationResult.success(LatLng this.point) : failure = null;

  LocationResult.error(LocationFailure this.failure) : point = null;
}

/// Contrato de ubicaciÃ³n nativa. Se inyecta para poder probar sin GPS.
abstract class LocationService {
  const LocationService();

  Future<LocationResult> current({
    Duration timeout = const Duration(seconds: 10),
  });

  Future<bool> openSettings();
}

/// ImplementaciÃ³n con `geolocator`.
class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationResult> current({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationResult.error(LocationFailure.serviceDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return LocationResult.error(LocationFailure.permissionDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationResult.error(
          LocationFailure.permissionDeniedForever,
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return LocationResult.success(
        LatLng(position.latitude, position.longitude),
      );
    } on TimeoutException {
      return LocationResult.error(LocationFailure.timeout);
    } on LocationServiceDisabledException {
      return LocationResult.error(LocationFailure.serviceDisabled);
    } on PermissionDeniedException {
      return LocationResult.error(LocationFailure.permissionDenied);
    } catch (_) {
      return LocationResult.error(LocationFailure.unavailable);
    }
  }

  @override
  Future<bool> openSettings() => Geolocator.openAppSettings();
}

