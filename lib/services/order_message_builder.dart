import '../core/format/money.dart';
import '../models/order.dart';

/// Construye el mensaje de pedido para enviar por WhatsApp.
class OrderMessageBuilder {
  const OrderMessageBuilder._();

  static String build(Order order) {
    final buffer = StringBuffer();
    buffer.writeln("*PEDIDO TOTO'S PIZZA* #${order.code}");
    buffer.writeln('--------------------------------');
    for (final item in order.items) {
      final promo = item.isOnPromo
          ? ' (antes ${Money.format(Money.multiply(item.originalUnitPriceSoles!, item.quantity))})'
          : '';
      buffer.writeln(
        '- ${item.quantity}x ${item.name.toUpperCase()} '
        '(${item.variantLabel}) — ${Money.format(item.lineTotalSoles)}$promo',
      );
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal: ${Money.format(order.subtotalSoles)}');
    if (order.shippingSoles > 0) {
      buffer.writeln('Envío: ${Money.format(order.shippingSoles)}');
    }
    if (order.savingsSoles > 0) {
      buffer.writeln(
        'Ahorro por promociones: ${Money.format(order.savingsSoles)}',
      );
    }
    buffer.writeln('*TOTAL: ${Money.format(order.totalSoles)}*');
    buffer.writeln('Tipo: ${order.type.label}');
    buffer.writeln('Sede: ${order.branchName}');
    buffer.writeln('Nombre: ${order.customerName}');
    if (order.paraOtraPersona && order.receptorNombre != null) {
      final phone = order.receptorTelefono == null
          ? 'sin teléfono'
          : order.receptorTelefono!;
      buffer.writeln('Recibe: ${order.receptorNombre} · $phone');
    }
    if (order.contactoPrincipalNombre != null &&
        order.contactoPrincipalTelefono != null) {
      buffer.writeln(
        'Contacto: ${order.contactoPrincipalNombre} · '
        '${order.contactoPrincipalTelefono}',
      );
    }
    if (order.address != null) buffer.writeln('Dirección: ${order.address}');
    if (order.reference != null) {
      buffer.writeln('Referencia: ${order.reference}');
    }
    if (order.distanciaKm != null) {
      buffer.writeln(
        'Distancia: ${order.distanciaKm!.toStringAsFixed(1)} km',
      );
    }
    if (order.tramo != null) buffer.writeln('Tramo: ${order.tramo}');
    if (order.etaMinutos != null) {
      buffer.writeln('Tiempo estimado: ~${order.etaMinutos} min');
    }
    if (order.envioEstimado) {
      buffer.writeln('Envío estimado, se confirma por WhatsApp.');
    }
    buffer.writeln('Teléfono: ${order.phone}');
    buffer.writeln('Pago: ${order.paymentMethodLabel}');
    if (order.note != null) buffer.writeln('Nota: ${order.note}');
    return buffer.toString().trimRight();
  }
}
