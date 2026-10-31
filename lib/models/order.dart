import '../core/format/money.dart';
import 'cart_item.dart';
import 'model_utils.dart';

/// Tipo de pedido.
enum OrderType {
  delivery,
  pickup;

  String get label =>
      this == OrderType.delivery ? 'DELIVERY' : 'RECOJO EN TIENDA';

  String get name => this == OrderType.delivery ? 'delivery' : 'pickup';

  static OrderType fromName(String? name) =>
      name == 'pickup' ? OrderType.pickup : OrderType.delivery;
}

/// Estado del pedido.
///
/// La beta no cobra en la app: el pedido queda `pendiente_confirmacion` y se
/// coordina por WhatsApp.
enum OrderStatus {
  pendienteConfirmacion;

  String get name => 'pendiente_confirmacion';

  String get label => 'PENDIENTE DE CONFIRMACIÓN';

  static OrderStatus fromName(String? name) =>
      OrderStatus.pendienteConfirmacion;
}

/// Pedido confirmado por el usuario, guardado en Firestore (`pedidos/{id}`).
class Order {
  const Order({
    required this.id,
    required this.code,
    required this.uid,
    required this.createdAt,
    required this.type,
    required this.branchId,
    required this.branchName,
    required this.items,
    required this.subtotalSoles,
    required this.shippingSoles,
    required this.totalSoles,
    required this.customerName,
    required this.phone,
    required this.paymentMethodId,
    required this.paymentMethodLabel,
    this.status = OrderStatus.pendienteConfirmacion,
    this.address,
    this.reference,
    this.note,
    this.discountSoles = 0,
    this.savingsSoles = 0,
    this.whatsappSent = false,
  });

  /// Id del documento en `pedidos`.
  final String id;

  /// Código legible del pedido (p. ej. `TOT-20261015-1234`).
  final String code;
  final String uid;
  final DateTime createdAt;
  final OrderType type;
  final String branchId;
  final String branchName;
  final List<CartItem> items;
  final double subtotalSoles;
  final double shippingSoles;
  final double discountSoles;
  final double totalSoles;
  final String customerName;
  final String phone;
  final String paymentMethodId;
  final String paymentMethodLabel;
  final OrderStatus status;
  final String? address;
  final String? reference;
  final String? note;

  /// Ahorro por promociones (soles). Alias legacy de [discountSoles].
  final double savingsSoles;
  final bool whatsappSent;

  factory Order.fromMap(Map<String, dynamic> json, {String? id}) => Order(
    id: id ?? ModelUtils.asString(json['id']),
    code: ModelUtils.asString(json['codigo'] ?? json['code']),
    uid: ModelUtils.asString(json['uid']),
    createdAt: ModelUtils.asDateTime(json['createdAt']) ?? DateTime(2000),
    type: OrderType.fromName(
      ModelUtils.asStringOrNull(json['tipo'] ?? json['type']),
    ),
    branchId: ModelUtils.asString(json['sedeId'] ?? json['branchId']),
    branchName: ModelUtils.asString(
      json['sedeNombre'] ?? json['branchName'],
    ),
    items: ModelUtils.asMapList(json['items']).map(CartItem.fromMap).toList(),
    subtotalSoles: ModelUtils.asMoney(
      json,
      'subtotal',
      centsKey: 'subtotalCents',
    ),
    shippingSoles: ModelUtils.asMoney(
      json,
      'envio',
      centsKey: 'shippingCents',
    ),
    discountSoles: json.containsKey('descuento') ||
            json.containsKey('discountCents')
        ? ModelUtils.asMoney(json, 'descuento', centsKey: 'discountCents')
        : ModelUtils.asMoney(json, 'ahorro', centsKey: 'savingsCents'),
    totalSoles: ModelUtils.asMoney(json, 'total', centsKey: 'totalCents'),
    customerName: ModelUtils.asString(
      json['cliente'] ?? json['customerName'],
    ),
    phone: ModelUtils.asString(json['telefono'] ?? json['phone']),
    paymentMethodId: ModelUtils.asString(
      json['medioPago'] ?? json['paymentMethod'],
    ),
    paymentMethodLabel: ModelUtils.asString(
      json['medioPagoEtiqueta'] ?? json['paymentMethodLabel'],
    ),
    status: OrderStatus.fromName(
      ModelUtils.asStringOrNull(json['estado'] ?? json['status']),
    ),
    address: ModelUtils.asStringOrNull(json['direccion'] ?? json['address']),
    reference: ModelUtils.asStringOrNull(
      json['referencia'] ?? json['reference'],
    ),
    note: ModelUtils.asStringOrNull(json['nota'] ?? json['note']),
    savingsSoles: json.containsKey('ahorro') ||
            json.containsKey('savingsCents')
        ? ModelUtils.asMoney(json, 'ahorro', centsKey: 'savingsCents')
        : ModelUtils.asMoney(json, 'descuento', centsKey: 'discountCents'),
    whatsappSent: ModelUtils.asBool(
      json['enviadoWhatsapp'] ?? json['whatsappSent'],
    ),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'codigo': code,
    'uid': uid,
    'createdAt': createdAt.toIso8601String(),
    'tipo': type.name,
    'sedeId': branchId,
    'sedeNombre': branchName,
    'items': items.map((e) => e.toMap()).toList(),
    'subtotal': Money.round(subtotalSoles),
    'envio': Money.round(shippingSoles),
    'descuento': Money.round(discountSoles),
    'total': Money.round(totalSoles),    'cliente': customerName,
    'telefono': phone,
    'medioPago': paymentMethodId,
    'medioPagoEtiqueta': paymentMethodLabel,
    'estado': status.name,
    if (address != null) 'direccion': address,
    if (reference != null) 'referencia': reference,
    if (note != null) 'nota': note,
    'ahorro': Money.round(discountSoles),
    'enviadoWhatsapp': whatsappSent,
  };
}
