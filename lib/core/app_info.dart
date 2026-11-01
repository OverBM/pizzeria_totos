/// Versión publicada de la app, en un único lugar.
///
/// `pubspec.yaml` debe declarar exactamente [pubspecVersion]; la prueba
/// `test/core/app_info_test.dart` lo verifica para que el número no se
/// desincronice entre el APK y la etiqueta que ve el usuario.
class AppInfo {
  const AppInfo._();

  /// `versionName` del APK y parte visible de la etiqueta.
  static const String version = '1.4.0';

  /// `versionCode` base (el `+5` de `pubspec.yaml`). No se pinta en la UI.
  static const int build = 5;

  /// Etiqueta visible en el pie del perfil: exactamente `V1.4.0`.
  static const String label = 'V$version';

  /// Línea completa de `pubspec.yaml`, útil para la prueba de sincronización.
  static const String pubspecVersion = '$version+$build';
}
