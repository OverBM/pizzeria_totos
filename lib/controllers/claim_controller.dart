import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/load_state.dart';
import '../core/time/lima_time.dart';
import '../models/claim.dart';
import '../repositories/claim_repository.dart';
import '../repositories/repository_exception.dart';
import '../services/settings_service.dart';

/// Borrador de reclamo creado desde el formulario.
class ClaimDraft {
  const ClaimDraft({
    required this.uid,
    required this.categoryId,
    required this.categoryLabel,
    required this.message,
    this.orderId,
    this.orderCode,
    this.branchId,
    this.branchName,
  });

  final String uid;
  final String categoryId;
  final String categoryLabel;
  final String message;
  final String? orderId;
  final String? orderCode;
  final String? branchId;
  final String? branchName;
}

/// Reclamos propios y envío del formulario.
class ClaimController extends ChangeNotifier {
  ClaimController({
    required ClaimRepository repository,
    required SettingsService settings,
  }) : _repository = repository,
       _settings = settings;

  final ClaimRepository _repository;
  final SettingsService _settings;
  StreamSubscription<List<Claim>>? _subscription;

  LoadState _state = LoadState.idle;
  List<Claim> _claims = const [];
  String? _error;
  bool _submitting = false;
  String _uid = '';

  LoadState get state => _state;
  List<Claim> get claims => _claims;
  String? get error => _error;
  bool get isSubmitting => _submitting;
  bool get isEmpty => _claims.isEmpty;
  List<ClaimReason> get reasons => _settings.settings.activeClaimReasons;

  void bind(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _subscription?.cancel();
    _subscription = null;
    _claims = const [];
    _error = null;
    _state = LoadState.idle;
    notifyListeners();
    if (uid.isNotEmpty) watch();
  }

  void watch() {
    if (_uid.isEmpty) return;
    _state = LoadState.loading;
    notifyListeners();
    _subscription ??= _repository
        .watchClaims(_uid)
        .listen(
          (claims) {
            _claims = claims;
            _state = LoadState.ready;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            _state = LoadState.error;
            _error = error is RepositoryException
                ? error.message
                : 'No se pudieron cargar tus reclamos.';
            notifyListeners();
          },
        );
  }

  Future<Claim?> submit(ClaimDraft draft) async {
    if (draft.message.trim().isEmpty) {
      _error = 'Cuéntanos qué pasó para poder ayudarte.';
      notifyListeners();
      return null;
    }
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final claim = Claim(
        id: '',
        code: _codeFor(now),
        uid: draft.uid,
        orderId: draft.orderId,
        branchId: draft.branchId,
        branchName: draft.branchName,
        categoryId: draft.categoryId,
        categoryLabel: draft.categoryLabel,
        message: draft.message.trim(),
        createdAt: now,
        updatedAt: now,
      );
      final id = await _repository.createClaim(claim);
      return Claim.fromMap({...claim.toMap(), 'id': id}, id: id);
    } catch (error) {
      _error = error is RepositoryException
          ? error.message
          : 'No se pudo enviar el reclamo.';
      return null;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  String _codeFor(DateTime instant) {
    final lima = LimaTime.at(instant);
    final date = '${lima.year}${_two(lima.month)}${_two(lima.day)}';
    final suffix = (instant.millisecondsSinceEpoch % 10000).toString().padLeft(
      4,
      '0',
    );
    return 'REC-$date-$suffix';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
