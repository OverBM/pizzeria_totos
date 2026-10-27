import '../models/order.dart';

/// Contrato de pedidos.
abstract interface class OrderRepository {
  /// Historial del usuario, del más reciente al más antiguo.
  Stream<List<Order>> watchOrders(String uid);

  Future<List<Order>> fetchOrders(String uid);

  /// Guarda el pedido y devuelve su id de documento.
  Future<String> createOrder(Order order);

  /// Marca el pedido como enviado por WhatsApp.
  Future<void> markWhatsappSent(String orderId);
}
