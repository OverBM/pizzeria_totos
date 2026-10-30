part of '../widgets.dart';


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
