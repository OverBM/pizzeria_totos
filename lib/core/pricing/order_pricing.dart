import '../format/money.dart';

/// Resultado del cálculo económico de un pedido.
///
/// Es una función pura: no conoce widgets, Firestore ni controladores.
class OrderPricing {
  const OrderPricing({
    required this.subtotalSoles,
    required this.promotionDiscountSoles,
    required this.couponDiscountSoles,
    required this.shippingOriginalSoles,
    required this.shippingChargedSoles,
    required this.totalSoles,
  });

  final double subtotalSoles;
  final double promotionDiscountSoles;
  final double couponDiscountSoles;
  final double shippingOriginalSoles;
  final double shippingChargedSoles;
  final double totalSoles;

  double get productDiscountSoles =>
      Money.sum([promotionDiscountSoles, couponDiscountSoles]);

  double get savingsSoles => productDiscountSoles;

  static OrderPricing calculate({
    required double subtotalSoles,
    required double promotionDiscountSoles,
    required double couponDiscountSoles,
    required double shippingOriginalSoles,
    required bool shippingCovered,
  }) {
    final subtotal = Money.round(subtotalSoles);
    final promotion = Money.round(promotionDiscountSoles)
        .clamp(0, subtotal)
        .toDouble();
    final baseAfterPromotion = Money.round(subtotal - promotion);
    final coupon = Money.round(couponDiscountSoles)
        .clamp(0, baseAfterPromotion)
        .toDouble();
    final shippingOriginal = Money.round(shippingOriginalSoles);
    final shipping = shippingCovered ? 0.0 : shippingOriginal;
    final total = Money.sum([
      subtotal,
      -promotion.toDouble(),
      -coupon.toDouble(),
      shipping,
    ]).clamp(0, double.infinity).toDouble();
    return OrderPricing(
      subtotalSoles: subtotal,
      promotionDiscountSoles: promotion.toDouble(),
      couponDiscountSoles: coupon.toDouble(),
      shippingOriginalSoles: shippingOriginal,
      shippingChargedSoles: shipping,
      totalSoles: total,
    );
  }
}
