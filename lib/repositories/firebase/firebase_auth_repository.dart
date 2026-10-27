import 'package:firebase_auth/firebase_auth.dart';

import '../../models/account.dart';
import '../auth_repository.dart';
import '../repository_exception.dart';

/// Autenticación con Firebase Auth (email y contraseña).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Account? get currentAccount {
    final user = _auth.currentUser;
    return user == null ? null : _toAccount(user);
  }

  @override
  Stream<Account?> authStateChanges() => _auth.authStateChanges().map(
    (user) => user == null ? null : _toAccount(user),
  );

  @override
  Future<Account> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const RepositoryException('No se pudo iniciar sesión.');
      }
      return _toAccount(user);
    } on FirebaseAuthException catch (error) {
      throw RepositoryException(_message(error), code: error.code);
    }
  }

  @override
  Future<Account> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const RepositoryException('No se pudo crear la cuenta.');
      }
      await user.updateDisplayName(name.trim());
      await user.reload();
      return _toAccount(_auth.currentUser ?? user);
    } on FirebaseAuthException catch (error) {
      throw RepositoryException(_message(error), code: error.code);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw RepositoryException(_message(error), code: error.code);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (error) {
      throw RepositoryException(_message(error), code: error.code);
    }
  }

  Account _toAccount(User user) {
    final email = user.email ?? '';
    final displayName = user.displayName?.trim();
    final name = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : email.split('@').first;
    return Account(uid: user.uid, name: name, email: email);
  }

  String _message(FirebaseAuthException error) => switch (error.code) {
    'invalid-email' => 'El correo no tiene un formato válido.',
    'user-disabled' => 'Esta cuenta está deshabilitada.',
    'user-not-found' => 'No existe una cuenta con ese correo.',
    'wrong-password' ||
    'invalid-credential' => 'Correo o contraseña incorrectos.',
    'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
    'weak-password' => 'La contraseña es demasiado débil (mínimo 6).',
    'too-many-requests' =>
      'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
    'network-request-failed' =>
      'Sin conexión. Revisa tu red e inténtalo de nuevo.',
    'requires-recent-login' =>
      'Vuelve a iniciar sesión para completar esta acción.',
    _ => error.message ?? 'No se pudo completar la operación.',
  };
}
