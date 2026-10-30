part of '../widgets.dart';


/// Control de cantidad con animación breve.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
    this.compact = false,
  });

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = compact ? 30.0 : 36.0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            size: size,
            onTap: onDecrement,
            label: 'Quitar uno',
          ),
          AnimatedSwitcher(
            duration: Motion.fast,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: SizedBox(
              width: 28,
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                textAlign: TextAlign.center,
                style: Brand.ui(14, weight: FontWeight.w700),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            size: size,
            onTap: onIncrement,
            label: 'Agregar uno',
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.size,
    this.onTap,
    this.label,
  });

  final IconData icon;
  final double size;
  final VoidCallback? onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: size,
          width: size,
          child: Icon(icon, size: 16, color: context.colors.textPrimary),
        ),
      ),
    );
  }
}
