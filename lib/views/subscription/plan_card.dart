import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/format/money.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../models/delivery_plan.dart';
import '../../models/media_ref.dart';
import '../../services/drive_image_service.dart';
import '../../widgets/widgets.dart';

/// Imagen de plan: Drive si existe; SVG de marca como respaldo.
class PlanImage extends StatelessWidget {
  const PlanImage({
    super.key,
    required this.media,
    required this.iconSvg,
    required this.label,
    this.size = 64,
    this.radius = 14,
    this.requestWidth = 180,
  });

  final MediaRef? media;
  final String iconSvg;
  final String label;
  final double size;
  final double radius;
  final int requestWidth;

  @override
  Widget build(BuildContext context) {
    final url = DriveImageService.resolve(media, width: requestWidth);
    final fallback = _fallback(context);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: size,
          height: size,
          child: url == null
              ? fallback
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  memCacheWidth: requestWidth,
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.surface,
      padding: EdgeInsets.all(size * 0.22),
      child: SvgPicture.asset(
        'assets/icons/plans/$iconSvg.svg',
        colorFilter: ColorFilter.mode(colors.action, BlendMode.srcIn),
        semanticsLabel: label,
      ),
    );
  }
}

/// Tarjeta de un plan pago.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    required this.onChoose,
    this.current = false,
  });

  final DeliveryPlan plan;
  final VoidCallback onTap;
  final VoidCallback onChoose;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final highlighted = plan.savingsSoles != null;
    return MotionPressable(
      onTap: onTap,
      semanticLabel: '${plan.name}, ${plan.priceLabel}, ${plan.durationLabel}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(Brand.s12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: Brand.cardRadius,
          border: Border.all(
            color: highlighted ? colors.action : colors.border,
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlanImage(
                  media: plan.image,
                  iconSvg: plan.iconSvg,
                  label: plan.name,
                  size: 64,
                ),
                const SizedBox(width: Brand.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan.name.toUpperCase(),
                              style: Brand.display(
                                20,
                                h: 1,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          if (plan.label.isNotEmpty)
                            _Badge(
                              label: plan.label,
                              highlighted: highlighted,
                            ),
                        ],
                      ),
                      const SizedBox(height: Brand.s4),
                      Text(
                        plan.description,
                        style: context.text.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: Brand.s8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            plan.priceLabel,
                            style: Brand.ui(18, weight: FontWeight.w700),
                          ),
                          const SizedBox(width: Brand.s4),
                          Text(
                            '· ${plan.durationLabel}',
                            style: context.text.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Brand.s12),
            _Benefit(
              icon: 'delivery_free',
              text: 'Envío gratis desde '
                  '${Money.format(plan.minimumOrderSoles)}',
            ),
            if (plan.savingsSoles != null) ...[
              const SizedBox(height: Brand.s4),
              _Benefit(
                icon: 'savings',
                text: plan.savingsLabel,
                accent: true,
              ),
            ],
            for (final benefit in plan.benefits.take(2)) ...[
              const SizedBox(height: Brand.s4),
              _Benefit(icon: 'check', text: benefit),
            ],
            const SizedBox(height: Brand.s12),
            PillButton(
              label: current ? 'TU PLAN ACTUAL' : 'ELEGIR ${plan.name}',
              expanded: true,
              showArrow: false,
              onPressed: current ? null : onChoose,
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.text,
    this.accent = false,
  });

  final String icon;
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/icons/plans/$icon.svg',
          width: 18,
          height: 18,
          colorFilter: ColorFilter.mode(
            accent ? colors.action : colors.textSecondary,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: Brand.s8),
        Expanded(
          child: Text(
            text,
            style: context.text.caption.copyWith(
              color: accent ? colors.action : colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.highlighted});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? colors.action : colors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Brand.ui(
          8,
          weight: FontWeight.w700,
          color: highlighted ? colors.onAction : colors.textSecondary,
        ),
      ),
    );
  }
}

/// Ficha detallada de un plan.
class PlanDetailSheet extends StatelessWidget {
  const PlanDetailSheet({
    super.key,
    required this.plan,
    required this.onChoose,
  });

  final DeliveryPlan plan;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Brand.s16,
          Brand.s16,
          Brand.s16,
          Brand.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: PlanImage(
                media: plan.image,
                iconSvg: plan.iconSvg,
                label: plan.name,
                size: 180,
                radius: 22,
                requestWidth: 500,
              ),
            ),
            const SizedBox(height: Brand.s16),
            Text(
              plan.name.toUpperCase(),
              style: Brand.display(28, h: 1, color: colors.textPrimary),
            ),
            const SizedBox(height: Brand.s4),
            Text(
              '${plan.priceLabel} · ${plan.durationLabel}',
              style: Brand.ui(16, weight: FontWeight.w700),
            ),
            if (plan.longDescription.isNotEmpty) ...[
              const SizedBox(height: Brand.s12),
              Text(
                plan.longDescription,
                style: context.text.bodySm.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: Brand.s20),
            const SectionHeading(
              eyebrow: 'Incluye',
              title: 'Qué llevas con tu plan',
            ),
            const SizedBox(height: Brand.s8),
            for (final benefit in plan.benefits) ...[
              _Benefit(icon: 'check', text: benefit),
              const SizedBox(height: Brand.s4),
            ],
            const SizedBox(height: Brand.s12),
            _Benefit(
              icon: 'coverage',
              text: 'Solo delivery dentro de cobertura; no incluye recojo.',
            ),
            const SizedBox(height: Brand.s4),
            _Benefit(
              icon: 'cancel',
              text: 'Cancela cuando quieras; el beneficio dura hasta vencer.',
            ),
            const SizedBox(height: Brand.s4),
            _Benefit(
              icon: 'calendar',
              text: 'Sin renovación automática en beta.',
            ),
            const SizedBox(height: Brand.s20),
            Text(
              'Compra mínima ${Money.format(plan.minimumOrderSoles)} en '
              'productos después de promociones. El cupón no quita el envío '
              'gratis.',
              style: context.text.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: Brand.s20),
            PillButton(
              label: 'ELEGIR ${plan.name}',
              expanded: true,
              showArrow: true,
              onPressed: onChoose,
            ),
            const SizedBox(height: Brand.s12),
            Text(
              'Activación simulada: no se cobra nada en la app.',
              textAlign: TextAlign.center,
              style: context.text.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
