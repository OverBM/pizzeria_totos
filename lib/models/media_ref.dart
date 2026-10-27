import 'model_utils.dart';

/// Referencia de una imagen del catálogo.
///
/// Puede ser una URL directa, un ID de Google Drive o el nombre de un asset
/// local de respaldo. El orden de resolución lo decide `DriveImageService`.
class MediaRef {
  const MediaRef({this.url, this.driveId, this.assetName});

  /// URL directa (por ejemplo, un enlace público ya resuelto).
  final String? url;

  /// ID de archivo de Google Drive.
  final String? driveId;

  /// Nombre de archivo dentro de `assets/images/` (respaldo de desarrollo).
  final String? assetName;

  static const MediaRef none = MediaRef();

  bool get isEmpty =>
      (url == null || url!.isEmpty) &&
      (driveId == null || driveId!.isEmpty) &&
      (assetName == null || assetName!.isEmpty);

  bool get isNotEmpty => !isEmpty;

  /// Acepta un mapa `{url|driveId|assetName}` o una cadena suelta.
  static MediaRef? fromValue(Object? value) {
    if (value == null) return null;
    if (value is String) {
      if (value.isEmpty) return null;
      return MediaRef(url: value);
    }
    if (value is Map) {
      return MediaRef.fromMap(Map<String, dynamic>.from(value));
    }
    return null;
  }

  static MediaRef? fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return null;
    final media = MediaRef(
      url: ModelUtils.asStringOrNull(map['url']),
      driveId: ModelUtils.asStringOrNull(map['driveId']),
      assetName: ModelUtils.asStringOrNull(map['assetName']),
    );
    return media.isEmpty ? null : media;
  }

  Map<String, dynamic> toMap() => {
    if (url != null) 'url': url,
    if (driveId != null) 'driveId': driveId,
    if (assetName != null) 'assetName': assetName,
  };

  MediaRef copyWith({String? url, String? driveId, String? assetName}) =>
      MediaRef(
        url: url ?? this.url,
        driveId: driveId ?? this.driveId,
        assetName: assetName ?? this.assetName,
      );
}
