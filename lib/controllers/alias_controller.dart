import 'package:flutter/foundation.dart';

import '../core/auth/alias_policy.dart';
import '../repositories/alias_repository.dart';
import '../repositories/callable_alias_resolver.dart';
import '../repositories/repository_exception.dart';

/// Resolución y edición de alias de acceso.
class AliasController extends ChangeNotifier {
  AliasController({
    required AliasRepository repository,
    CallableAliasResolver? callableResolver,
  }) : _repository = repository,
       _callableResolver = callableResolver;

  final AliasRepository _repository;
  final CallableAliasResolver? _callableResolver;
  bool _busy = false;
  String? _error;

  bool get isBusy => _busy;
  String? get error => _error;

  String? validate(String alias) => AliasPolicy.validate(alias);

  Future<String?> resolveEmail(String identifier) async {
    final clean = identifier.trim();
    if (AliasPolicy.isEmail(clean)) return clean;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final email = _callableResolver != null
          ? await _callableResolver.resolveEmail(clean)
          : await _repository.emailForAlias(clean);
      if (email == null) {
        _error = 'Alias o contraseña incorrectos.';
      }
      return email;
    } catch (error) {
      _error = error is RepositoryException
          ? error.message
          : 'No se pudo resolver el alias.';
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> claim({
    required String uid,
    required String alias,
    required String email,
  }) async {
    final error = AliasPolicy.validate(alias);
    if (error != null) {
      _error = error;
      notifyListeners();
      return null;
    }
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.claimAlias(
        uid: uid,
        alias: alias,
        email: email,
      );
      return alias;
    } catch (error) {
      _error = error is RepositoryException
          ? error.message
          : 'No se pudo guardar el alias.';
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> release({required String uid, required String alias}) async {
    if (alias.trim().isEmpty) return;
    try {
      await _repository.releaseAlias(uid: uid, alias: alias);
    } catch (_) {
      // La liberación es best-effort; el perfil conserva el alias nuevo.
    }
  }

  String suggestFromEmail(String email) =>
      _repository.suggestFromEmail(email);

  Future<String> uniqueAlias(String base) => _repository.uniqueAlias(base);

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}
