import '../models/account.dart';

/// Contrato del perfil del usuario (`users/{uid}`).
abstract interface class ProfileRepository {
  /// Escucha el perfil del usuario autenticado.
  Stream<Account?> watchProfile(String uid);

  Future<Account?> fetchProfile(String uid);

  /// Crea el perfil si no existe; nunca toca el campo `role`.
  Future<void> ensureProfile({
    required String uid,
    required String name,
    required String email,
  });

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phone,
    List<Address>? addresses,
  });

  Future<Address> addAddress({required String uid, required Address address});

  Future<void> removeAddress({required String uid, required String addressId});
}
