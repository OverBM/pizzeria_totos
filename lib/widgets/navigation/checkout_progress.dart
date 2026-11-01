part of '../widgets.dart';

/// Indicador de progreso de los tres pasos del checkout.
class CheckoutProgress extends StatelessWidget {
  const CheckoutProgress({super.key, required this.step});

  final CheckoutStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        for (final item in CheckoutStep.values) ...[
          if (item.index > 0)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: Brand.s8),
                color: item.index <= step.index
                    ? colors.action
                    : colors.border,
              ),
            ),
          _StepDot(
            step: item,
            current: item == step,
            completed: item.index < step.index,
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
  });

  final CheckoutStep step;
  final bool current;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = current || completed;
    return Column(
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
              color: active ? colors.action : colors.border,
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
    );
  }
}
