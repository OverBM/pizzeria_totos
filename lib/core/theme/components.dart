import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../motion/motion_widgets.dart';
import 'brand.dart';
import 'brand_logo.dart';
import 'theme_context.dart';

/// Lockup horizontal de la marca: logo oficial pequeño + bajada de marca.
///
/// No se redibuja el wordmark: se usa el asset oficial.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.height = 30, this.showTagline = true});

  final double height;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogo(surface: LogoSurface.transparent, height: height),
        if (showTagline) ...[
          const SizedBox(width: Brand.s8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TOTO'S",
                style: Brand.display(15, h: 1, color: context.colors.onBar),
              ),
              Text(
                'PIZZERÍA · HUANCAYO',
                style: Brand.ui(
                  7,
                  weight: FontWeight.w500,
                  color: context.colors.onBar.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Barra superior negra fija con el lockup y acciones.
class TotoTopBar extends StatelessWidget implements PreferredSizeWidget {
  const TotoTopBar({
    super.key,
    this.actions = const [],
    this.leading,
    this.showWordmark = true,
    this.bottom,
    this.transparent = false,
  });

  final List<Widget> actions;
  final Widget? leading;
  final bool showWordmark;
  final PreferredSizeWidget? bottom;
  final bool transparent;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: transparent ? Colors.transparent : context.colors.bar,
      leading: leading,
      leadingWidth: leading == null ? null : 56,
      titleSpacing: leading == null ? Brand.s16 : 0,
      title: showWordmark ? const BrandWordmark() : null,
      bottom: bottom,
      actions: [
        ...actions,
        const SizedBox(width: Brand.s8),
      ],
    );
  }
}

/// Velo vino sobre fotografías.
class BrandOverlay extends StatelessWidget {
  const BrandOverlay({super.key, this.opacity = 0.55, this.child});

  final double opacity;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Brand.signMaroon.withValues(alpha: opacity * 0.55),
            Brand.signMaroon.withValues(alpha: opacity),
            Brand.signBlack.withValues(alpha: 0.55),
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: child,
    );
  }
}

/// Aviso discreto de datos cacheados o de servicio degradado.
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({
    super.key,
    this.message = 'Sin conexión: estás viendo la última información guardada.',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Brand.s12,
        vertical: Brand.s8,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.buttonRadius,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: colors.textSecondary),
          const SizedBox(width: Brand.s8),
          Expanded(child: Text(message, style: context.text.bodySm)),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: Brand.s8),
                minimumSize: const Size(0, 32),
              ),
              child: Text('REINTENTAR', style: context.text.label),
            ),
        ],
      ),
    );
  }
}

