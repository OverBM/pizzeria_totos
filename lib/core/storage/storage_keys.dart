/// Claves de persistencia local versionadas.
///
/// Patrón `totos.<dominio>.v1`: al cambiar el formato de un dominio se sube la
/// versión y se ignora el formato anterior (sin migración destructiva).
class StorageKeys {
  const StorageKeys._();

  /// Carrito local (se conserva al iniciar sesión y al ir al perfil).
  static const String cart = 'totos.cart.v2';

  /// Último tab visitado del shell.
  static const String lastTab = 'totos.lastTab.v1';

  /// Caché del perfil para arranques sin red.
  static const String profileCache = 'totos.profile.v2';

  /// Pedidos locales de la beta anterior, en solo lectura.
  static const String legacyOrders = 'totos.orders.v1';

  /// Reclamos locales de la beta anterior, en solo lectura.
  static const String legacyClaims = 'totos.claims.v1';
}
