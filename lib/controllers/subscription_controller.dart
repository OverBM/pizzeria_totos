import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/load_state.dart';
import '../core/time/lima_time.dart';
import '../models/delivery_plan.dart';
import '../models/subscription.dart';
import '../repositories/repository_exception.dart';
import '../repositories/subscription_repository.dart';

/// Planes pagos, plan base y suscripción del usuario.
class SubscriptionController extends ChangeNotifier {
  SubscriptionController({required SubscriptionRepository repository})
    : _repository = repository;

  final SubscriptionRepository _repository;
  StreamSubscription<List<DeliveryPlan>>? _plansSubscription;
  StreamSubscription<PlanBase>? _baseSubscription;
  StreamSubscription<Subscription?>? _subscription;
  String _uid = '';

  List<DeliveryPlan> _plans = const [];
  PlanBase _planBase = PlanBase.fallback;
  Subscription? _current;
  LoadState _state = LoadState.idle;
  String? _error;
  bool _busy = false;

  List<DeliveryPlan> get plans => _plans;
  PlanBase get planBase => _planBase;
  Subscription? get subscription => _current;
  Subscription? get paidSubscription =>
      _current != null && _current!.isActiveAt(LimaTime.now())
          ? _current
          : null;
  DeliveryPlan? get paidPlan {
    final paid = paidSubscription;
    if (paid == null) return null;
    for (final plan in _plans) {
      if (plan.id == paid.planId) return plan;
    }
    return null;
  }

  bool get isActive => paidSubscription != null;
  bool get isBusy => _busy;
  String? get error => _error;
  LoadState get state => _state;

  /// Nombre visible del plan actual; El Antojo si no hay plan pago activo.
  String get currentPlanName => paidSubscription?.planName ?? _planBase.name;

  int get daysRemaining => paidSubscription?.daysRemainingAt(LimaTime.now()) ?? 0;

  bool get renewalWarning =>
      paidSubscription?.renewalWarningDue ?? false;

  /// Envío cubierto para delivery con compra mínima.
  bool coversShipping({
    required double subtotalAfterPromotions,
    required double minimumOrderSoles,
    required bool isDelivery,
  }) {
    final paid = paidSubscription;
    if (paid == null || !isDelivery) return false;
    return subtotalAfterPromotions >= minimumOrderSoles;
  }

  void bind(String uid) {
    if (_uid == uid && _subscription != null) return;
    _uid = uid;
    _subscription?.cancel();
    _subscription = null;
    _current = null;
    if (uid.isEmpty) {
      notifyListeners();
      return;
    }
    _subscription = _repository.watchSubscription(uid).listen(
      (subscription) {
        _current = subscription;
        notifyListeners();
      },
      onError: (Object error) {
        _error = error is RepositoryException
            ? error.message
            : 'No se pudo cargar tu plan.';
        notifyListeners();
      },
    );
  }

  void watch() {
    _state = LoadState.loading;
    _plansSubscription ??= _repository.watchPlans().listen(
      (plans) {
        _plans = plans;
        _state = LoadState.ready;
        notifyListeners();
      },
      onError: (Object error) {
        _state = LoadState.error;
        _error = error is RepositoryException
            ? error.message
            : 'No se pudieron cargar los planes.';
        notifyListeners();
      },
    );
    _baseSubscription ??= _repository.watchPlanBase().listen(
      (base) {
        _planBase = base;
        notifyListeners();
      },
    );
  }

  Future<bool> activate(DeliveryPlan plan) async {
    if (_uid.isEmpty) {
      _error = 'Inicia sesión para contratar un plan.';
      notifyListeners();
      return false;
    }
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.activate(uid: _uid, plan: plan);
      return true;
    } catch (error) {
      _error = error is RepositoryException
          ? error.message
          : 'No se pudo activar el plan.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> cancel({String reason = 'Cancelado por el usuario'}) async {
    final current = _current;
    if (_uid.isEmpty || current == null) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final immediate = current.canRefundAt(LimaTime.now());
      await _repository.cancel(
        uid: _uid,
        reason: reason,
        immediate: immediate,
      );
      return true;
    } catch (error) {
      _error = error is RepositoryException
          ? error.message
          : 'No se pudo cancelar el plan.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> registerShipment() async {
    if (_uid.isEmpty) return;
    await _repository.registerShipment(_uid);
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _plansSubscription?.cancel();
    _baseSubscription?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
