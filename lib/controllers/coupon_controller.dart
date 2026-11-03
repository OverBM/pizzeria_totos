import 'package:flutter/foundation.dart';

import '../core/time/lima_time.dart';
import '../models/coupon.dart';
import '../repositories/coupon_repository.dart';
import '../repositories/repository_exception.dart';

/// Cupón aplicado al carrito y validación por código.
class CouponController extends ChangeNotifier {
  CouponController({required CouponRepository repository})
    : _repository = repository;

  final CouponRepository _repository;
  CouponApplication? _applied;
  CouponFailure? _failure;
  String? _error;
  bool _busy = false;

  CouponApplication? get applied => _applied;
  CouponFailure? get failure => _failure;
  String? get error => _error;
  bool get isBusy => _busy;
  bool get hasCoupon => _applied != null;

  double discountFor(double baseSoles) {
    final applied = _applied;
    if (applied == null) return 0;
    final failure = applied.coupon.validate(
      baseSoles: baseSoles,
      limaWallClock: LimaTime.now(),
    );
    if (failure != null) return 0;
    return applied.coupon.discountFor(baseSoles);
  }

  CouponFailure? validate(double baseSoles) {
    final applied = _applied;
    if (applied == null) return null;
    return applied.coupon.validate(
      baseSoles: baseSoles,
      limaWallClock: LimaTime.now(),
    );
  }

  Future<bool> apply({
    required String code,
    required double baseSoles,
    String? uid,
  }) async {
    _busy = true;
    _error = null;
    _failure = null;
    notifyListeners();
    try {
      final normalized = code.trim();
      if (normalized.isEmpty) {
        _failure = CouponFailure.notFound;
        return false;
      }
      final coupon = await _repository.fetchByCode(normalized);
      if (coupon == null) {
        _failure = CouponFailure.notFound;
        _error = _failure!.message();
        return false;
      }
      final failure = coupon.validate(
        baseSoles: baseSoles,
        limaWallClock: LimaTime.now(),
      );
      if (failure != null) {
        _failure = failure;
        _error = failure.message(
          minimumSoles: coupon.minimumSubtotalSoles ?? 0,
          missingSoles: ((coupon.minimumSubtotalSoles ?? 0) - baseSoles)
              .clamp(0, double.infinity)
              .toDouble(),
        );
        return false;
      }
      if (uid != null &&
          await _repository.wasRedeemed(code: normalized, uid: uid)) {
        _failure = CouponFailure.alreadyUsed;
        _error = _failure!.message();
        return false;
      }
      final discount = coupon.discountFor(baseSoles);
      if (discount <= 0) {
        _failure = CouponFailure.minimumNotMet;
        _error = _failure!.message(
          minimumSoles: coupon.minimumSubtotalSoles ?? 0,
          missingSoles: ((coupon.minimumSubtotalSoles ?? 0) - baseSoles)
              .clamp(0, double.infinity)
              .toDouble(),
        );
        return false;
      }
      _applied = CouponApplication(
        coupon: coupon,
        baseSoles: baseSoles,
        discountSoles: discount,
      );
      return true;
    } catch (error) {
      _error = error is RepositoryException
          ? error.message
          : 'No se pudo aplicar el cupón.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> redeem({
    required String code,
    required String uid,
    required String orderId,
  }) async {
    await _repository.redeem(code: code, uid: uid, orderId: orderId);
  }

  void clear() {
    _applied = null;
    _failure = null;
    _error = null;
    notifyListeners();
  }

  String? get message {
    if (_error != null) return _error;
    final failure = _failure;
    if (failure == null) return null;
    final base = _applied?.baseSoles ?? 0;
    return failure.message(
      minimumSoles: _applied?.coupon.minimumSubtotalSoles ?? 0,
      missingSoles: ((_applied?.coupon.minimumSubtotalSoles ?? 0) - base)
          .clamp(0, double.infinity)
          .toDouble(),
    );
  }
}
