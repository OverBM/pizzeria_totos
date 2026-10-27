import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/branch_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/checkout_controller.dart';
import '../../core/format/money.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/components.dart';
import '../../core/theme/theme_context.dart';
import '../../models/cart_item.dart';
import '../../models/media_ref.dart';
import '../../models/order.dart';
import '../../models/payment_method.dart';
import '../../services/contact_launcher.dart';
import '../../services/order_message_builder.dart';
import '../../services/settings_service.dart';
import '../common/drive_image.dart';

/// Carrito y checkout derivado del perfil autenticado.
class CartView extends StatefulWidget {
  const CartView({
    super.key,
    required this.onGoToCarta,
    required this.onOpenAuth,
    required this.onOpenProfile,
    required this.onOpenOrders,
  });

  final VoidCallback onGoToCarta;
  final VoidCallback onOpenAuth;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenOrders;

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final checkout = context.watch<CheckoutController>();
    final auth = context.watch<AuthController>();
    final branches = context.watch<BranchController>();

    if (cart.isEmpty) {
      return SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: EmptyState(
            title: 'Tu pedido está vacío',
            message:
                'Explora la carta y agrega tus favoritas. '
                'Tu carrito se conserva aunque inicies sesión.',
            icon: Icons.shopping_bag_outlined,
            actionLabel: 'VER LA CARTA',
            onAction: widget.onGoToCarta,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Brand.s16,
        Brand.s24,
        Brand.s16,
        Brand.s24,
      ),
      children: [
        SectionHeading(
          eyebrow: 'Tu pedido',
          title: 'Lo que elegiste',
          actionLabel: 'Mis pedidos',
          onAction: widget.onOpenOrders,
        ),
        const SizedBox(height: Brand.s12),
        for (final item in cart.items) ...[
          _CartLine(item: item, cart: cart),
          const SizedBox(height: Brand.s8),
        ],
        const SizedBox(height: Brand.s8),
        _sessionCard(context, auth),
        const SizedBox(height: Brand.s16),
        _deliverySection(context, checkout, branches, auth),
        const SizedBox(height: Brand.s16),
        _paymentSection(context, checkout),
        const SizedBox(height: Brand.s16),
        TextField(
          controller: _note,
          maxLines: 2,
          onChanged: checkout.setNote,
          decoration: const InputDecoration(
            labelText: 'Nota para la cocina (opcional)',
            hintText: 'Sin cebolla, tocar el timbre…',
          ),
        ),
        const SizedBox(height: Brand.s16),
        _totals(context, cart, checkout),
        const SizedBox(height: Brand.s16),
        _issues(context, checkout),
        const SizedBox(height: Brand.s8),
        PillButton(
          label: auth.isSignedIn
              ? (checkout.isSubmitting ? 'CONFIRMANDO…' : 'CONFIRMAR PEDIDO')
              : 'INICIA SESIÓN PARA PEDIR',
          expanded: true,
          showArrow: true,
          onPressed: checkout.isSubmitting
              ? null
              : auth.isSignedIn
              ? () => _submit(context, checkout)
              : widget.onOpenAuth,
        ),
        const SizedBox(height: Brand.s8),
        Text(
          'No se cobra en la app. Coordinamos el pago y la entrega por WhatsApp.',
          textAlign: TextAlign.center,
          style: context.text.caption.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _sessionCard(BuildContext context, AuthController auth) {
    final colors = context.colors;
    if (!auth.isSignedIn) {
      return Container(
        padding: const EdgeInsets.all(Brand.s12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: Brand.cardRadius,
          border: Border.all(color: colors.action),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded, color: colors.action),
            const SizedBox(width: Brand.s8),
            const Expanded(
              child: Text(
                'Inicia sesión para confirmar tu pedido con tus datos.',
              ),
            ),
            TextButton(
              onPressed: widget.onOpenAuth,
              child: const Text('ENTRAR'),
            ),
          ],
        ),
      );
    }
    final account = auth.account;
    return ProfileChip(
      name: account?.name ?? 'Tu cuenta',
      subtitle: account?.phone.isEmpty ?? true
          ? 'Falta tu teléfono · completar perfil'
          : account!.phone,
      onTap: widget.onOpenProfile,
    );
  }

  Widget _deliverySection(
    BuildContext context,
    CheckoutController checkout,
    BranchController branches,
    AuthController auth,
  ) {
    final colors = context.colors;
    final selected = checkout.selectedBranch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(eyebrow: 'Entrega', title: 'Dónde y cómo'),
        const SizedBox(height: Brand.s12),
        if (branches.branches.isEmpty)
          Text(
            'No hay sedes disponibles para elegir.',
            style: context.text.bodySm,
          )
        else
          Wrap(
            spacing: Brand.s8,
            runSpacing: Brand.s8,
            children: [
              for (final branch in branches.branches)
                FilterPill(
                  label: branch.name,
                  selected: selected?.id == branch.id,
                  onTap: () => checkout.selectBranch(branch.id),
                ),
            ],
          ),
        const SizedBox(height: Brand.s12),
        Row(
          children: [
            FilterPill(
              label: 'DELIVERY',
              selected: checkout.type == OrderType.delivery,
              onTap: selected != null && !selected.delivers
                  ? null
                  : () => checkout.setType(OrderType.delivery),
            ),
            const SizedBox(width: Brand.s8),
            FilterPill(
              label: 'RECOJO EN TIENDA',
              selected: checkout.type == OrderType.pickup,
              onTap: () => checkout.setType(OrderType.pickup),
            ),
          ],
        ),
        if (checkout.type == OrderType.delivery) ...[
          const SizedBox(height: Brand.s12),
          if (!auth.isSignedIn)
            Text(
              'Inicia sesión para usar tus direcciones guardadas.',
              style: context.text.bodySm,
            )
          else if (auth.account?.addresses.isEmpty ?? true)
            OutlinedButton.icon(
              onPressed: widget.onOpenProfile,
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: const Text('AGREGAR DIRECCIÓN'),
            )
          else
            RadioGroup<String>(
              groupValue: checkout.selectedAddress?.id,
              onChanged: (value) {
                if (value != null) checkout.selectAddress(value);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final address in auth.account!.addresses)
                    RadioListTile<String>(
                      value: address.id,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: colors.action,
                      title: Text(
                        address.title.toUpperCase(),
                        style: Brand.ui(12, weight: FontWeight.w700),
                      ),
                      subtitle: Text(address.line, style: context.text.caption),
                    ),
                  TextButton.icon(
                    onPressed: widget.onOpenProfile,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('EDITAR DIRECCIONES'),
                  ),
                ],
              ),
            ),
          if (selected != null && !selected.delivers)
            Padding(
              padding: const EdgeInsets.only(top: Brand.s8),
              child: Text(
                'Esta sede no tiene delivery: elige recojo en tienda.',
                style: Brand.ui(11, color: colors.action),
              ),
            ),
        ],
        if (selected != null) ...[
          const SizedBox(height: Brand.s8),
          Text(
            '${selected.name} · ${selected.address}',
            style: context.text.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _paymentSection(BuildContext context, CheckoutController checkout) {
    final methods = checkout.paymentMethods;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(eyebrow: 'Pago', title: 'Cómo pagas'),
        const SizedBox(height: Brand.s12),
        Wrap(
          spacing: Brand.s8,
          runSpacing: Brand.s8,
          children: [
            for (final PaymentMethod method in methods)
              FilterPill(
                label: method.label,
                selected: checkout.selectedPaymentMethod.id == method.id,
                onTap: () => checkout.selectPaymentMethod(method.id),
              ),
          ],
        ),
      ],
    );
  }