/// Encabezado de sección: eyebrow entre corchetes, titular y acción.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.eyebrow,
    this.title,
    this.actionLabel,
    this.onAction,
    this.outlined = false,
    this.crossAxis = CrossAxisAlignment.start,
  });

  final String eyebrow;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool outlined;
  final CrossAxisAlignment crossAxis;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final eyebrowStyle = Brand.ui(
      12,
      weight: FontWeight.w500,
      color: colors.action,
    );
    return Column(
      crossAxisAlignment: crossAxis,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('‹ ', style: eyebrowStyle),
            Expanded(
              child: Text(
                eyebrow.toUpperCase(),
                style: eyebrowStyle.copyWith(color: colors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(' ›', style: eyebrowStyle),
          ],
        ),
        if (title != null) ...[
          const SizedBox(height: Brand.s8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: outlined
                    ? OutlinedDisplayTitle(title!, size: 32)
                    : Text(title!.toUpperCase(), style: context.text.heading),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel!.toUpperCase(),
                    style:
                        Brand.ui(
                          12,
                          weight: FontWeight.w700,
                          color: colors.textPrimary,
                        ).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: colors.action,
                          decorationThickness: 2,
                        ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Titular display con contorno naranja.
class OutlinedDisplayTitle extends StatelessWidget {
  const OutlinedDisplayTitle(
    this.text, {
    super.key,
    this.size = 44,
    this.textAlign = TextAlign.left,
  });

  final String text;
  final double size;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = Brand.display(size, h: 0.95, color: colors.textPrimary);
    return Stack(
      children: [
        Text(
          text.toUpperCase(),
          textAlign: textAlign,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..strokeJoin = StrokeJoin.round
              ..color = colors.action,
          ),
        ),
        Text(text.toUpperCase(), textAlign: textAlign, style: base),
      ],
    );
  }
}

/// Botón principal o secundario de 50 dp.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.filled = true,
    this.expanded = false,
    this.showArrow = false,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final bool expanded;
  final bool showArrow;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: Brand.s8),
        ],
        Flexible(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showArrow) ...[
          const SizedBox(width: Brand.s8),
          const Text('›', style: TextStyle(fontSize: 20, height: 1)),
        ],
      ],
    );

    final shape = RoundedRectangleBorder(borderRadius: Brand.buttonRadius);
    final button = SizedBox(
      height: height,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(shape: shape),
              child: content,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                shape: shape,
                side: BorderSide(color: colors.textPrimary),
                foregroundColor: colors.textPrimary,
              ),
              child: content,
            ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Chip de filtro de 44 dp.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.iconWidget,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MotionPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        curve: Motion.standard,
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: Brand.s16),
        decoration: BoxDecoration(
          color: selected ? colors.action : Colors.transparent,
          borderRadius: Brand.buttonRadius,
          border: Border.all(
            color: selected ? Colors.transparent : Brand.boneWhite30,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconWidget != null) ...[
              iconWidget!,
              const SizedBox(width: Brand.s8),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? colors.onAction : colors.textSecondary,
              ),
              const SizedBox(width: Brand.s8),
            ],
            Text(
              label.toUpperCase(),
              style: Brand.ui(
                13,
                weight: FontWeight.w500,
                color: selected ? colors.onAction : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta destacada de radio 22 con foto, etiqueta y precio circular.
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({
    super.key,
    required this.image,
    required this.title,
    required this.priceLabel,
    this.eyebrow,
    this.description,
    this.onTap,
    this.onAdd,
    this.width = 268,
    this.imageHeight = 223,
  });

  final Widget image;
  final String title;
  final String priceLabel;
  final String? eyebrow;
  final String? description;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final double width;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: width,
      child: MotionPressable(
        onTap: onTap,
        semanticLabel: title,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: image,
                  ),
                  if (eyebrow != null)
                    Positioned(
                      left: Brand.s12,
                      top: Brand.s12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Brand.s8,
                          vertical: Brand.s4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.bar,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colors.action),
                        ),
                        child: Text(
                          eyebrow!.toUpperCase(),
                          style: Brand.ui(
                            9,
                            weight: FontWeight.w700,
                            color: colors.onBar,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(Brand.s12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Brand.display(
                              17,
                              h: 1.05,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (description != null) ...[
                            const SizedBox(height: Brand.s4),
                            Text(
                              description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySm.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: Brand.s8),
                          PriceCircle(priceLabel: priceLabel, onTap: onTap),
                        ],
                      ),
                    ),
                    if (onAdd != null)
                      _RoundAction(
                        icon: Icons.add_rounded,
                        onTap: onAdd,
                        label: 'Agregar $title',
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

/// Precio en círculo naranja de 54 dp.
class PriceCircle extends StatelessWidget {
  const PriceCircle({
    super.key,
    required this.priceLabel,
    this.onTap,
    this.size = 54,
  });

  final String priceLabel;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final circle = Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.action, shape: BoxShape.circle),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            priceLabel,
            style: Brand.ui(
              12,
              weight: FontWeight.w700,
              color: colors.onAction,
              h: 1,
            ),
          ),
        ),
      ),
    );
    if (onTap == null) return circle;
    return GestureDetector(onTap: onTap, child: circle);
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.onTap,
    this.label,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: colors.action,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: colors.onAction),
        ),
      ),
    );
  }
}

/// Tarjeta horizontal de carta: foto 126 × 151 y datos a la derecha.
class ProductRowCard extends StatelessWidget {
  const ProductRowCard({
    super.key,
    required this.image,
    required this.name,
    required this.description,
    required this.categoryLabel,
    required this.priceLabel,
    this.onTap,
    this.onAdd,
  });

  final Widget image;
  final String name;
  final String description;
  final String categoryLabel;
  final String priceLabel;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MotionPressable(
      onTap: onTap,
      semanticLabel: name,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: Brand.cardRadius,
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 151, width: 126, child: image),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(Brand.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.display(
                        17,
                        h: 1.05,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: Brand.s4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.ui(12, color: colors.textSecondary, h: 1.3),
                    ),
                    const SizedBox(height: Brand.s8),
                    Text(
                      categoryLabel.toUpperCase(),
                      style: Brand.ui(
                        9,
                        weight: FontWeight.w700,
                        color: colors.action,
                      ),
                    ),
                    const SizedBox(height: Brand.s8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            priceLabel,
                            style: Brand.ui(
                              17,
                              weight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        if (onAdd != null)
                          _RoundAction(
                            icon: Icons.add_rounded,
                            onTap: onAdd,
                            label: 'Agregar $name',
                            size: 36,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Control de cantidad con animación breve.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = compact ? 30.0 : 36.0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            size: size,
            onTap: onDecrement,
            label: 'Quitar uno',
          ),
          AnimatedSwitcher(
            duration: Motion.fast,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: SizedBox(
              width: 28,
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                textAlign: TextAlign.center,
                style: Brand.ui(14, weight: FontWeight.w700),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            size: size,
            onTap: onIncrement,
            label: 'Agregar uno',
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.size,
    this.onTap,
    this.label,
  });

  final IconData icon;
  final double size;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: size,
          width: size,
          child: Icon(icon, size: 16, color: context.colors.textPrimary),
        ),
      ),
    );
  }
}

