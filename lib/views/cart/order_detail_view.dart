import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/format/money.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../models/order.dart';
import '../../models/media_ref.dart';
import '../../services/contact_launcher.dart';
import '../../services/order_message_builder.dart';
import '../../services/settings_service.dart';
import '../../widgets/widgets.dart';

/// Detalle completo de un pedido del historial.
class OrderDetailView extends StatelessWidget {
  const OrderDetailView({super.key, required this.order});

  final Order order;

  static final DateFormat _date = DateFormat('dd/MM/yyyy · HH:mm');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final settings = Provider.of<SettingsService>(context, listen: false);
    return Scaffold(
      appBar: TotoTopBar(
        showWordmark: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Brand.s16, 0, Brand.s16, Brand.s12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'DETALLE DEL PEDIDO',
                style: Brand.display(20, h: 1),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Brand.s16,
          Brand.s16,
          Brand.s16,
          Brand.s24,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(Brand.s16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: Brand.cardRadius,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${order.code}',
                        style: Brand.display(
                          22,
                          h: 1,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    StatusPill(
                      label: order.status.label,
                      filled: false,
                      color: colors.action,
                    ),
                  ],
                ),
                const SizedBox(height: Brand.s8),
                Text(
                  _date.format(order.createdAt),
                  style: context.text.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: Brand.s8),
                Text(
                  '${order.type.label} · ${order.branchName}',
                  style: context.text.bodySm,
                ),
                if (order.address != null) ...[
                  const SizedBox(height: Brand.s4),
                  Text(order.address!, style: context.text.bodySm),
                ],
                if (order.reference != null) ...[
                  const SizedBox(height: Brand.s2),
                  Text(
                    'Ref. ${order.reference}',
                    style: context.text.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Brand.s24),
          Text(
            'PRODUCTOS',
            style: Brand.ui(
              10,
              weight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: Brand.s8),
          for (final item in order.items) ...[
            Container(
              padding: const EdgeInsets.all(Brand.s12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: Brand.cardRadius,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: DriveImage(
                      media: item.image == null
                          ? null
                          : MediaRef.fromValue(item.image!),
                      placeholderLabel: item.name,
                      borderRadius: Brand.cardRadius,
                    ),
                  ),
                  const SizedBox(width: Brand.s8),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.action.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${item.quantity}×',
                      style: Brand.ui(11, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: Brand.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name.toUpperCase(),
                          style: Brand.ui(12, weight: FontWeight.w700),
                        ),
                        Text(
                          item.variantLabel,
                          style: context.text.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: Brand.s2),
                        Text(
                          '${Money.format(item.unitPriceSoles)} c/u',
                          style: context.text.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (item.isOnPromo)
                        Text(
                          Money.format(
                            Money.multiply(
                              item.originalUnitPriceSoles!,
                              item.quantity,
                            ),
                          ),
                          style: Brand.ui(
                            10,
                            color: colors.textSecondary,
                          ).copyWith(decoration: TextDecoration.lineThrough),
                        ),
                      Text(
                        Money.format(item.lineTotalSoles),
                        style: Brand.ui(13, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Brand.s8),
          ],
          const SizedBox(height: Brand.s8),
          Container(
            padding: const EdgeInsets.all(Brand.s12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: Brand.cardRadius,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
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
                const Divider(height: Brand.s24),
                _row(
                  context,
                  'TOTAL',
                  Money.format(order.totalSoles),
                  strong: true,
                ),
              ],
            ),
          ),
          if (order.note != null) ...[
            const SizedBox(height: Brand.s16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Brand.s12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: Brand.cardRadius,
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOTA',
                    style: Brand.ui(
                      9,
                      weight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Brand.s4),
                  Text(order.note!, style: context.text.bodySm),
                ],
              ),
            ),
          ],
          const SizedBox(height: Brand.s24),
          PillButton(
            label: 'ENVIAR RESUMEN POR WHATSAPP',
            expanded: true,
            showArrow: true,
            onPressed: () => ContactLauncher.whatsapp(
              phone: settings.whatsapp,
              message: OrderMessageBuilder.build(order),
            ),
          ),
          const SizedBox(height: Brand.s8),
          Text(
            'Pago: ${order.paymentMethodLabel} · ${order.customerName} · '
            '${order.phone}',
            textAlign: TextAlign.center,
            style: context.text.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool accent = false,
    bool strong = false,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Brand.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: (strong ? Brand.ui(12, weight: FontWeight.w700) : context.text.bodySm)
                  .copyWith(
                    color: accent ? colors.action : colors.textSecondary,
                  ),
            ),
          ),
          Text(
            value,
            style: Brand.ui(
              strong ? 16 : 12,
              weight: FontWeight.w700,
              color: accent ? colors.action : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
