import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/checkout_controller.dart';
import '../../controllers/coupon_controller.dart';
import '../../core/format/money.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';

/// Campo de cupón reutilizable en el carrito y la confirmación.
class CouponField extends StatefulWidget {
  const CouponField({super.key});

  @override
  State<CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<CouponField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final checkout = context.read<CheckoutController>();
    final ok = await checkout.applyCoupon(_controller.text);
    if (!mounted) return;
    if (ok) {
      _controller.clear();
      FocusScope.of(context).unfocus();
    } else {
      final message =
          context.read<CouponController>().message ??
          'No se pudo aplicar el cupón.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkout = context.watch<CheckoutController>();
    final coupons = context.watch<CouponController>();
    final colors = context.colors;
    final applied = coupons.applied;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CUPÓN',
          style: Brand.ui(
            10,
            weight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: Brand.s4),
        if (applied == null)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Código de cupón',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _apply(),
                ),
              ),
              const SizedBox(width: Brand.s8),
              TextButton(
                onPressed: coupons.isBusy ? null : _apply,
                child: const Text('APLICAR'),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.all(Brand.s12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: Brand.cardRadius,
              border: Border.all(color: colors.action),
            ),
            child: Row(
              children: [
                Icon(Icons.local_offer_rounded, size: 18, color: colors.action),
                const SizedBox(width: Brand.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applied.coupon.code,
                        style: Brand.ui(12, weight: FontWeight.w700),
                      ),
                      Text(
                        'Descuento ${Money.format(checkout.couponDiscountSoles)}',
                        style: context.text.caption.copyWith(
                          color: colors.action,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: checkout.removeCoupon,
                  child: const Text('QUITAR'),
                ),
              ],
            ),
          ),
        if (coupons.message != null && applied == null) ...[
          const SizedBox(height: Brand.s4),
          Text(
            coupons.message!,
            style: context.text.caption.copyWith(color: colors.action),
          ),
        ],
      ],
    );
  }
}
