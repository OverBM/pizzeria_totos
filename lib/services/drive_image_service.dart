import '../models/media_ref.dart';

/// Resuelve referencias de imagen de Google Drive a URLs usables.
///
/// Acepta un ID de Drive, un enlace de compartir de Drive o una URL directa.
/// Los enlaces de Drive se sirven mediante el endpoint público de miniaturas,
/// que respeta el ancho solicitado y evita descargar el original completo.
class DriveImageService {
  const DriveImageService._();

  static const String _thumbnailBase = 'https://drive.google.com/thumbnail';

  /// Expresión para extraer el ID de los formatos habituales de Drive:
  /// `/file/d/<id>/view`, `?id=<id>`, `/d/<id>`.
  static final RegExp _filePathId = RegExp(r'/file/d/([a-zA-Z0-9_-]{10,})');
  static final RegExp _shortPathId = RegExp(r'/d/([a-zA-Z0-9_-]{10,})');
  static final RegExp _queryId = RegExp(r'[?&]id=([a-zA-Z0-9_-]{10,})');
  static final RegExp _plainId = RegExp(r'^[a-zA-Z0-9_-]{20,}$');

  /// Extrae un ID de Drive de [value], o `null` si no lo parece.
  static String? extractId(String? value) {
    if (value == null) return null;
    final text = value.trim();
    if (text.isEmpty) return null;
    if (_plainId.hasMatch(text) && !text.contains('.')) return text;
    final pathMatch =
        _filePathId.firstMatch(text) ?? _shortPathId.firstMatch(text);
    if (pathMatch != null) return pathMatch.group(1);
    final queryMatch = _queryId.firstMatch(text);
    if (queryMatch != null) return queryMatch.group(1);
    return null;
  }

  /// Devuelve true si [value] parece una referencia de Drive.
  static bool isDriveReference(String? value) => extractId(value) != null;

  /// Resuelve una [MediaRef] a una URL de imagen lista para `CachedNetworkImage`.
  ///
  /// Prioridad: `driveId` → ID embebido en `url` → `url` directa → `null`.
  static String? resolve(MediaRef? ref, {int width = 800}) {
    if (ref == null || ref.isEmpty) return null;
    final driveId = extractId(ref.driveId) ?? extractId(ref.url);
    if (driveId != null) return thumbnailUrl(driveId, width: width);
    final url = ref.url?.trim();
    if (url != null && url.startsWith(RegExp(r'https?://'))) return url;
    return null;
  }

  /// URL de miniatura pública para un ID de Drive.
  ///
  /// El ancho llega ya resuelto por `DriveImage`:
  /// - miniaturas: `max(ancho, 2 × alto) × DPR`, bucket de 64 px (320-1200),
  ///   para cubrir el recorte de `BoxFit.cover` sin pedir resolución de pantalla;
  /// - fotos a sangre: ancho de pantalla exacto.
  ///
  /// El clamp de 120-2000 es una red de seguridad: no volver a pasar el ancho
  /// de la pantalla para una tarjeta.
  static String thumbnailUrl(String id, {int width = 800}) {
    final safeWidth = width.clamp(120, 2000);
    return '$_thumbnailBase?id=$id&sz=w$safeWidth';
  }
}
