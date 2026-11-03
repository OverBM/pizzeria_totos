import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../core/time/lima_time.dart';
import '../../models/coupon.dart';
import '../../models/order.dart';
import '../../services/firestore_mapper.dart';
import '../order_repository.dart';
import '../repository_exception.dart';

/// Pedidos del usuario en `pedidos`.
class FirestoreOrderRepository implements OrderRepository {
  FirestoreOrderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('pedidos');

  @override
  Stream<List<Order>> watchOrders(String uid) => _orders
      .where('uid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(_build);

  @override
  Future<List<Order>> fetchOrders(String uid) async {
    try {
      final snapshot = await _orders
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      return _build(snapshot);
    } catch (error) {
      throw RepositoryException(_readMessage(error), code: error.toString());
    }
  }

  @override
  Future<String> createOrder(
    Order order, {
    String? couponCode,
    String? couponUid,
    bool registerShipment = false,
  }) async {
    try {
      final reference = _orders.doc();
      await _firestore.runTransaction((transaction) async {
        if (couponCode != null && couponUid != null) {
          final couponRef = _firestore
              .collection('cupones')
              .doc(couponCode.trim());
          final redemptionRef = _firestore
              .collection('redenciones')
              .doc('${couponCode.trim()}_$couponUid');
          final couponSnapshot = await transaction.get(couponRef);
          final redemptionSnapshot = await transaction.get(redemptionRef);
          if (!couponSnapshot.exists) {
            throw const RepositoryException('Cupón no válido.');
          }
          if (redemptionSnapshot.exists) {
            throw const RepositoryException('Ya usaste este cupón.');
          }
          final coupon = Coupon.fromMap(
            FirestoreMapper.fromDocument(couponSnapshot),
          );
          final failure = coupon.validate(
            baseSoles:
                order.subtotalSoles - order.effectivePromotionDiscountSoles,
            limaWallClock: LimaTime.now(),
          );
          if (failure != null) {
            throw RepositoryException(
              failure.message(
                minimumSoles: coupon.minimumSubtotalSoles ?? 0,
                missingSoles:
                    ((coupon.minimumSubtotalSoles ?? 0) -
                            (order.subtotalSoles -
                                order.effectivePromotionDiscountSoles))
                        .clamp(0, double.infinity)
                        .toDouble(),
              ),
            );
          }
          transaction.update(couponRef, {'usos': coupon.uses + 1});
          transaction.set(redemptionRef, {
            'uid': couponUid,
            'codigo': coupon.code,
            'pedidoId': reference.id,
            'creadoEn': FieldValue.serverTimestamp(),
          });
        }
        if (registerShipment && couponUid != null) {
          final subscriptionRef = _firestore
              .collection('suscripciones')
              .doc(couponUid);
          final snapshot = await transaction.get(subscriptionRef);
          if (snapshot.exists) {
            transaction.update(subscriptionRef, {
              'enviosUsados': FieldValue.increment(1),
              'actualizadoEn': FieldValue.serverTimestamp(),
            });
          }
        }
        transaction.set(
          reference,
          FirestoreMapper.toFirestore(
            {...order.toMap(), 'id': reference.id},
            dateFields: {'createdAt'},
          ),
        );
      });
      return reference.id;
    } catch (error) {
      if (error is RepositoryException) rethrow;
      throw RepositoryException(_writeMessage(error), code: error.toString());
    }
  }

  List<Order> _build(QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot
      .docs
      .map((doc) => Order.fromMap(doc.data(), id: doc.id))
      .toList();

  String _readMessage(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'failed-precondition') {
        return 'Falta un índice de Firestore para ordenar tus pedidos. '
            'Pide al administrador que publique los índices.';
      }
      if (error.code == 'permission-denied') {
        return 'No tienes permiso para leer tus pedidos. Revisa las reglas '
            'de Firestore.';
      }
    }
    return 'No se pudo cargar tu historial de pedidos.';
  }

  String _writeMessage(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Firestore rechazó el pedido. Revisa las reglas publicadas.';
      }
      if (error.code == 'unavailable') {
        return 'Sin conexión con Firestore. Tu carrito se conserva; '
            'inténtalo de nuevo.';
      }
    }
    return 'No se pudo registrar el pedido. Inténtalo de nuevo.';
  }

  @override
  Future<void> markWhatsappSent(String orderId) async {
    try {
      await _orders.doc(orderId).set({
        'enviadoWhatsapp': true,
      }, SetOptions(merge: true));
    } catch (_) {
      // El pedido ya está registrado; este campo es informativo.
    }
  }
}
