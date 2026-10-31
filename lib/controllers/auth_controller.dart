import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/load_state.dart';
import '../models/account.dart';
import '../repositories/auth_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/repository_exception.dart';

/// Sesión y perfil del usuario.
///
/// Mantiene la cuenta de Firebase Auth y el documento `users/{uid}` en un solo
/// objeto observable por las vistas. Sin widgets ni Firebase en sus imports.
class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    required ProfileRepository profiles,
  }) : _repository = repository,
       _profiles = profiles;

  final AuthRepository _repository;
  final ProfileRepository _profiles;

  StreamSubscription<Account?>? _authSubscription;
  StreamSubscription<Account?>? _profileSubscription;
  bool _profileRequested = false;

  LoadState _state = LoadState.idle;
  Account? _authAccount;
  Account? _profile;
  String? _error;
  bool _submitting = false;

  LoadState get state => _state;
  Account? get account {
    final auth = _authAccount;
    if (auth == null) return null;
    final profile = _profile;
    if (profile == null) return auth;
    return Account(
      uid: auth.uid,
      name: profile.name.isEmpty ? auth.name : profile.name,
      email: profile.email.isEmpty ? auth.email : profile.email,
      phone: profile.phone,
      addresses: profile.addresses,
      createdAt: profile.createdAt ?? auth.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  Account? get authAccount => _authAccount;
  String? get error => _error;
  bool get isSignedIn => _authAccount != null;
  bool get isSubmitting => _submitting;
  String get uid => _authAccount?.uid ?? '';
  bool get hasPhone => account?.hasPhone ?? false;
  bool get hasAddress => account?.hasAddress ?? false;

  /// Empieza a escuchar la sesión persistente de Firebase Auth.
  void start() {
    _authSubscription ??= _repository.authStateChanges().listen(
      _onAuthChanged,
      onError: (Object error) {
        _state = LoadState.error;
        _error = _message(error, 'No se pudo comprobar la sesión.');
        notifyListeners();
      },
    );
    if (_state == LoadState.idle) {
      _state = LoadState.loading;
      notifyListeners();
    }
  }

  void _onAuthChanged(Account? auth) {
    _authAccount = auth;
    _state = LoadState.ready;

    _profileSubscription?.cancel();
    _profileSubscription = null;
    _profile = null;
    _profileRequested = false;

    if (auth != null) {
      _profileSubscription = _profiles
          .watchProfile(auth.uid)
          .listen(
            (profile) {
              _profile = profile;
              if (profile == null && !_profileRequested) {
                _profileRequested = true;
                _ensureProfile(auth);
              }
              notifyListeners();
            },
            onError: (Object error) {
              _error = _message(error, 'No se pudo cargar el perfil.');
              notifyListeners();
            },
          );
    }
    notifyListeners();
  }

  Future<void> _ensureProfile(Account auth) async {
    try {
      await _profiles.ensureProfile(
        uid: auth.uid,
        name: auth.name,
        email: auth.email,
      );
    } on RepositoryException catch (error) {
      _error = error.message;
    }
  }

  Future<bool> signIn({required String email, required String password}) =>
      _run(() => _repository.signIn(email: email, password: password));

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) => _run(() async {
    final account = await _repository.signUp(
      name: name,
      email: email,
      password: password,
    );
    await _profiles.ensureProfile(
      uid: account.uid,
      name: name,
      email: account.email,
    );
    return account;
  });

  Future<bool> _run(Future<Account> Function() action) async {
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      _error = _message(error, 'No se pudo completar la operación.');
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _profile = null;
    _authAccount = null;
    notifyListeners();
  }

  Future<bool> sendPasswordReset(String email) async {
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.sendPasswordReset(email);
      return true;
    } catch (error) {
      _error = _message(error, 'No se pudo enviar el correo de recuperación.');
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    List<Address>? addresses,
  }) async {
    final uid = this.uid;
    if (uid.isEmpty) return false;
    try {
      await _profiles.updateProfile(
        uid: uid,
        name: name,
        phone: phone,
        addresses: addresses,
      );
      final current = _profile;
      final base = current ?? _authAccount;
      if (base != null) {
        _profile = Account(
          uid: base.uid,
          name: name ?? base.name,
          email: base.email,
          phone: phone ?? base.phone,
          addresses: addresses ?? base.addresses,
          createdAt: base.createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (error) {
      _error = _message(error, 'No se pudo guardar el perfil.');
      notifyListeners();
      return false;
    }
  }

  Future<bool> addAddress(Address address) async {
    final uid = this.uid;
    if (uid.isEmpty) return false;
    try {
      await _profiles.addAddress(uid: uid, address: address);
      return true;
    } catch (error) {
      _error = _message(error, 'No se pudo guardar la dirección.');
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeAddress(String addressId) async {
    final uid = this.uid;
    if (uid.isEmpty) return false;
    try {
      await _profiles.removeAddress(uid: uid, addressId: addressId);
      return true;
    } catch (error) {
      _error = _message(error, 'No se pudo eliminar la dirección.');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Muestra un error local de validación sin llamar a Firebase.
  void showError(String message) {
    _error = message;
    notifyListeners();
  }

  String _message(Object error, String fallback) =>
      error is RepositoryException ? error.message : fallback;

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
