import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/checkout_controller.dart';
import '../../core/format/money.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../models/checkout_step.dart';
import '../../models/order.dart';
import '../../models/payment_method.dart';
import '../../widgets/widgets.dart';
import 'order_confirmation_sheet.dart';

/// Paso 3 del checkout: pago, nota, resumen y confirmación.
class CheckoutConfirmView extends StatefulWidget {
  const CheckoutConfirmView({super.key});

  @override
  State<CheckoutConfirmView> createState() => _CheckoutConfirmViewState();
}

class _CheckoutConfirmViewState extends State<CheckoutConfirmView> {
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: context.read<CheckoutController>().note);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _openLogin() async {
    await Navigator.of(context).push(AppRoutes.login());
  }

  Future<void> _submit() async {
    final checkout = context.read<CheckoutController>();
    final order = await checkout.submit();
    if (!mounted) return;
    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(checkout.error ?? 'No se pudo registrar el pedido.'),
        ),
      );
      return;
    }
    await showOrderConfirmation(context, order);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final checkout = context.watch<CheckoutController>();
    final auth = context.watch<AuthController>();
    final cart = context.watch<CartController>();
    final colors = context.colors;
    final issues = checkout.validate();
    final branch = checkout.selectedBranch;
    final delivery = checkout.type == OrderType.delivery;

    return Scaffold(
      appBar: TotoTopBar(
        showWordmark: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Brand.s16,
              0,
              Brand.s16,
              Brand.s12,
            ),
            child: CheckoutProgress(step: CheckoutStep.confirmar),
          ),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                Brand.s16,
                Brand.s16,
                Brand.s16,
                Brand.s80,
              ),
              children: [
                Text(
                  'PASO 3 DE 3',
                  style: Brand.ui(
                    10,
                    weight: FontWeight.w700,
                    color: colors.action,
                  ),
                ),
                const SizedBox(height: Brand.s4),
                Text(
                  'CONFIRMAR',
                  style: Brand.display(28, h: 1, color: colors.textPrimary),
                ),
                const SizedBox(height: Brand.s20),
                _card(
                  context,
                  title: 'RECIBE',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checkout.recipientMode == OrderRecipientMode.self
                            ? 'Para mí'
                            : (checkout.effectiveRecipientName.isEmpty
                                  ? 'Para otra persona'
                                  : checkout.effectiveRecipientName),
                        style: Brand.ui(12, weight: FontWeight.w700),
                      ),
                      if (checkout.effectiveRecipientPhone.isNotEmpty)
                        Text(
                          checkout.effectiveRecipientPhone,
                          style: context.text.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      if (checkout.contactName.isNotEmpty &&
                          checkout.contactName !=
                              checkout.effectiveRecipientName)
                        Text(
                          'Contacto: ${checkout.contactName} · '
                          '${checkout.contactPhone}',
                          style: context.text.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Brand.s12),
                _card(
                  context,
                  title: 'ENTREGA',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery ? 'Delivery' : 'Recojo en tienda',
                        style: Brand.ui(12, weight: FontWeight.w700),
                      ),
                      if (branch != null)
                        Text(
                          '${branch.name} · ${branch.address}',
                          style: context.text.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      if (delivery && checkout.deliveryAddressLabel.isNotEmpty)
                        Text(
                          checkout.deliveryAddressLabel,
                          style: context.text.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      if (delivery && checkout.deliveryQuote != null) ...[
                        const SizedBox(height: Brand.s4),
                        Text(
                          '${checkout.deliveryQuote!.distanceLabel} · '
                          '${checkout.deliveryBandLabel} · '
                          '${checkout.deliveryQuote!.etaMinutes} min',
                          style: context.text.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Brand.s20),
                const SectionHeading(eyebrow: 'Pago', title: 'Cómo pagas'),
                const SizedBox(height: Brand.s12),
                Wrap(
                  spacing: Brand.s8,
                  runSpacing: Brand.s8,
                  children: [
                    for (final PaymentMethod method
                        in checkout.paymentMethods)
                      FilterPill(
                        label: method.label,
                        selected:
                            checkout.selectedPaymentMethod.id == method.id,
                        onTap: () => checkout.selectPaymentMethod(method.id),
                      ),
                  ],
                ),
                const SizedBox(height: Brand.s20),
                TextField(
                  controller: _note,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  onChanged: checkout.setNote,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  decoration: const InputDecoration(
                    labelText: 'Nota para la cocina (opcional)',
                    hintText: 'Sin cebolla, tocar el timbre…',
                  ),
                ),
                const SizedBox(height: Brand.s20),
                const SectionHeading(eyebrow: 'Pedido', title: 'Tu detalle'),
                const SizedBox(height: Brand.s12),
                for (final item in cart.items) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}× ${item.name}',
                          style: context.text.bodySm,
                        ),
                      ),
                      Text(
                        Money.format(item.lineTotalSoles),
                        style: Brand.ui(12, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                  if (item.masa != null)
                    Text(
                      'Masa: ${item.masa!.label}',
                      style: context.text.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  if (item.extras.isNotEmpty)
                    Text(
                      item.extras.map((e) => e.nombre).join(' · '),
                      style: context.text.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: Brand.s4),
                ],
                const SizedBox(height: Brand.s8),
                _card(
                  context,
                  title: 'TOTAL',
                  child: Column(
                    children: [
                      _row(
                        context,
                        'Subtotal',
                        Money.format(cart.subtotalSoles),
                      ),
                      if (cart.discountSoles > 0)
                        _row(
                          context,
                          'Descuento',
                          '- ${Money.format(cart.discountSoles)}',
                          accent: true,
                        ),
                      _row(
                        context,
                        delivery ? 'Envío' : 'Recojo',
                        checkout.shippingSoles == 0
                            ? 'Sin costo'
                            : Money.format(checkout.shippingSoles),
                      ),
                      const Divider(height: Brand.s24),
                      Row(
                        children: [
                          Text(
                            'TOTAL',
                            style: Brand.ui(
                              12,
                              weight: FontWeight.w700,
                              color: colors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            Money.format(checkout.totalSoles),
                            style: Brand.ui(
                              22,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (issues.isNotEmpty) ...[
                  const SizedBox(height: Brand.s16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(Brand.s12),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: Brand.cardRadius,
                      border: Border.all(color: colors.action),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final issue in issues)
                          Padding(
                            padding: const EdgeInsets.only(top: Brand.s4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: colors.action,
                                ),
                                const SizedBox(width: Brand.s4),
                                Expanded(
                                  child: Text(
                                    issue.message,
                                    style: context.text.caption,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (issues.any(
                          (issue) =>
                              issue == CheckoutIssue.noPhone ||
                              issue == CheckoutIssue.noAddress,
                        ))
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              AppRoutes.profile(),
                            ),
                            child: const Text('COMPLETAR PERFIL'),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Brand.s16),
                Text(
                  'No se cobra en la app. Coordinamos el pago y la entrega por '
                  'WhatsApp.',
                  textAlign: TextAlign.center,
                  style: context.text.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(
            Brand.s16,
            Brand.s8,
            Brand.s16,
            Brand.s8,
          ),
          child: PillButton(
            label: !auth.isSignedIn
                ? 'INICIA SESIÓN PARA PEDIR'
                : checkout.isSubmitting
                ? 'CONFIRMANDO…'
                : 'CONFIRMAR PEDIDO',
            expanded: true,
            showArrow: true,
            onPressed: checkout.isSubmitting ||
                    (auth.isSignedIn && issues.isNotEmpty)
                ? null
                : auth.isSignedIn
                ? _submit
                : _openLogin,
          ),
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final colors = context.colors;
    return Container(
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
            title,
            style: Brand.ui(
              9,
              weight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: Brand.s4),
          child,
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Brand.s2),
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
              weight: FontWeight.w700,
              color: accent ? colors.action : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
