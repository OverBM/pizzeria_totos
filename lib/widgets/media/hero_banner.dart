part of '../widgets.dart';

/// Hero fotográfico a sangre con parallax acotado y entrada editorial.
class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.image,
    required this.title,
    this.subtitle,
    required this.onPrimary,
    required this.onSecondary,
    this.eyebrow = 'BIENVENIDO A TOTO\'S',
    this.titleTail = '(Y PASTAS)',
    this.primaryLabel = 'VER LA CARTA',
    this.secondaryLabel = 'NUESTRAS SEDES',
    this.badge = 'HECHO PARA COMPARTIR',
    this.scrollOffset = 0,
    this.height = 490,
  });

  final Widget image;
  final String eyebrow;
  final String title;
  final String titleTail;

  /// Bajada opcional: cuando falta, el bloque inferior se compacta.
  final String? subtitle;
  final String primaryLabel;
  final String secondaryLabel;
  final String badge;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final double scrollOffset;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SizedBox(height: height, child: image),
          Positioned(
            left: Brand.s16,
            right: Brand.s16,
            top: Brand.s24,
            // A 360 dp con texto escalado los dos sellos no caben: cada uno
            // cede ancho y recorta con puntos suspensivos en vez de desbordar.
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Brand.s10,
                      vertical: Brand.s4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bar,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.action),
                    ),
                    child: Text(
                      eyebrow.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.ui(
                        9,
                        weight: FontWeight.w700,
                        color: colors.onBar,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Brand.s8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Brand.s10,
                      vertical: Brand.s4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bar,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Brand.ui(
                        8,
                        weight: FontWeight.w700,
                        color: colors.onBar,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: Brand.s16,
            right: Brand.s16,
            bottom: Brand.s24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedDisplayTitle(title, size: 45),
                Text(
                  titleTail.toUpperCase(),
                  style: Brand.display(27, h: 1, color: colors.action),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: Brand.s12),
                  Text(
                    subtitle!,
                    style: Brand.ui(13, color: colors.textPrimary, h: 1.4),
                  ),
                ],
                const SizedBox(height: Brand.s16),
                Wrap(
                  spacing: Brand.s8,
                  runSpacing: Brand.s8,
                  children: [
                    PillButton(
                      label: primaryLabel,
                      onPressed: onPrimary,
                      showArrow: true,
                    ),
                    PillButton(
                      label: secondaryLabel,
                      onPressed: onSecondary,
                      filled: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
