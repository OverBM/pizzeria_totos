import '../core/format/money.dart';
import 'model_utils.dart';

enum CouponType { percentage, fixedAmount }

enum CouponFailure {
  notFound,
  inactive,
  expired,
  exhausted,
  alreadyUsed,
  minimumNotMet;

  String message({double minimumSoles = 0, double missingSoles = 0}) =>
      switch (this) {
        CouponFailure.notFound => 'Cupón no válido.',
        CouponFailure.inactive => 'Este cupón no está disponible.',
        CouponFailure.expired => 'Este cupón venció.',
        CouponFailure.exhausted => 'Este cupón ya no tiene usos disponibles.',
        CouponFailure.alreadyUsed => 'Ya usaste este cupón.',
        CouponFailure.minimumNotMet =>
          'Te faltan ${Money.format(missingSoles)} para usar este cupón.',
      };
}

/// Cupón de descuento (`cupones/{codigo}`).
class Coupon {
  const Coupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.maxUses,
    required this.uses,
    this.description = '',
    this.minimumSubtotalSoles,
    this.expiresAt,
    this.active = true,
  });

  final String id;
  final String code;
  final CouponType type;
  final double value;
  final String description;
  final double? minimumSubtotalSoles;
  final int maxUses;
  final int uses;
  final DateTime? expiresAt;
  final bool active;

  bool get isExhausted => maxUses > 0 && uses >= maxUses;

  bool isActiveAt(DateTime limaWallClock) {
    if (!active || isExhausted) return false;
    final end = expiresAt;
    return end == null || !limaWallClock.isAfter(end);
  }

  /// Descuento sobre el subtotal después de promociones.
  double discountFor(double baseSoles) {
    final base = Money.round(baseSoles);
    if (base <= 0) return 0;
    final discount = switch (type) {
      CouponType.percentage => Money.discountAmount(base, value),
      CouponType.fixedAmount => Money.round(value),
    };
    return discount.clamp(0, base).toDouble();
  }

  CouponFailure? validate({
    required double baseSoles,
    required DateTime limaWallClock,
  }) {
    if (!active) return CouponFailure.inactive;
    if (expiresAt != null && limaWallClock.isAfter(expiresAt!)) {
      return CouponFailure.expired;
    }
    if (isExhausted) return CouponFailure.exhausted;
    final minimum = minimumSubtotalSoles;
    if (minimum != null && baseSoles < minimum) {
      return CouponFailure.minimumNotMet;
    }
    return null;
  }

  CouponApplication apply(double baseSoles) => CouponApplication(
    coupon: this,
    baseSoles: Money.round(baseSoles),
    discountSoles: discountFor(baseSoles),
  );

  factory Coupon.fromMap(Map<String, dynamic> json) => Coupon(
    id: ModelUtils.asString(json['id']),
    code: ModelUtils.asString(json['codigo'] ?? json['code'] ?? json['id'])
        .trim(),
    type: ModelUtils.asString(json['tipo'] ?? json['type']) == 'monto_fijo'
        ? CouponType.fixedAmount
        : CouponType.percentage,
    value: ModelUtils.asDouble(json['valor'] ?? json['value']),
    description: ModelUtils.asString(
      json['descripcion'] ?? json['description'],
    ),
    minimumSubtotalSoles: ModelUtils.asMoneyOrNull(
      json,
      'compraMinima',
      centsKey: 'minimumSubtotalCents',
    ),
    maxUses: ModelUtils.asInt(json['maxUsos'] ?? json['maxUses']),
    uses: ModelUtils.asInt(json['usos'] ?? json['uses']),
    expiresAt: ModelUtils.asDateTime(
      json['fechaVencimiento'] ?? json['expiresAt'],
    ),
    active: ModelUtils.asBool(
      json['activo'] ?? json['active'],
      fallback:
          ModelUtils.asString(json['estado'] ?? json['status']) != 'inactivo',
    ),
  );
}

/// Resultado de aplicar un cupón.
class CouponApplication {
  const CouponApplication({
    required this.coupon,
    required this.baseSoles,
    required this.discountSoles,
  });

  final Coupon coupon;
  final double baseSoles;
  final double discountSoles;
}
