/// Contrato para resolver y reclamar aliases.
abstract interface class AliasRepository {
  /// Devuelve el correo asociado al alias, o `null` si no existe.
  Future<String?> emailForAlias(String alias);

  /// Reserva un alias para el usuario; falla si ya existe.
  Future<void> claimAlias({
    required String uid,
    required String alias,
    required String email,
  });

  /// Libera un alias si pertenece al usuario.
  Future<void> releaseAlias({required String uid, required String alias});

  /// Alias actual del usuario, si existe.
  Future<String?> aliasForUid(String uid);

  /// Alias sugerido a partir de la parte local del correo.
  String suggestFromEmail(String email);

  /// Genera un alias único agregando sufijo si está ocupado.
  Future<String> uniqueAlias(String base);
}
