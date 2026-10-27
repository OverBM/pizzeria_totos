import '../models/claim.dart';

/// Contrato de reclamos del usuario.
abstract interface class ClaimRepository {
  Stream<List<Claim>> watchClaims(String uid);

  Future<List<Claim>> fetchClaims(String uid);

  /// Guarda el reclamo y devuelve su id de documento.
  Future<String> createClaim(Claim claim);
}
