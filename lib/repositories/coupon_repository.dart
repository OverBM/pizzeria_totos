import '../models/coupon.dart';

/// Contrato de cupones por código.
abstract interface class CouponRepository {
  Future<Coupon?> fetchByCode(String code);

  /// ¿El usuario ya redimió este cupón?
  Future<bool> wasRedeemed({required String code, required String uid});

  /// Consume el cupón dentro de una transacción que también crea el pedido.
  Future<void> redeem({
    required String code,
    required String uid,
    required String orderId,
  });
}
