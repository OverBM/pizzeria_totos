import 'promotion.dart';

/// Precio resuelto de una variante: lista, final y promoción aplicada.
class PricedVariant {
  const PricedVariant({
    required this.baseSoles,
    required this.finalSoles,
    this.promotion,
  });

  final double baseSoles;
  final double finalSoles;
  final Promotion? promotion;

  bool get hasDiscount => promotion != null && finalSoles < baseSoles;
  double get discountSoles => baseSoles - finalSoles;
  int get discountPercent =>
      promotion?.effectiveDiscountPercent(baseSoles) ?? 0;
}
