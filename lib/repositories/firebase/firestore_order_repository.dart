import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

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
      throw RepositoryException(
        _readMessage(error),
        code: error.toString(),
      );
    }
  }

  @override
  Future<String> createOrder(Order order) async {
    try {
      final reference = _orders.doc();
      await reference.set(
        FirestoreMapper.toFirestore({
          ...order.toMap(),
          'id': reference.id,
        }, dateFields: {'createdAt'}),
      );
      return reference.id;
    } catch (error) {
      throw RepositoryException(
        _writeMessage(error),
        code: error.toString(),
      );
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
