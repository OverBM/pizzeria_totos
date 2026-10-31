import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/format/money.dart';
import '../core/load_state.dart';
import '../core/time/lima_time.dart';
import '../models/priced_variant.dart';
import '../models/product.dart';
import '../models/promotion.dart';
import '../models/variant.dart';
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
  ///
  /// Se conserva para consumidores antiguos; las vistas nuevas usan
  /// [priceFor] para obtener también el precio final.
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

  /// Resuelve el precio de una variante aplicando como máximo una promoción.
  ///
  /// Prioridad: variante específica, precio fijo sobre porcentaje, mayor
  /// descuento, `startsAt` más reciente e `id` para estabilidad.
  PricedVariant priceFor(Product product, Variant variant) {
    final base = Money.round(variant.priceSoles);
    final now = LimaTime.now();
    final candidates = <PricedVariant>[];

    for (final promotion in _promotions) {
      if (!promotion.matches(product.id, variant.label) ||
          !promotion.appliesToPrice ||
          !promotion.isActive(now)) {
        continue;
      }
      final finalPrice = promotion.discountedPrice(base);
      if (Money.round(finalPrice) >= base) continue;
      candidates.add(
        PricedVariant(
          baseSoles: base,
          finalSoles: Money.round(finalPrice),
          promotion: promotion,
        ),
      );
    }

    if (candidates.isEmpty) {
      return PricedVariant(baseSoles: base, finalSoles: base);
    }

    candidates.sort((a, b) {
      final aPromo = a.promotion!;
      final bPromo = b.promotion!;

      final aSpecific = aPromo.variantLabel != null ? 1 : 0;
      final bSpecific = bPromo.variantLabel != null ? 1 : 0;
      if (aSpecific != bSpecific) return bSpecific.compareTo(aSpecific);

      final aFixed = aPromo.priceSoles != null ? 1 : 0;
      final bFixed = bPromo.priceSoles != null ? 1 : 0;
      if (aFixed != bFixed) return bFixed.compareTo(aFixed);

      final byDiscount = b.discountSoles.compareTo(a.discountSoles);
      if (byDiscount != 0) return byDiscount;

      final aStart = aPromo.startsAt?.millisecondsSinceEpoch ?? 0;
      final bStart = bPromo.startsAt?.millisecondsSinceEpoch ?? 0;
      if (aStart != bStart) return bStart.compareTo(aStart);

      return aPromo.id.compareTo(bPromo.id);
    });

    return candidates.first;
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