/// Pill de estado: ABIERTA/CERRADA o estado de pedido.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.filled = true,
    this.color,
  });

  final String label;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = color ?? colors.action;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Brand.s10, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? accent : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: filled ? Colors.transparent : accent),
      ),
      child: Text(
        label.toUpperCase(),
        style: Brand.ui(
          10,
          weight: FontWeight.w700,
          color: filled ? colors.onAction : accent,
        ),
      ),
    );
  }
}

/// Icono de carrito con insignia animada.
class CartBadge extends StatelessWidget {
  const CartBadge({
    super.key,
    required this.count,
    this.onPressed,
    this.icon = Icons.shopping_cart_outlined,
  });

  final int count;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Ver pedido',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: colors.onBar, size: 24),
          if (count > 0)
            Positioned(
              right: -6,
              top: -6,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.6, end: 1),
                duration: Motion.resolve(context, Motion.base),
                curve: Curves.easeOutBack,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.action,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: Brand.ui(
                      9,
                      weight: FontWeight.w700,
                      color: colors.onAction,
                      h: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Insignia de descuento editorial.
class PromoBadge extends StatelessWidget {
  const PromoBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Brand.s10,
        vertical: Brand.s4,
      ),
      decoration: BoxDecoration(
        color: colors.bar,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.action, width: 2),
      ),
      child: Text(
        label.toUpperCase(),
        style: Brand.ui(11, weight: FontWeight.w700, color: colors.onBar),
      ),
    );
  }
}

/// Destino de la barra inferior.
class TotoNavItem {
  const TotoNavItem({required this.icon, required this.label, this.iconWidget});

  final IconData icon;
  final String label;
  final Widget? iconWidget;
}

