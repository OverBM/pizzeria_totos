import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/delivery_plan.dart';
import '../../models/subscription.dart';
import '../repository_exception.dart';
import '../subscription_repository.dart';

/// Planes, estado base y suscripciones del usuario.
class FirestoreSubscriptionRepository implements SubscriptionRepository {
  FirestoreSubscriptionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<DeliveryPlan>> watchPlans() => _firestore
      .collection('planesDelivery')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => DeliveryPlan.fromMap({
                ...doc.data(),
                'id': doc.id,
              }),
            )
            .where((plan) => plan.id.isNotEmpty && plan.active)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );

  @override
  Stream<PlanBase> watchPlanBase() => _firestore
      .collection('configuracion')
      .doc('planBase')
      .snapshots()
      .map(
        (snapshot) => PlanBase.fromMap(
          snapshot.data() ?? const {},
        ),
      );

  @override
  Stream<Subscription?> watchSubscription(String uid) => _firestore
      .collection('suscripciones')
      .doc(uid)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? Subscription.fromMap({
                ...snapshot.data()!,
                'uid': uid,
              })
            : null,
      );

  @override
  Future<void> activate({
    required String uid,
    required DeliveryPlan plan,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final reference = _firestore.collection('suscripciones').doc(uid);
        final snapshot = await transaction.get(reference);
        final now = DateTime.now();
        final current = snapshot.exists
            ? Subscription.fromMap({
                ...snapshot.data()!,
                'uid': uid,
              })
            : null;
        final base = current != null && current.isActiveAt(now)
            ? current.endAt
            : now;
        final end = base.add(Duration(days: plan.days));
        transaction.set(reference, {
          'uid': uid,
          'planId': plan.id,
          'planNombre': plan.name,
          'precio': plan.priceSoles,
          'inicio': current == null
              ? FieldValue.serverTimestamp()
              : Timestamp.fromDate(current.startAt),
          'vence': Timestamp.fromDate(end),
          'periodoInicio': current == null
              ? FieldValue.serverTimestamp()
              : Timestamp.fromDate(current.periodStart),
          'estado': 'activa',
          'enviosUsados': current?.shipmentsUsed ?? 0,
          'renuevaAutomatico': false,
          'actualizadoEn': FieldValue.serverTimestamp(),
        });
      });
    } catch (error) {
      throw RepositoryException(
        'No se pudo activar el plan.',
        code: error.toString(),
      );
    }
  }

  @override
  Future<void> cancel({
    required String uid,
    required String reason,
    required bool immediate,
  }) async {
    try {
      final reference = _firestore.collection('suscripciones').doc(uid);
      await reference.update({
        'estado': 'cancelada',
        'canceladaEn': FieldValue.serverTimestamp(),
        'motivoCancelacion': reason,
        if (immediate) 'vence': Timestamp.fromDate(DateTime.now()),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw RepositoryException(
        'No se pudo cancelar el plan.',
        code: error.toString(),
      );
    }
  }

  @override
  Future<void> registerShipment(String uid) async {
    await _firestore.collection('suscripciones').doc(uid).update({
      'enviosUsados': FieldValue.increment(1),
      'actualizadoEn': FieldValue.serverTimestamp(),
    });
  }
}
