import '../models/settings.dart';
import '../repositories/settings_repository.dart';
import '../repositories/repository_exception.dart';

/// Acceso a la configuración del negocio con caché en memoria.
class SettingsService {
  SettingsService({required SettingsRepository repository})
    : _repository = repository;

  final SettingsRepository _repository;
  AppSettings _settings = AppSettings.fallback;
  bool _loaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _loaded;

  /// Número de WhatsApp efectivo (placeholder si Firestore no lo define).
  String get whatsapp => _settings.effectiveWhatsapp;
  String get phone => _settings.phone;
  String get heroImageUrl => '';

  /// Carpeta pública de Drive donde el negocio sube las fotos.
  ///
  /// `null` si el campo no está configurado; en ese caso la UI no muestra el
  /// enlace (evita un enlace roto).
  String? get driveFolderUrl {
    final url = _settings.driveFolderUrl?.trim();
    return (url == null || url.isEmpty) ? null : url;
  }

  bool get hasDriveFolder => driveFolderUrl != null;

  Future<AppSettings> load() async {
    try {
      _settings = await _repository.fetchSettings();
      _loaded = true;
    } on RepositoryException {
      _loaded = true;
    } catch (_) {
      _loaded = true;
    }
    return _settings;
  }

  Stream<AppSettings> watch() => _repository.watchSettings();

  void apply(AppSettings settings) {
    _settings = settings;
    _loaded = true;
  }
}
