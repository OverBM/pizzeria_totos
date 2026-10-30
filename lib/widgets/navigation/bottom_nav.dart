part of '../widgets.dart';


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
