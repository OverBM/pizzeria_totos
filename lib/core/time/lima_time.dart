import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Hora oficial de TOTO'S en `America/Lima`, independiente de la zona del
/// dispositivo (el negocio atiende en hora de Perú).
class LimaTime {
  const LimaTime._();

  static const String zoneId = 'America/Lima';
  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    _initialized = true;
  }

  static tz.Location get location {
    ensureInitialized();
    return tz.getLocation(zoneId);
  }

  /// Ahora en hora de Lima.
  static tz.TZDateTime now() => tz.TZDateTime.now(location);

  /// Convierte un instante a hora de Lima.
  static tz.TZDateTime at(DateTime instant) =>
      tz.TZDateTime.from(instant, location);
}
