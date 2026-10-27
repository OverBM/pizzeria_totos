import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/load_state.dart';
import '../core/time/lima_time.dart';
import '../models/promotion.dart';
import '../repositories/promotion_repository.dart';
import '../repositories/repository_exception.dart';

/// Promociones vigentes publicadas en Firestore.
class PromotionController extends ChangeNotifier {
  PromotionController({required PromotionRepository repository})
    : _repository = repository;

  final PromotionRepository _repository;
  StreamSubscription<List<Promotion>>? _subscription;

  LoadState _state = LoadState.idle;
  List<Promotion> _promotions = const [];
  String? _error;

  LoadState get state => _state;
  List<Promotion> get promotions => _promotions;
  String? get error => _error;
  bool get isEmpty => _promotions.isEmpty;

  /// Solo las vigentes en hora de Lima.
  List<Promotion> get active =>
      _promotions.where((p) => p.isActive(LimaTime.now())).toList();

  List<Promotion> get banners => active.where((p) => p.banner).toList();

  Future<void> load() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _promotions = await _repository.fetchPromotions();
      _state = LoadState.ready;
    } catch (error) {
      _state = LoadState.error;
      _error = error is RepositoryException
          ? error.message
          : 'No se pudieron cargar las promociones.';
    }
    notifyListeners();
  }

  void watch() {
    _subscription ??= _repository.watchPromotions().listen(
      (promotions) {
        _promotions = promotions;
        _state = LoadState.ready;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        if (_state != LoadState.ready) {
          _state = LoadState.error;
          _error = error is RepositoryException
              ? error.message
              : 'No se pudieron actualizar las promociones.';
          notifyListeners();
        }
      },
    );
  }

  /// Promoción aplicable a una variante concreta, o `null`.
  Promotion? forVariant(String productId, String variantLabel) {
    final now = LimaTime.now();
    for (final promotion in _promotions) {
      if (promotion.matches(productId, variantLabel) &&
          promotion.appliesToPrice &&
          promotion.isActive(now)) {
        return promotion;
      }
    }
    return null;
  }

  Promotion? byId(String id) {
    for (final promotion in _promotions) {
      if (promotion.id == id) return promotion;
    }
    return null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
