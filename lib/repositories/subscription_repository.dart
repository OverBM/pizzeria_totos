import '../models/delivery_plan.dart';
import '../models/subscription.dart';

/// Contrato de planes y suscripciones.
abstract interface class SubscriptionRepository {
  Stream<List<DeliveryPlan>> watchPlans();

  Stream<PlanBase> watchPlanBase();

  Stream<Subscription?> watchSubscription(String uid);

  Future<void> activate({required String uid, required DeliveryPlan plan});

  Future<void> cancel({
    required String uid,
    required String reason,
    required bool immediate,
  });

  Future<void> registerShipment(String uid);
}
