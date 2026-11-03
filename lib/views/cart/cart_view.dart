import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/catalog_controller.dart';
import '../../controllers/checkout_controller.dart';
import '../../core/data/product_summary.dart';
import '../../core/format/money.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/product_family.dart';
import '../../core/theme/theme_context.dart';
import '../../models/cart_item.dart';
import '../../models/media_ref.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../widgets/pizza_art.dart';
import '../../widgets/widgets.dart';
import '../carta/combo_configurator_sheet.dart';

/// Carrito y Paso 1 del checkout.
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
  final TextEditingController _recipientName = TextEditingController();
  final TextEditingController _recipientPhone = TextEditingController();

  @override
  void dispose() {
    _recipientName.dispose();
    _recipientPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final checkout = context.watch<CheckoutController>();
    final auth = context.watch<AuthController>();
    final catalog = context.watch<CatalogController>();
    final suggestions = _suggestions(catalog, cart);

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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        Brand.s16,
        Brand.s16,
        Brand.s16,
        Brand.s80,
      ),
      children: [
        _header(context, cart),
        const SizedBox(height: Brand.s8),
        for (final item in cart.items) ...[
          Dismissible(
            key: ValueKey(item.key),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: Brand.s20),
              decoration: BoxDecoration(
                color: context.colors.action,
                borderRadius: Brand.cardRadius,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: context.colors.onAction,
              ),
            ),
            onDismissed: (_) {
              cart.remove(item.key);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('${item.name} retirado'),
                    action: SnackBarAction(
                      label: 'DESHACER',
                      onPressed: () => cart.restore(item),
                    ),
                  ),
                );
            },
            child: _CartLine(
              item: item,
              cart: cart,
              onEdit: () => _editLine(context, item),
            ),
          ),
          const SizedBox(height: Brand.s8),
        ],
        const SizedBox(height: Brand.s8),
        _CartDetails(items: cart.items),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: Brand.s16),
          _suggestionsSection(context, cart, suggestions),
        ],
        const SizedBox(height: Brand.s16),
        _summary(context, cart, checkout),
        const SizedBox(height: Brand.s16),
        _sessionCard(context, auth),
        const SizedBox(height: Brand.s16),
        _recipientSection(context, checkout, auth),
        const SizedBox(height: Brand.s16),
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

  Widget _header(BuildContext context, CartController cart) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'PASO 1 DE 3 · TU PEDIDO',
                style: Brand.ui(
                  10,
                  weight: FontWeight.w700,
                  color: colors.action,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _confirmClear(context, cart),
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('VACIAR'),
            ),
          ],
        ),
        Text(
          'LO QUE ELEGISTE',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Brand.display(22, h: 1, color: colors.textPrimary),
        ),
        const SizedBox(height: Brand.s12),
      ],
    );
  }

  Future<void> _confirmClear(BuildContext context, CartController cart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('VACIAR CARRITO'),
        content: const Text('¿Quitar todos los productos de tu pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('VACIAR'),
          ),
        ],
      ),
    );
    if (confirmed == true) await cart.clear();
  }

  Future<void> _editLine(BuildContext context, CartItem item) async {
    if (item.isCustomPizza) {
      await Navigator.of(context)
          .push(AppRoutes.customPizza(initialItem: item));
      return;
    }
    final catalog = context.read<CatalogController>();
    final product = catalog.byId(item.productId);
    if (product == null) return;
    final variant =
        product.variantForLabel(item.variantLabel) ??
        product.defaultVariantOrNull;
    if (variant == null) return;

    if (product.hasComponentes) {
      final selection = await showModalBottomSheet<ComboSelection>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.colors.surface,
        builder: (_) => ComboConfiguratorSheet(
          product: product,
          variant: variant,
          initialExtras: item.extras,
          initialComponents: item.componentes,
        ),
      );
      if (selection == null || !context.mounted) return;
      context.read<CartController>().replaceLine(
        item.key,
        product,
        variant,
        quantity: item.quantity,
        masa: item.masa,
        extras: selection.extras,
        componentes: selection.componentes,
      );
      return;
    }

    await Navigator.of(context).push(
      AppRoutes.product(
        product,
        variantLabel: item.variantLabel,
        initialItem: item,
      ),
    );
  }

  List<Product> _suggestions(CatalogController catalog, CartController cart) {
    final inCart = cart.items.map((item) => item.productId).toSet();
    const complements = {
      'pizzas': {'bebidas', 'guarniciones', 'dulces'},
      'medias': {'bebidas', 'guarniciones', 'dulces'},
      'familiares': {'bebidas', 'guarniciones', 'dulces'},
      'pastas': {'bebidas', 'guarniciones', 'dulces'},
      'lasanas': {'bebidas', 'guarniciones', 'dulces'},
      'combos': {'bebidas', 'dulces'},
      'guarniciones': {'bebidas', 'dulces'},
      'bebidas': {'guarniciones', 'dulces'},
      'dulces': {'bebidas'},
    };
    final cartCategories = cart.items
        .map((item) => catalog.byId(item.productId)?.categoryId)
        .whereType<String>()
        .toSet();
    final preferred = <String>{};
    for (final category in cartCategories) {
      preferred.addAll(complements[category] ?? const {});
    }
    if (preferred.isEmpty) {
      preferred.addAll(const {'bebidas', 'guarniciones', 'dulces'});
    }
    final available = catalog.listedProducts
        .where((product) => product.isSellable && !inCart.contains(product.id))
        .toList();
    final first = available
        .where((product) => preferred.contains(product.categoryId))
        .toList();
    final rest = available
        .where((product) => !preferred.contains(product.categoryId))
        .toList();
    return [...first, ...rest].take(4).toList();
  }

  Widget _suggestionsSection(
    BuildContext context,
    CartController cart,
    List<Product> products,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          eyebrow: 'Suma algo más',
          title: 'Complementa tu pedido',
        ),
        const SizedBox(height: Brand.s12),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: Brand.s8),
            itemBuilder: (context, index) {
              final product = products[index];
              return _SuggestionCard(
                product: product,
                onTap: () =>
                    Navigator.of(context).push(AppRoutes.product(product)),
                onAdd: product.isSellable
                    ? () {
                        final variant = product.defaultVariantOrNull;
                        if (variant == null) return;
                        addProductToCart(context, product, variant);
                      }
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _summary(
    BuildContext context,
    CartController cart,
    CheckoutController checkout,
  ) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(color: colors.border),
      ),
      child: Material(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: Brand.s12),
            childrenPadding: const EdgeInsets.fromLTRB(
              Brand.s12,
              0,
              Brand.s12,
              Brand.s12,
            ),
            iconColor: colors.textSecondary,
            collapsedIconColor: colors.textSecondary,
            title: Row(
              children: [
                Text(
                  'RESUMEN DE PEDIDO',
                  style: Brand.ui(
                    10,
                    weight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  Money.format(checkout.totalSoles),
                  style: Brand.ui(14, weight: FontWeight.w700),
                ),
              ],
            ),
            children: [
              _row(context, 'Subtotal', Money.format(cart.subtotalSoles)),
              if (cart.discountSoles > 0)
                _row(
                  context,
                  'Promociones',
                  '- ${Money.format(cart.discountSoles)}',
                  accent: true,
                ),
              if (checkout.couponDiscountSoles > 0)
                _row(
                  context,
                  'Cupón',
                  '- ${Money.format(checkout.couponDiscountSoles)}',
                  accent: true,
                ),
              _row(
                context,
                checkout.type == OrderType.pickup
                    ? 'Recojo en tienda'
                    : checkout.subscriptionBenefitApplies
                    ? 'Envío incluido'
                    : checkout.deliveryEstimated
                    ? 'Envío estimado'
                    : 'Envío',
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
                  AnimatedMoney(
                    value: checkout.totalSoles,
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

  Widget _recipientSection(
    BuildContext context,
    CheckoutController checkout,
    AuthController auth,
  ) {
    final colors = context.colors;
    final other = checkout.recipientMode == OrderRecipientMode.other;
    if (!other) {
      _recipientName.clear();
      _recipientPhone.clear();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(eyebrow: 'Destinatario', title: '¿Para quién es?'),
        const SizedBox(height: Brand.s12),
        Wrap(
          spacing: Brand.s8,
          runSpacing: Brand.s8,
          children: [
            FilterPill(
              label: 'PARA MÍ',
              selected: !other,
              onTap: () => checkout.setRecipientMode(OrderRecipientMode.self),
            ),
            FilterPill(
              label: 'PARA OTRA PERSONA',
              selected: other,
              onTap: () => checkout.setRecipientMode(OrderRecipientMode.other),
            ),
          ],
        ),
        const SizedBox(height: Brand.s12),
        if (other) ...[
          TextField(
            controller: _recipientName,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: checkout.setRecipientName,
            decoration: const InputDecoration(
              labelText: 'Nombre de quien recibe',
              hintText: 'Luis, mamá, oficina…',
            ),
          ),
          const SizedBox(height: Brand.s8),
          TextField(
            controller: _recipientPhone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onChanged: checkout.setRecipientPhone,
            decoration: const InputDecoration(
              labelText: 'Teléfono de quien recibe (opcional)',
              hintText: '999 111 222',
            ),
          ),
          const SizedBox(height: Brand.s4),
          Text(
            'Si no pones teléfono, el repartidor contacta al comprador.',
            style: context.text.caption.copyWith(color: colors.textSecondary),
          ),
        ] else
          Text(
            auth.isSignedIn
                ? '${auth.account?.name ?? ''} · ${auth.account?.phone ?? ''}'
                : 'Inicia sesión para usar tus datos al confirmar el pedido.',
            style: context.text.caption.copyWith(color: colors.textSecondary),
          ),
      ],
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.item,
    required this.cart,
    required this.onEdit,
  });

  final CartItem item;
  final CartController cart;
  final VoidCallback onEdit;

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
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 72,
                width: 72,
                child: item.isCustomPizza
                    ? Padding(
                        padding: const EdgeInsets.all(4),
                        child: PizzaArt(selection: item.customPizza, size: 64),
                      )
                    : DriveImage(
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
                    Padding(
                      padding: const EdgeInsets.only(right: 70),
                      child: Text(
                        item.name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Brand.ui(
                          13,
                          weight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (item.customPizza != null) ...[
                      const SizedBox(height: Brand.s4),
                      for (final line in item.customPizza!.detailLines.take(2))
                        Text(
                          line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                    ],
                    const SizedBox(height: Brand.s16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Precio',
                                style: context.text.caption.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              AnimatedMoney(
                                value: item.lineTotalSoles,
                                style: Brand.ui(
                                  16,
                                  weight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Brand.s16),
                        RemoveLineButton(
                          onTap: () => cart.remove(item.key),
                          productName: item.name,
                        ),
                        const SizedBox(width: Brand.s16),
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
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: TextButton.icon(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 26),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const EditIcon(size: 13),
              label: const Text('EDITAR'),
            ),
          ),
        ],
      ),
    );
  }

  MediaRef _media(String value) => MediaRef.fromValue(value) ?? MediaRef.none;
}

class _CartDetails extends StatelessWidget {
  const _CartDetails({required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: colors.surface,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: Brand.s12),
            childrenPadding: const EdgeInsets.fromLTRB(
              Brand.s12,
              0,
              Brand.s12,
              Brand.s12,
            ),
            iconColor: colors.textSecondary,
            collapsedIconColor: colors.textSecondary,
            title: Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 16,
                  color: colors.action,
                ),
                const SizedBox(width: Brand.s8),
                Expanded(
                  child: Text(
                    'VER DETALLE DEL PEDIDO',
                    style: Brand.ui(
                      10,
                      weight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              for (final item in items)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: Brand.s8),
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
                        '${item.quantity}× ${item.name}',
                        style: Brand.ui(12, weight: FontWeight.w700),
                      ),
                      if (item.masa != null)
                        Text(
                          'Masa: ${item.masa!.label}',
                          style: context.text.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      Text(
                        item.variantLabel,
                        style: context.text.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      for (final component in item.componentes)
                        Text(
                          '- ${component.cantidad}× ${component.nombre}'
                          '${component.opcion == null ? '' : ' (${component.opcion})'}',
                          style: context.text.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      for (final extra in item.extras)
                        Text(
                          '+ ${extra.nombre} ${Money.format(extra.precioSoles)}',
                          style: context.text.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      if (item.isOnPromo)
                        Text(
                          'Ahorro ${Money.format(item.savingsSoles)}',
                          style: context.text.caption.copyWith(
                            color: colors.action,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.product, this.onAdd, this.onTap});

  final Product product;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(Brand.s8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: Brand.cardRadius,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 78,
              width: double.infinity,
              child: DriveImage(
                media: product.image,
                placeholderLabel: product.name,
                borderRadius: Brand.cardRadius,
              ),
            ),
            const SizedBox(height: Brand.s8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Brand.ui(11, weight: FontWeight.w700),
            ),
            const SizedBox(height: Brand.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductFamilyIcon(categoryId: product.categoryId, size: 12),
                const SizedBox(width: Brand.s4),
                Expanded(
                  child: Text(
                    ProductSummary.of(product).visibleIngredients,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    Money.format(product.minPriceSoles),
                    style: Brand.ui(12, weight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.action,
                    foregroundColor: colors.onAction,
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                  tooltip: 'Agregar ${product.name}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
