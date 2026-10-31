part of '../widgets.dart';

/// Acción de quitar una línea del carrito, junto al selector de cantidad.
class RemoveLineButton extends StatelessWidget {
  const RemoveLineButton({
    super.key,
    required this.onTap,
    required this.productName,
    this.size = 32,
  });

  final VoidCallback onTap;
  final String productName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: 'Quitar $productName',
      child: Tooltip(
        message: 'Quitar $productName',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: size,
            width: size,
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/trash.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  colors.onBar,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
