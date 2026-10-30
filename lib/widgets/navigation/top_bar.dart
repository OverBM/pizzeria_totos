part of '../widgets.dart';


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
