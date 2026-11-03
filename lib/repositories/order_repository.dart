import '../models/order.dart';

/// Contrato de pedidos.
abstract interface class OrderRepository {
  /// Historial del usuario, del más reciente al más antiguo.
  Stream<List<Order>> watchOrders(String uid);

  Future<List<Order>> fetchOrders(String uid);

  /// Guarda el pedido y devuelve su id de documento.
  ///
  /// Si se indica un cupón o una suscripción, el pedido, el consumo del cupón
  /// y el uso del envío se escriben en la misma transacción.
  Future<String> createOrder(
    Order order, {
    String? couponCode,
    String? couponUid,
    bool registerShipment = false,
  });

  /// Marca el pedido como enviado por WhatsApp.
  Future<void> markWhatsappSent(String orderId);
}
