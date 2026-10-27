import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/load_state.dart';
import '../models/branch.dart';
import '../repositories/branch_repository.dart';
import '../repositories/repository_exception.dart';

/// Sedes activas de la provincia de Huancayo.
class BranchController extends ChangeNotifier {
  BranchController({required BranchRepository repository})
    : _repository = repository;

  final BranchRepository _repository;
  StreamSubscription<List<Branch>>? _subscription;

  LoadState _state = LoadState.idle;
  List<Branch> _branches = const [];
  String? _error;

  LoadState get state => _state;
  List<Branch> get branches => _branches;
  String? get error => _error;
  bool get isEmpty => _branches.isEmpty;

  Branch? get defaultBranch => _branches.isEmpty ? null : _branches.first;

  Future<void> load() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _branches = await _repository.fetchBranches();
      _state = LoadState.ready;
    } catch (error) {
      _state = LoadState.error;
      _error = error is RepositoryException
          ? error.message
          : 'No se pudieron cargar las sedes.';
    }
    notifyListeners();
  }

  void watch() {
    _subscription ??= _repository.watchBranches().listen(
      (branches) {
        _branches = branches;
        _state = LoadState.ready;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        if (_state != LoadState.ready) {
          _state = LoadState.error;
          _error = error is RepositoryException
              ? error.message
              : 'No se pudieron actualizar las sedes.';
          notifyListeners();
        }
      },
    );
  }

  Branch? byId(String id) {
    for (final branch in _branches) {
      if (branch.id == id) return branch;
    }
    return null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
