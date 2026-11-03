import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/cart_controller.dart';
import '../../controllers/custom_pizza_controller.dart';
import '../../core/format/money.dart';
import '../../core/load_state.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../models/cart_item.dart';
import '../../models/custom_pizza.dart';
import '../../models/ingredient.dart';
import '../../widgets/pizza_art.dart';
import '../../widgets/widgets.dart';

/// Creador de pizza personalizada.
class CustomPizzaView extends StatefulWidget {
  const CustomPizzaView({super.key, this.initialItem});

  final CartItem? initialItem;

  @override
  State<CustomPizzaView> createState() => _CustomPizzaViewState();
}

class _CustomPizzaViewState extends State<CustomPizzaView> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final controller = context.read<CustomPizzaController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final initial = widget.initialItem?.customPizza;
      if (initial != null) {
        controller.hydrate(initial, quantity: widget.initialItem!.quantity);
      } else {
        controller.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomPizzaController>();
    final colors = context.colors;
    final selection = controller.selection;

    return Scaffold(
      appBar: TotoTopBar(
        showWordmark: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _body(context, controller, selection),
          ),
        ],
      ),
      bottomNavigationBar: selection == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                color: colors.canvas,
                padding: const EdgeInsets.fromLTRB(
                  Brand.s16,
                  Brand.s8,
                  Brand.s16,
                  Brand.s8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'TOTAL · ${controller.quantity} pizza${controller.quantity == 1 ? '' : 's'}',
                            style: Brand.ui(
                              9,
                              weight: FontWeight.w700,
                              color: colors.textSecondary,
                            ),
                          ),
                          AnimatedMoney(
                            value:
                                selection.unitPriceSoles * controller.quantity,
                            style: Brand.ui(
                              20,
                              weight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            'Lista en ~${selection.preparationMinutes} min',
                            style: context.text.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Brand.s12),
                    PillButton(
                      label: widget.initialItem == null
                          ? 'AGREGAR'
                          : 'GUARDAR',
                      showArrow: false,
                      onPressed: () => _add(context, controller),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _body(
    BuildContext context,
    CustomPizzaController controller,
    CustomPizzaSelection? selection,
  ) {
    if (controller.state == LoadState.loading && !controller.isReady) {
      return const SkeletonList(count: 4, height: 80);
    }
    if (controller.state == LoadState.error && !controller.isReady) {
      return EmptyState(
        title: 'No pudimos cargar la pizza',
        message: controller.error ?? 'Revisa tu conexión e inténtalo de nuevo.',
        icon: Icons.wifi_off_rounded,
        onAction: controller.load,
      );
    }
    if (!controller.isReady) {
      return const EmptyState(
        title: 'Pizza personalizada no disponible',
        message: 'Por ahora no hay tamaños o ingredientes publicados.',
        icon: Icons.local_pizza_outlined,
      );
    }

    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Brand.s16,
        Brand.s16,
        Brand.s16,
        Brand.s80,
      ),
      children: [
        MotionReveal(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '‹ HORNO ABIERTO ›',
                style: Brand.ui(
                  11,
                  weight: FontWeight.w700,
                  color: colors.action,
                ),
              ),
              const SizedBox(height: Brand.s4),
              Text(
                'ARMA TU PIZZA',
                style: Brand.display(30, h: 1, color: colors.textPrimary),
              ),
              const SizedBox(height: Brand.s8),
              Text(
                'Elige la base, la masa y tus ingredientes. La base incluye '
                'masa, salsa y queso estándar.',
                style: context.text.bodySm.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Brand.s16),
        _PizzaPreview(selection: selection),
        const SizedBox(height: Brand.s16),
        _title(context, 'TAMAÑO', 'Elige cuánto vas a compartir'),
        const SizedBox(height: Brand.s8),
        Wrap(
          spacing: Brand.s8,
          runSpacing: Brand.s8,
          children: [
            for (final size in controller.config.sizes)
              FilterPill(
                label: '${size.name} · ${size.diameterCm} cm',
                selected: controller.size?.id == size.id,
                onTap: () => controller.selectSize(size),
              ),
          ],
        ),
        const SizedBox(height: Brand.s20),
        _title(context, 'MASA', 'La base de la casa'),
        const SizedBox(height: Brand.s8),
        Wrap(
          spacing: Brand.s8,
          runSpacing: Brand.s8,
          children: [
            for (final option in controller.config.doughs)
              FilterPill(
                label: option.name,
                selected: controller.dough?.id == option.id,
                onTap: () => controller.selectDough(option),
              ),
          ],
        ),
        const SizedBox(height: Brand.s20),
        _title(context, 'SALSA', 'El carácter de tu pizza'),
        const SizedBox(height: Brand.s8),
        Wrap(
          spacing: Brand.s8,
          runSpacing: Brand.s8,
          children: [
            for (final option in controller.config.sauces)
              FilterPill(
                label: option.name,
                selected: controller.sauce?.id == option.id,
                onTap: () => controller.selectSauce(option),
              ),
          ],
        ),
        const SizedBox(height: Brand.s20),
        _title(context, 'QUESO', 'Estándar incluido; cambia el ajuste'),
        const SizedBox(height: Brand.s8),
        Wrap(
          spacing: Brand.s8,
          runSpacing: Brand.s8,
          children: [
            for (final option in controller.config.cheeses)
              FilterPill(
                label: option.name,
                selected: controller.cheese?.id == option.id,
                onTap: () => controller.selectCheese(option),
              ),
          ],
        ),
        const SizedBox(height: Brand.s20),
        _title(
          context,
          'INGREDIENTES',
          'Hasta ${controller.maxIngredients} para este tamaño',
        ),
        const SizedBox(height: Brand.s8),
        for (final ingredient in controller.ingredients) ...[
          _IngredientRow(
            ingredient: ingredient,
            selected: controller.selectedIngredientIds.contains(ingredient.id),
            enabled: ingredient.available &&
                (controller.selectedIngredientIds.contains(ingredient.id) ||
                    controller.canAddIngredient),
            price: Money.round(
              ingredient.priceSoles *
                  (controller.size?.ingredientMultiplier ?? 1),
            ),
            onTap: () => controller.toggleIngredient(ingredient),
          ),
          const SizedBox(height: Brand.s8),
        ],
        const SizedBox(height: Brand.s12),
        _Breakdown(selection: selection),
        const SizedBox(height: Brand.s16),
        Row(
          children: [
            Text(
              'CANTIDAD',
              style: Brand.ui(
                10,
                weight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const Spacer(),
            QuantityStepper(
              quantity: controller.quantity,
              onIncrement: () => controller.setQuantity(controller.quantity + 1),
              onDecrement: () => controller.setQuantity(controller.quantity - 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _title(BuildContext context, String title, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Brand.ui(
            11,
            weight: FontWeight.w700,
            color: context.colors.action,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hint,
          style: context.text.caption.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _add(BuildContext context, CustomPizzaController controller) {
    final selection = controller.selection;
    if (selection == null) return;
    final cart = context.read<CartController>();
    final initial = widget.initialItem;
    if (initial != null) {
      cart.replaceCustomPizza(
        initial.key,
        selection,
        quantity: controller.quantity,
      );
    } else {
      cart.addCustomPizza(selection, quantity: controller.quantity);
    }
    HapticFeedback.lightImpact();
    Navigator.of(context).maybePop(true);
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.selected,
    required this.enabled,
    required this.price,
    required this.onTap,
  });

  final Ingredient ingredient;
  final bool selected;
  final bool enabled;
  final double price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Opacity(
      opacity: enabled ? 1 : 0.42,
      child: MotionPressable(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(
            horizontal: Brand.s12,
            vertical: Brand.s10,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.surface : Colors.transparent,
            borderRadius: Brand.cardRadius,
            border: Border.all(
              color: selected ? colors.action : colors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                size: 20,
                color: selected ? colors.action : colors.textSecondary,
              ),
              const SizedBox(width: Brand.s8),
              Expanded(
                child: Text(
                  ingredient.name,
                  style: Brand.ui(13, weight: FontWeight.w500),
                ),
              ),
              Text(
                '+ ${Money.format(price)}',
                style: Brand.ui(12, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Representación visual de la pizza que se está armando.
class _PizzaPreview extends StatelessWidget {
  const _PizzaPreview({required this.selection});

  final CustomPizzaSelection? selection;

  @override
  Widget build(BuildContext context) {
    final value = selection;
    if (value == null) return const SizedBox.shrink();
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        Brand.s12,
        Brand.s16,
        Brand.s12,
        Brand.s12,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            'TU PIZZA',
            style: Brand.ui(
              9,
              weight: FontWeight.w700,
              color: colors.action,
            ),
          ),
          const SizedBox(height: Brand.s8),
          PizzaArt(selection: value, size: 190),
          const SizedBox(height: Brand.s8),
          Text(
            value.ingredients.isEmpty
                ? 'Base de la casa: masa, salsa y queso'
                : value.ingredients.map((i) => i.name).join(' · '),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.selection});

  final CustomPizzaSelection? selection;

  @override
  Widget build(BuildContext context) {
    final value = selection;
    if (value == null) return const SizedBox.shrink();
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
          _line(context, 'Base', value.basePriceSoles),
          if (value.doughCents != 0)
            _line(context, 'Masa', Money.fromCents(value.doughCents)),
          if (value.sauceCents != 0)
            _line(context, 'Salsa', Money.fromCents(value.sauceCents)),
          if (value.cheeseCents != 0)
            _line(context, 'Queso', Money.fromCents(value.cheeseCents)),
          if (value.ingredientsCents != 0)
            _line(context, 'Ingredientes', value.toppingsSoles),
          const Divider(height: Brand.s20),
          Row(
            children: [
              Text(
                'PRECIO',
                style: Brand.ui(
                  10,
                  weight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              AnimatedMoney(
                value: value.unitPriceSoles,
                style: Brand.ui(18, weight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.caption.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
          Text(Money.format(value), style: Brand.ui(12)),
        ],
      ),
    );
  }
}
