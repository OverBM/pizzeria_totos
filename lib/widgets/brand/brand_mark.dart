part of '../widgets.dart';

/// Lockup horizontal de la marca: logo oficial pequeño + bajada de marca.
///
/// No se redibuja el wordmark: se usa el asset oficial.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.height = 30,
    this.showTagline = true,
    this.onTap,
  });

  final double height;
  final bool showTagline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandLogo(surface: LogoSurface.transparent, height: height),
        if (showTagline) ...[
          const SizedBox(width: Brand.s8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TOTO'S",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Brand.display(15, h: 1, color: context.colors.onBar),
                ),
                Text(
                  'PIZZERÍA · HUANCAYO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Brand.ui(
                    7,
                    weight: FontWeight.w500,
                    color: context.colors.onBar.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: 'Ir al inicio',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      ),
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
