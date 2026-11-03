import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/subscription_controller.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../models/delivery_plan.dart';
import '../../models/subscription.dart';
import '../../widgets/widgets.dart';
import '../auth/login_view.dart';
import 'plan_card.dart';

/// Pantalla de planes: plan actual y upgrades.
class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key, this.embedded = false});

  /// Cuando es una pestaña del shell no monta otro `Scaffold` ni barra.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final subscriptions = context.watch<SubscriptionController>();
    final colors = context.colors;

    final body = Column(
      children: [
        if (!embedded) const OfflineBanner(),
        Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Brand.s16,
                Brand.s16,
                Brand.s16,
                Brand.s32,
              ),
              children: [
                Text(
                  '‹ TOTO\'S PLANES ›',
                  style: Brand.ui(
                    11,
                    weight: FontWeight.w700,
                    color: colors.action,
                  ),
                ),
                const SizedBox(height: Brand.s4),
                Text(
                  'TU PLAN',
                  style: Brand.display(34, h: 1, color: colors.textPrimary),
                ),
                const SizedBox(height: Brand.s8),
                Text(
                  'Elige cómo quieres pedir. El envío gratis aplica solo a '
                  'delivery dentro de cobertura y con compra mínima.',
                  style: context.text.bodySm.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: Brand.s20),
                _CurrentPlanCard(
                  base: subscriptions.planBase,
                  subscription: subscriptions.paidSubscription,
                  paidPlan: subscriptions.paidPlan,
                ),
                if (subscriptions.renewalWarning) ...[
                  const SizedBox(height: Brand.s8),
                  Text(
                    'Tu plan se renueva pronto. Cancela antes de la '
                    'renovación si no quieres el siguiente cobro.',
                    style: context.text.caption.copyWith(
                      color: colors.action,
                    ),
                  ),
                ],
                const SizedBox(height: Brand.s24),
                if (subscriptions.plans.isEmpty)
                  const EmptyState(
                    title: 'No hay planes disponibles',
                    message:
                        'El negocio todavía no publicó los planes pagos. '
                        'Puedes seguir pidiendo con El Antojo.',
                    icon: Icons.local_offer_outlined,
                  )
                else ...[
                  const SectionHeading(
                    eyebrow: 'Mejora tu experiencia',
                    title: 'Elige tu plan',
                  ),
                  const SizedBox(height: Brand.s12),
                  for (var i = 0; i < subscriptions.plans.length; i++)
                    MotionReveal(
                      delay: Duration(milliseconds: 60 * i),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: Brand.s12),
                        child: PlanCard(
                          plan: subscriptions.plans[i],
                          current: subscriptions.paidSubscription?.planId ==
                              subscriptions.plans[i].id,
                          onTap: () => _openDetail(
                            context,
                            subscriptions,
                            auth,
                            subscriptions.plans[i],
                          ),
                          onChoose: () => _choose(
                            context,
                            subscriptions,
                            auth,
                            subscriptions.plans[i],
                          ),
                        ),
                      ),
                    ),
                ],
                if (subscriptions.paidSubscription != null) ...[
                  const SizedBox(height: Brand.s12),
                  _CancelCard(
                    subscription: subscriptions.paidSubscription!,
                    onCancel: () => _cancel(context, subscriptions),
                  ),
                ],
                const SizedBox(height: Brand.s16),
                Text(
                  'Activación simulada de beta: no se cobra nada en la app. '
                  'El beneficio se activa al instante y no se renueva solo.',
                  textAlign: TextAlign.center,
                  style: context.text.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    if (embedded) return body;
    return Scaffold(
      appBar: TotoTopBar(
        showWordmark: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
      ),
      body: body,
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    SubscriptionController subscriptions,
    AuthController auth,
    DeliveryPlan plan,
  ) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (sheetContext) => PlanDetailSheet(
        plan: plan,
        onChoose: () => Navigator.of(sheetContext).pop(true),
      ),
    ).then((chosen) async {
      if (chosen == true && context.mounted) {
        await _choose(context, subscriptions, auth, plan);
      }
    });
  }

  Future<void> _choose(
    BuildContext context,
    SubscriptionController subscriptions,
    AuthController auth,
    DeliveryPlan plan,
  ) async {
    if (!auth.isSignedIn) {
      final logged = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
      if (!context.mounted || logged != true) return;
    }
    final ok = await subscriptions.activate(plan);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '${plan.name} activo. Ya puedes pedir con envío gratis.'
                : subscriptions.error ?? 'No se pudo activar el plan.',
          ),
        ),
      );
  }

  Future<void> _cancel(
    BuildContext context,
    SubscriptionController subscriptions,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('CANCELAR PLAN'),
        content: const Text(
          'Si no usaste el envío y cancelas dentro de las primeras 24 horas, '
          'la activación se revierte. Si ya lo usaste, mantienes el beneficio '
          'hasta el vencimiento y no hay reembolso parcial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('VOLVER'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('CANCELAR PLAN'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await subscriptions.cancel();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Plan cancelado. Revisa hasta cuándo mantienes el beneficio.'
                : subscriptions.error ?? 'No se pudo cancelar el plan.',
          ),
        ),
      );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.base,
    required this.subscription,
    this.paidPlan,
  });

  final PlanBase base;
  final Subscription? subscription;
  final DeliveryPlan? paidPlan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final paid = subscription;
    final name = paid?.planName ?? base.name;
    final description = paid == null
        ? base.description
        : '${paid.status.label} · vence '
            '${DateFormat('dd/MM/yyyy').format(paid.endAt)}';
    return Container(
      padding: const EdgeInsets.all(Brand.s12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          PlanImage(
            media: paidPlan?.image ?? base.image,
            iconSvg: paidPlan?.iconSvg ?? base.iconSvg,
            label: name,
            size: 56,
            requestWidth: 160,
          ),
          const SizedBox(width: Brand.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TU PLAN ACTUAL',
                  style: Brand.ui(
                    9,
                    weight: FontWeight.w700,
                    color: colors.action,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name.toUpperCase(),
                  style: Brand.display(20, h: 1, color: colors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: context.text.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (paid != null) ...[
                  const SizedBox(height: Brand.s4),
                  Text(
                    paid.shipmentsUsed == 0
                        ? 'Aún no usaste el envío gratis'
                        : 'Envíos usados: ${paid.shipmentsUsed}',
                    style: context.text.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelCard extends StatelessWidget {
  const _CancelCard({
    required this.subscription,
    required this.onCancel,
  });

  final Subscription subscription;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
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
            'GESTIONAR PLAN',
            style: Brand.ui(
              9,
              weight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: Brand.s4),
          Text(
            'Vence el ${DateFormat('dd/MM/yyyy').format(subscription.endAt)}. '
            'No se renueva automáticamente.',
            style: context.text.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: Brand.s8),
          TextButton(
            onPressed: onCancel,
            child: const Text('CANCELAR PLAN'),
          ),
        ],
      ),
    );
  }
}
