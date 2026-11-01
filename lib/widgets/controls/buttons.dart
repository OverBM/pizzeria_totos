part of '../widgets.dart';


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

/// Botón circular de acción sobre la tarjeta.
class RoundActionButton extends StatelessWidget {
  const RoundActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.size = 40,
    this.iconScale = 0.55,
  });

  final Widget icon;
  final VoidCallback? onTap;
  final String? label;
  final double size;
  final double iconScale;

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
          child: Center(
            child: SizedBox(
              width: size * iconScale,
              height: size * iconScale,
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

/// Carrito de línea para la acción de agregar.
/// Icono de edición para acciones de línea.
class EditIcon extends StatelessWidget {
  const EditIcon({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.action;
    return SvgPicture.asset(
      'assets/icons/edit.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      placeholderBuilder: (context) => Icon(
        Icons.edit_outlined,
        size: size ?? 14,
        color: color,
      ),
    );
  }
}

/// Icono de «Mis pedidos» para la barra superior.
class OrdersIcon extends StatelessWidget {
  const OrdersIcon({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textPrimary;
    return SvgPicture.asset(
      'assets/icons/orders.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      placeholderBuilder: (context) => Icon(
        Icons.receipt_long_outlined,
        size: size ?? 22,
        color: color,
      ),
    );
  }
}

class AddToCartIcon extends StatelessWidget {
  const AddToCartIcon({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.onAction;
    return SvgPicture.asset(
      'assets/icons/add_to_cart.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      placeholderBuilder: (context) => Icon(
        Icons.add_shopping_cart_rounded,
        size: size ?? 20,
        color: color,
      ),
    );
  }
}
