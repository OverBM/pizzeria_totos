import '../models/account.dart';

/// Contrato de autenticación con email y contraseña.
abstract interface class AuthRepository {
  /// Cuenta autenticada actualmente, o `null` si no hay sesión.
  Account? get currentAccount;

  /// Emite la cuenta al iniciar o cerrar sesión.
  Stream<Account?> authStateChanges();

  Future<Account> signIn({required String email, required String password});

  Future<Account> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  Future<void> deleteAccount();
}
