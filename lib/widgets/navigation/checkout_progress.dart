part of '../widgets.dart';

/// Indicador de progreso de los tres pasos del checkout.
///
/// Los pasos ya alcanzados se pueden tocar para volver a ellos; los que están
/// por delante del último paso visitado quedan deshabilitados.
class CheckoutProgress extends StatelessWidget {
  const CheckoutProgress({
    super.key,
    required this.step,
    this.maxStep,
    this.onSelect,
  });

  /// Paso que se está viendo.
  final CheckoutStep step;

  /// Paso más lejano alcanzado. Por defecto, el actual.
  final CheckoutStep? maxStep;

  /// Se dispara al tocar un paso habilitado.
  final ValueChanged<CheckoutStep>? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final limit = maxStep ?? step;
    return Row(
      children: [
        for (final item in CheckoutStep.values) ...[
          if (item.index > 0)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: Brand.s4),
                color: item.index <= step.index ? colors.action : colors.border,
              ),
            ),
          _StepDot(
            step: item,
            current: item == step,
            completed: item.index < step.index,
            enabled:
                onSelect != null && item != step && item.index <= limit.index,
            onSelect: onSelect,
          ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.step,
    required this.current,
    required this.completed,
    required this.enabled,
    required this.onSelect,
  });

  final CheckoutStep step;
  final bool current;
  final bool completed;
  final bool enabled;
  final ValueChanged<CheckoutStep>? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = current || completed;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Brand.s8,
        vertical: Brand.s2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 24,
            width: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? colors.action : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? colors.action
                    : enabled
                    ? colors.textSecondary
                    : colors.border,
              ),
            ),
            child: completed
                ? Icon(Icons.check_rounded, size: 14, color: colors.onAction)
                : Text(
                    '${step.number}',
                    style: Brand.ui(
                      10,
                      weight: FontWeight.w700,
                      color: active ? colors.onAction : colors.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(height: Brand.s4),
          Text(
            step.label,
            style: Brand.ui(
              9,
              weight: current ? FontWeight.w700 : FontWeight.w400,
              color: current ? colors.textPrimary : colors.textSecondary,
            ),
          ),
        ],
      ),
    );

    if (!enabled || onSelect == null) {
      return Semantics(
        label: 'Paso ${step.number}: ${step.label}',
        selected: current,
        child: content,
      );
    }

    return Semantics(
      button: true,
      label: 'Ir al paso ${step.number}: ${step.label}',
      child: InkWell(
        onTap: () => onSelect!(step),
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
}
