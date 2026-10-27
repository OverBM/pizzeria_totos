import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/core/motion/motion.dart';
import 'package:pizzeria_totos/core/motion/motion_widgets.dart';
import 'package:pizzeria_totos/core/theme/toto_theme.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: totoTheme(),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  ),
);

void main() {
  group('tokens', () {
    test('duraciones, curvas y distancias son estables', () {
      expect(Motion.fast.inMilliseconds, lessThan(Motion.base.inMilliseconds));
      expect(Motion.base.inMilliseconds, lessThan(Motion.slow.inMilliseconds));
      expect(
        Motion.reveal.inMilliseconds,
        greaterThan(Motion.slow.inMilliseconds),
      );
      expect(Motion.pressScale, lessThan(1));
      expect(Motion.revealOffset, greaterThan(0));
    });

    testWidgets('resolve anula la duración con «reducir movimiento»', (
      tester,
    ) async {
      late BuildContext normal;
      late BuildContext reduced;
      await tester.pumpWidget(
        MaterialApp(
          theme: totoTheme(),
          home: Builder(
            builder: (context) {
              normal = context;
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: Builder(
                  builder: (inner) {
                    reduced = inner;
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(Motion.enabled(normal), isTrue);
      expect(Motion.resolve(normal, Motion.base), Motion.base);
      expect(Motion.enabled(reduced), isFalse);
      expect(Motion.resolve(reduced, Motion.base), Duration.zero);
    });
  });

  group('MotionReveal', () {
    testWidgets('sin reducir movimiento anima desde opacidad 0', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const MotionReveal(child: Text('HOLA'))));
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('HOLA'), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, lessThan(1));

      await tester.pumpAndSettle();
      final settled = tester.widget<Opacity>(
        find.ancestor(of: find.text('HOLA'), matching: find.byType(Opacity)),
      );
      expect(settled.opacity, 1);
    });

    testWidgets('con reducir movimiento el hijo aparece final', (tester) async {
      await tester.pumpWidget(
        _host(const MotionReveal(child: Text('HOLA')), reduceMotion: true),
      );
      expect(find.text('HOLA'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MotionReveal),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(MotionReveal),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
    });
  });

  group('MotionSwitcher', () {
    testWidgets('sin movimiento no monta AnimatedSwitcher', (tester) async {
      await tester.pumpWidget(
        _host(const MotionSwitcher(child: Text('CARTA')), reduceMotion: true),
      );
      expect(find.text('CARTA'), findsOneWidget);
      expect(find.byType(AnimatedSwitcher), findsNothing);
    });

    testWidgets('con movimiento envuelve el contenido', (tester) async {
      await tester.pumpWidget(
        _host(const MotionSwitcher(child: Text('CARTA'))),
      );
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('CARTA'), findsOneWidget);
    });
  });

  group('MotionPressable', () {
    testWidgets('responde al toque con escala breve', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(MotionPressable(onTap: () => taps++, child: const Text('PEDIR'))),
      );
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);

      await tester.tap(find.text('PEDIR'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('con reducir movimiento la escala queda en 1', (tester) async {
      await tester.pumpWidget(
        _host(
          MotionPressable(onTap: () {}, child: const Text('PEDIR')),
          reduceMotion: true,
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('PEDIR')),
      );
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('ShimmerBox', () {
    testWidgets('sin reducir movimiento pinta un degradado', (tester) async {
      await tester.pumpWidget(_host(const ShimmerBox(height: 40)));
      await tester.pump(const Duration(milliseconds: 100));
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.gradient, isNotNull);

      // El brillo se repite: se desmonta para no dejar timers vivos.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('con reducir movimiento es un bloque plano', (tester) async {
      await tester.pumpWidget(
        _host(const ShimmerBox(height: 40), reduceMotion: true),
      );
      await tester.pump();
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.gradient, isNull);
      expect(decoration.color, isNotNull);
    });
  });

  group('MotionPulse', () {
    testWidgets('con reducir movimiento no monta la escala', (tester) async {
      await tester.pumpWidget(
        _host(const MotionPulse(child: Text('ENVIADO')), reduceMotion: true),
      );
      expect(find.text('ENVIADO'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MotionPulse),
          matching: find.byType(ScaleTransition),
        ),
        findsNothing,
      );
    });

    testWidgets('pulsa una sola vez y vuelve a 1', (tester) async {
      await tester.pumpWidget(_host(const MotionPulse(child: Text('ENVIADO'))));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      final scale = tester.widget<ScaleTransition>(
        find
            .descendant(
              of: find.byType(MotionPulse),
              matching: find.byType(ScaleTransition),
            )
            .first,
      );
      expect(scale.scale.value, closeTo(1, 0.001));
    });
  });

  group('MotionRoute', () {
    test('usa la transición breve del sistema', () {
      final route = MotionRoute<void>(builder: (_) => const SizedBox.shrink());
      expect(route.transitionDuration, Motion.base);
      expect(route.reverseTransitionDuration, Motion.fast);
    });
  });
}