  Widget _totals(
    BuildContext context,
    CartController cart,
    CheckoutController checkout,
  ) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(Brand.s12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _row(context, 'Subtotal', Money.format(cart.subtotalSoles)),
          if (cart.savingsSoles > 0)
            _row(
              context,
              'Ahorro por promociones',
              '- ${Money.format(cart.savingsSoles)}',
              accent: true,
            ),
          _row(
            context,
            checkout.type == OrderType.pickup ? 'Recojo en tienda' : 'Envío',
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
                  color: colors.textPrimary,
                ),
              ),
            ],
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
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.bodySm.copyWith(color: colors.textSecondary),
            ),
          ),
          Text(
            value,
            style: Brand.ui(
              13,
              weight: FontWeight.w700,
              color: accent ? colors.action : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _issues(BuildContext context, CheckoutController checkout) {
    final issues = checkout.validate();
    if (issues.isEmpty && checkout.error == null) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    return Container(
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
          if (checkout.error != null)
            Text(checkout.error!, style: Brand.ui(12, color: colors.action)),
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
                    child: Text(issue.message, style: context.text.caption),
                  ),
                ],
              ),
            ),
          if (issues.any(
            (issue) =>
                issue == CheckoutIssue.noPhone ||
                issue == CheckoutIssue.noAddress,
          ))
            Padding(
              padding: const EdgeInsets.only(top: Brand.s8),
              child: OutlinedButton(
                onPressed: widget.onOpenProfile,
                child: const Text('COMPLETAR PERFIL'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    CheckoutController checkout,
  ) async {
    final order = await checkout.submit();
    if (!context.mounted) return;
    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(checkout.error ?? 'No se pudo registrar el pedido.'),
        ),
      );
      return;
    }
    _note.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ConfirmationSheet(order: order),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.item, required this.cart});

  final CartItem item;
  final CartController cart;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(Brand.s8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 72,
            width: 72,
            child: DriveImage(
              media: item.image == null ? null : _media(item.image!),
              placeholderLabel: item.name,
              borderRadius: Brand.cardRadius,
            ),
          ),
          const SizedBox(width: Brand.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Brand.ui(
                    13,
                    weight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  item.variantLabel,
                  style: context.text.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: Brand.s4),
                Row(
                  children: [
                    if (item.isOnPromo)
                      Padding(
                        padding: const EdgeInsets.only(right: Brand.s4),
                        child: Text(
                          Money.format(item.originalUnitPriceSoles!),
                          style: Brand.ui(
                            10,
                            color: colors.textSecondary,
                          ).copyWith(decoration: TextDecoration.lineThrough),
                        ),
                      ),
                    Text(
                      Money.format(item.lineTotalSoles),
                      style: Brand.ui(
                        13,
                        weight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => cart.remove(item.key),
                icon: const Icon(Icons.close_rounded, size: 16),
                tooltip: 'Quitar ${item.name}',
                visualDensity: VisualDensity.compact,
              ),
              QuantityStepper(
                quantity: item.quantity,
                compact: true,
                onIncrement: () => cart.increment(item.key),
                onDecrement: () => cart.decrement(item.key),
              ),
            ],
          ),
        ],
      ),
    );
  }

  MediaRef _media(String value) => MediaRef.fromValue(value) ?? MediaRef.none;
}

class _ConfirmationSheet extends StatelessWidget {
  const _ConfirmationSheet({required this.order});

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
}
