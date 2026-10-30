part of '../widgets.dart';


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
