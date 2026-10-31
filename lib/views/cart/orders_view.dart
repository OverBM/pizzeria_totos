import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/order_controller.dart';
import '../../core/format/money.dart';
import '../../core/load_state.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/theme/brand.dart';
import '../../widgets/widgets.dart';
import '../../core/theme/theme_context.dart';
import '../../models/order.dart';
import 'order_detail_view.dart';

/// Historial de pedidos del usuario autenticado.
class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  static final DateFormat _date = DateFormat('dd/MM/yyyy · HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = context.read<OrderController>();
      if (controller.state == LoadState.idle) {
        controller.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrderController>();
    return Scaffold(
      appBar: TotoTopBar(
        showWordmark: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        actions: [
          IconButton(
            onPressed: controller.load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar',
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(44),
          child: Padding(
            padding: EdgeInsets.fromLTRB(Brand.s16, 0, Brand.s16, Brand.s12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MIS PEDIDOS',
                style: TextStyle(fontFamily: Brand.fontDisplay, fontSize: 22),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _body(context, controller)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, OrderController controller) {
    if (controller.state == LoadState.loading && controller.isEmpty) {
      return const SingleChildScrollView(
        child: SkeletonList(count: 3, height: 120),
      );
    }
    if (controller.isEmpty) {
      return EmptyState(
        title: 'Aún no tienes pedidos',
        message:
            controller.error ??
            'Cuando confirmes tu primer pedido aparecerá aquí con su código '
                'y estado.',
        icon: Icons.receipt_long_outlined,
        actionLabel: 'RECARGAR',
        onAction: controller.load,
      );
    }
    return RefreshIndicator(
      onRefresh: controller.load,
      color: Brand.ovenOrange,
      child: ListView.separated(
        padding: const EdgeInsets.all(Brand.s16),
        itemCount: controller.orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: Brand.s12),
        itemBuilder: (context, index) {
          final order = controller.orders[index];
          return _OrderCard(
            order: order,
            date: _date,
            onTap: () => Navigator.of(context).push(
              MotionRoute(builder: (_) => OrderDetailView(order: order)),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.date,
    required this.onTap,
  });

  final Order order;
  final DateFormat date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final preview = order.items
        .take(2)
        .map((item) => '${item.quantity}× ${item.name}')
        .join(' · ');
    return MotionPressable(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(Brand.s12),
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
                  style: Brand.ui(
                    14,
                    weight: FontWeight.w700,
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
          const SizedBox(height: Brand.s4),
          Text(
            date.format(order.createdAt),
            style: context.text.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: Brand.s8),
          Text(
            '${order.type.label} · ${order.branchName}',
            style: context.text.bodySm,
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: Brand.s2),
            Text(
              order.items.length > 2 ? '$preview…' : preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          if (order.address != null) ...[
            const SizedBox(height: Brand.s2),
            Text(
              order.address!,
              style: context.text.caption.copyWith(color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: Brand.s8),
          _amountRow(context, 'Subtotal', Money.format(order.subtotalSoles)),
          if (order.discountSoles > 0)
            _amountRow(
              context,
              'Descuento',
              '- ${Money.format(order.discountSoles)}',
              accent: true,
            ),
          _amountRow(
            context,
            'Envío',
            order.shippingSoles == 0
                ? 'Sin costo'
                : Money.format(order.shippingSoles),
          ),
          const Divider(height: Brand.s16),
          Row(
            children: [
              Text(
                'TOTAL',
                style: Brand.ui(
                  11,
                  weight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                Money.format(order.totalSoles),
                style: Brand.ui(
                  16,
                  weight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }

  Widget _amountRow(
    BuildContext context,
    String label,
    String value, {
    bool accent = false,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: Brand.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.caption.copyWith(
                color: accent ? colors.action : colors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: Brand.ui(
              12,
              weight: FontWeight.w600,
              color: accent ? colors.action : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
