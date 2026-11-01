import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/checkout_controller.dart';
import '../../core/format/money.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../models/order.dart';
import '../../services/contact_launcher.dart';
import '../../services/order_message_builder.dart';
import '../../services/settings_service.dart';
import '../../widgets/widgets.dart';

/// Muestra la confirmación de un pedido recién registrado.
Future<void> showOrderConfirmation(
  BuildContext context,
  Order order,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => OrderConfirmationSheet(order: order),
  );
}

class OrderConfirmationSheet extends StatelessWidget {
  const OrderConfirmationSheet({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final settings = Provider.of<SettingsService>(context, listen: false);
    final checkout = context.read<CheckoutController>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Brand.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Brand.s10,
                vertical: Brand.s4,
              ),
              decoration: BoxDecoration(
                color: colors.action,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'PEDIDO REGISTRADO',
                style: Brand.ui(
                  9,
                  weight: FontWeight.w700,
                  color: colors.onAction,
                ),
              ),
            ),
            const SizedBox(height: Brand.s12),
            Text(
              '#${order.code}',
              style: Brand.display(26, h: 1, color: colors.textPrimary),
            ),
            const SizedBox(height: Brand.s8),
            Text(
              'Queda pendiente de confirmación. No se cobró nada en la app: '
              'continuamos por WhatsApp para coordinar el pago y la entrega.',
              style: context.text.bodySm.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: Brand.s16),
            _row(context, 'Subtotal', Money.format(order.subtotalSoles)),
            if (order.discountSoles > 0)
              _row(
                context,
                'Descuento',
                '- ${Money.format(order.discountSoles)}',
                accent: true,
              ),
            _row(
              context,
              'Envío',
              order.shippingSoles == 0
                  ? 'Sin costo'
                  : Money.format(order.shippingSoles),
            ),
            if (order.distanciaKm != null)
              _row(
                context,
                'Distancia',
                '${order.distanciaKm!.toStringAsFixed(1)} km',
              ),
            if (order.tramo != null) _row(context, 'Tramo', order.tramo!),
            if (order.etaMinutos != null)
              _row(context, 'Llega en', '~${order.etaMinutos} min'),
            if (order.paraOtraPersona && order.receptorNombre != null)
              _row(context, 'Recibe', order.receptorNombre!),
            const Divider(height: Brand.s24),
            Row(
              children: [
                Text(
                  Money.format(order.totalSoles),
                  style: Brand.ui(
                    22,
                    weight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                StatusPill(
                  label: order.status.label,
                  filled: false,
                  color: colors.action,
                ),
              ],
            ),
            const SizedBox(height: Brand.s16),
            PillButton(
              label: 'CONTINUAR POR WHATSAPP',
              expanded: true,
              showArrow: true,
              onPressed: () async {
                final sent = await ContactLauncher.whatsapp(
                  phone: settings.whatsapp,
                  message: OrderMessageBuilder.build(order),
                );
                if (sent) await checkout.markWhatsappSent(order);
              },
            ),
            const SizedBox(height: Brand.s8),
            PillButton(
              label: 'SEGUIR EXPLORANDO',
              filled: false,
              expanded: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool accent = false,
  }) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.text.bodySm.copyWith(
              color: accent ? colors.action : colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: Brand.ui(
            12,
            weight: FontWeight.w700,
            color: accent ? colors.action : colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