/// Barra de navegación inferior negra de cinco destinos con subrayado.
class TotoBottomNav extends StatelessWidget {
  const TotoBottomNav({
    super.key,
    required this.index,
    required this.onSelect,
    required this.items,
    this.cartCount = 0,
    this.cartIndex = 2,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final List<TotoNavItem> items;
  final int cartCount;
  final int cartIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.bar,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavCell(
                    item: items[i],
                    active: i == index,
                    badge: i == cartIndex ? cartCount : 0,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.item,
    required this.active,
    required this.badge,
    required this.onTap,
  });

  final TotoNavItem item;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = active ? colors.onBar : colors.onBar.withValues(alpha: 0.62);
    return InkWell(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: Motion.resolve(context, Motion.fast),
                curve: Motion.enter,
                scale: active ? 1.08 : 1.0,
                child: _icon(color),
              ),
              const SizedBox(height: Brand.s4),
              Text(
                item.label,
                style: Brand.ui(
                  10,
                  weight: active ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          AnimatedPositioned(
            duration: Motion.resolve(context, Motion.base),
            curve: Motion.standard,
            bottom: 0,
            left: active ? 14 : 28,
            right: active ? 14 : 28,
            child: AnimatedContainer(
              duration: Motion.resolve(context, Motion.base),
              height: 2,
              color: active ? colors.action : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _icon(Color color) {
    final base = item.iconWidget;
    if (base == null) {
      return Icon(item.icon, color: color, size: 21);
    }
    return IconTheme(
      data: IconThemeData(color: color, size: 21),
      child: SizedBox(height: 21, width: 21, child: base),
    );
  }
}

/// Tarjeta de sede con bloque de mapa de marca.
class BranchMapCard extends StatelessWidget {
  const BranchMapCard({
    super.key,
    required this.name,
    required this.address,
    required this.statusLabel,
    required this.open,
    this.hoursLabel,
    this.deliveryLabel,
    this.onCall,
    this.onMap,
    this.onWhatsapp,
    this.selected = false,
    this.onSelect,
  });

  final String name;
  final String address;
  final String statusLabel;
  final bool open;
  final String? hoursLabel;
  final String? deliveryLabel;
  final VoidCallback? onCall;
  final VoidCallback? onMap;
  final VoidCallback? onWhatsapp;
  final bool selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(
          color: selected ? colors.action : colors.border,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 96,
            child: CustomPaint(
              painter: _MapGridPainter(color: colors.action),
              child: Center(
                child: Icon(
                  Icons.location_on_rounded,
                  color: colors.action,
                  size: 32,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Brand.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name.toUpperCase(),
                        style: Brand.display(
                          18,
                          h: 1,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    StatusPill(label: statusLabel, filled: open),
                  ],
                ),
                const SizedBox(height: Brand.s4),
                Text(address, style: context.text.bodySm),
                if (hoursLabel != null) ...[
                  const SizedBox(height: Brand.s2),
                  Text(
                    hoursLabel!,
                    style: Brand.ui(11, color: colors.textSecondary),
                  ),
                ],
                const SizedBox(height: Brand.s8),
                Row(
                  children: [
                    if (onCall != null)
                      _IconAction(
                        icon: Icons.call_outlined,
                        label: 'Llamar',
                        onTap: onCall,
                      ),
                    if (onWhatsapp != null)
                      _IconAction(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'WhatsApp',
                        onTap: onWhatsapp,
                      ),
                    if (onMap != null)
                      _IconAction(
                        icon: Icons.map_outlined,
                        label: 'Mapa',
                        onTap: onMap,
                      ),
                    const Spacer(),
                    if (onSelect != null)
                      TextButton(
                        onPressed: onSelect,
                        child: Text(
                          selected ? 'ELEGIDA' : 'ELEGIR',
                          style: Brand.ui(
                            11,
                            weight: FontWeight.w700,
                            color: colors.action,
                          ),
                        ),
                      ),
                  ],
                ),
                if (deliveryLabel != null)
                  Text(
                    deliveryLabel!,
                    style: Brand.ui(11, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 17, color: context.colors.textPrimary),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFF3E0A0C);
    canvas.drawRect(Offset.zero & size, background);
    final line = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    const step = 18.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final road = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.35,
        size.width,
        size.height * 0.5,
      );
    canvas.drawPath(path, road);
    final dot = Paint()..color = color.withValues(alpha: 0.45);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(12 + i * (size.width - 24) / 4, size.height * 0.2),
        2,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Estado vacío con acción de recarga.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.illustration,
    this.actionLabel = 'RECARGAR',
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? illustration;
  final String actionLabel;
  final VoidCallback? onAction;

  /// Acción secundaria opcional (p. ej. abrir la carpeta de Drive del negocio).
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Brand.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null)
              SizedBox(height: 160, width: 220, child: illustration)
            else
              Container(
                height: 96,
                width: 96,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(icon, size: 40, color: colors.action),
              ),
            const SizedBox(height: Brand.s16),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: Brand.display(22, h: 1.05, color: colors.textPrimary),
            ),
            const SizedBox(height: Brand.s8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodySm.copyWith(color: colors.textSecondary),
            ),
            if (onAction != null) ...[
              const SizedBox(height: Brand.s16),
              PillButton(
                label: actionLabel,
                onPressed: onAction,
                filled: false,
                showArrow: true,
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: Brand.s8),
              TextButton.icon(
                onPressed: onSecondary,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Esqueleto de lista durante la carga.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 4,
    this.height = 151,
    this.padding = const EdgeInsets.all(Brand.s16),
  });

  final int count;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: Brand.s12),
      itemBuilder: (context, _) => ShimmerBox(height: height),
    );
  }
}

/// Chip de identidad del usuario autenticado.
class ProfileChip extends StatelessWidget {
  const ProfileChip({
    super.key,
    required this.name,
    this.subtitle,
    this.onTap,
    this.avatarSize = 44,
  });

  final String name;
  final String? subtitle;
  final VoidCallback? onTap;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? 'T'
        : trimmed.substring(0, 1).toUpperCase();
    return MotionPressable(
      onTap: onTap,
      semanticLabel: 'Perfil de $name',
      child: Container(
        padding: const EdgeInsets.all(Brand.s8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: Brand.buttonRadius,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: avatarSize,
              width: avatarSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.action,
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: Brand.display(18, h: 1, color: colors.onAction),
              ),
            ),
            const SizedBox(width: Brand.s10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Brand.ui(
                      13,
                      weight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.ui(11, color: colors.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Brand.s8),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Punto de paginación de carrusel.
class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: Motion.fast,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 6,
          width: active ? 18 : 6,
          decoration: BoxDecoration(
            color: active ? colors.action : Brand.boneWhite30,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

/// Distancia acotada para parallax.
double parallaxOffset(double scrollOffset, {double max = 60}) =>
    math.min(scrollOffset * 0.35, max);
