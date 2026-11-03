import 'package:flutter/material.dart';

import '../format/money.dart';
import 'motion.dart';

/// Entrada escalonada: fade + desplazamiento corto.
class MotionReveal extends StatelessWidget {
  const MotionReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = Motion.revealOffset,
    this.axis = Axis.vertical,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    if (!Motion.enabled(context)) return child;
    return _RevealBody(delay: delay, offset: offset, axis: axis, child: child);
  }
}

class _RevealBody extends StatefulWidget {
  const _RevealBody({
    required this.delay,
    required this.offset,
    required this.axis,
    required this.child,
  });

  final Duration delay;
  final double offset;
  final Axis axis;
  final Widget child;

  @override
  State<_RevealBody> createState() => _RevealBodyState();
}

class _RevealBodyState extends State<_RevealBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.reveal,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.enter,
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dx = widget.axis == Axis.horizontal ? widget.offset : 0.0;
    final dy = widget.axis == Axis.vertical ? widget.offset : 0.0;
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final value = _curve.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(dx * (1 - value), dy * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Importe que se anima cuando cambia de valor.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({
    super.key,
    required this.value,
    this.style,
    this.textAlign,
  });

  final double value;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    if (!Motion.enabled(context)) {
      return Text(
        Money.format(value),
        style: style,
        textAlign: textAlign,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: Motion.resolve(context, Motion.base),
      curve: Motion.enter,
      builder: (context, animated, _) => Text(
        Money.format(animated),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}

/// Respuesta táctil breve (escala) sin cambiar el layout.
class MotionPressable extends StatefulWidget {
  const MotionPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;

  @override
  State<MotionPressable> createState() => _MotionPressableState();
}

class _MotionPressableState extends State<MotionPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = Motion.enabled(context);
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed && enabled ? Motion.pressScale : 1,
          duration: Motion.resolve(context, Motion.fast),
          curve: Motion.standard,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Transición suave entre dos contenidos (cambio de categoría, estados).
class MotionSwitcher extends StatelessWidget {
  const MotionSwitcher({
    super.key,
    required this.child,
    this.duration = Motion.base,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final Duration duration;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (!Motion.enabled(context)) return child;
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      layoutBuilder: (current, previous) =>
          Stack(alignment: alignment, children: [...previous, ?current]),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Pulso único de énfasis (por ejemplo, el estado «Enviado» de un reclamo).
///
/// Se reproduce una sola vez y no anima si el sistema pide reducir movimiento.
class MotionPulse extends StatefulWidget {
  const MotionPulse({
    super.key,
    required this.child,
    this.scale = 1.06,
    this.duration = const Duration(milliseconds: 900),
  });

  final Widget child;
  final double scale;
  final Duration duration;

  @override
  State<MotionPulse> createState() => _MotionPulseState();
}

class _MotionPulseState extends State<MotionPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: widget.scale,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 45,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: widget.scale,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInCubic)),
      weight: 55,
    ),
  ]).animate(_controller);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.enabled(context)) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Motion.enabled(context)) return widget.child;
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// Ruta con transición breve; instantánea si se pide reducir movimiento.
class MotionRoute<T> extends PageRouteBuilder<T> {
  MotionRoute({
    required this.builder,
    super.settings,
    super.fullscreenDialog = false,
  }) : super(
         transitionDuration: Motion.base,
         reverseTransitionDuration: Motion.fast,
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           if (!Motion.enabled(context)) return child;
           final curved = CurvedAnimation(
             parent: animation,
             curve: Motion.enter,
             reverseCurve: Motion.exit,
           );
           return FadeTransition(
             opacity: curved,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: const Offset(0.04, 0),
                 end: Offset.zero,
               ).animate(curved),
               child: child,
             ),
           );
         },
       );

  final WidgetBuilder builder;
}

/// Bloque con brillo suave para estados de carga.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 120,
    this.radius = 12,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.enabled(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surface;
    if (!Motion.enabled(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1 + _controller.value * 2, 0),
            end: Alignment(1 + _controller.value * 2, 0),
            colors: [base, const Color(0xFF8A2A2E), base],
          ),
        ),
      ),
    );
  }
}
