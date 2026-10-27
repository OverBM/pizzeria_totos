import '../models/settings.dart';

/// Contrato de configuración del negocio (`settings/app`).
abstract interface class SettingsRepository {
  Future<AppSettings> fetchSettings();

  Stream<AppSettings> watchSettings();
}
