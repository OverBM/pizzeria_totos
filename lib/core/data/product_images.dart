import 'package:flutter/services.dart';

/// Resuelve las fotos locales de respaldo en `assets/images/products/`.
///
/// La fuente principal es Firestore (enlaces de Drive). Este manifiesto solo
/// alimenta la cadena de respaldo Drive → asset → placeholder de marca.
class ProductImages {
  const ProductImages._();

  static Map<String, String> _byId = <String, String>{};
  static bool _loaded = false;

  static const String _prefix = 'assets/images/products/';
  static const Set<String> _exts = {'png', 'jpg', 'jpeg', 'webp'};

  /// Carga el manifiesto de assets una vez. Se llama al arrancar la app.
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final map = <String, String>{};
      for (final key in manifest.listAssets()) {
        if (!key.startsWith(_prefix)) continue;
        final file = key.substring(_prefix.length);
        final dot = file.lastIndexOf('.');
        if (dot <= 0) continue;
        final ext = file.substring(dot + 1).toLowerCase();
        if (!_exts.contains(ext)) continue;
        final id = file.substring(0, dot);
        if (id.startsWith('.')) continue; // ignora .gitkeep
        map[id] = key;
      }
      _byId = map;
    } catch (_) {
      _byId = <String, String>{};
    }
    _loaded = true;
  }

  /// Ruta del asset para un id de producto, o `null` si no hay foto.
  static String? pathFor(String id) => _byId[id];

  /// Solo para pruebas.
  static void debugSet(Map<String, String> images) {
    _byId = images;
    _loaded = true;
  }
}
