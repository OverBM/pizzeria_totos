part of '../widgets.dart';


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
