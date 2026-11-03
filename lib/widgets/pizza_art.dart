import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/custom_pizza.dart';

/// Dibujo representativo de una pizza personalizada.
class PizzaArt extends StatelessWidget {
  const PizzaArt({super.key, required this.selection, this.size = 96});

  final CustomPizzaSelection? selection;
  final double size;

  @override
  Widget build(BuildContext context) {
    final value = selection;
    if (value == null) {
      return SizedBox(
        width: size,
        height: size,
        child: const Icon(Icons.local_pizza_rounded),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: PizzaArtPainter(selection: value),
      ),
    );
  }
}

class PizzaArtPainter extends CustomPainter {
  const PizzaArtPainter({required this.selection});

  final CustomPizzaSelection selection;

  static const _toppingColors = {
    'pepperoni': Color(0xFF9E3B2E),
    'jamon': Color(0xFFD77A7A),
    'tocino': Color(0xFF8A4B2A),
    'salchicha-italiana': Color(0xFFB55239),
    'carne-res': Color(0xFF7B3E2A),
    'champinones': Color(0xFFB89B7A),
    'aceitunas': Color(0xFF3D2B2B),
    'cebolla': Color(0xFFE8D8D8),
    'pimiento': Color(0xFF4E8A4E),
    'pina': Color(0xFFE8C64A),
    'jalapeno': Color(0xFF5D8A3C),
    'queso-azul': Color(0xFFD8D0B8),
    'parmesano': Color(0xFFE8D8A8),
    'tomate-fresco': Color(0xFFD85A45),
    'oregano': Color(0xFF4B6B3A),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final crust = Paint()..color = const Color(0xFFD6A15E);
    final sauceColor = switch (selection.sauce.id) {
      'bbq' => const Color(0xFF5B0F11),
      'ajo' => const Color(0xFFF0DFC0),
      'picante' => const Color(0xFFB74624),
      'alfredo' => const Color(0xFFF2E2C8),
      _ => const Color(0xFFB74624),
    };
    final sauce = Paint()..color = sauceColor;
    final cheese = Paint()..color = const Color(0xFFF2D58B);

    canvas.drawCircle(center, radius, crust);
    canvas.drawCircle(center, radius * 0.84, sauce);
    canvas.drawCircle(center, radius * 0.72, cheese);

    final bubble = Paint()..color = const Color(0xFFE7C56C);
    for (var i = 0; i < 7; i++) {
      final angle = i * math.pi * 2 / 7 + 0.4;
      final point = center +
          Offset(math.cos(angle), math.sin(angle)) * (radius * 0.42);
      canvas.drawCircle(
        point,
        math.max(2.5, radius * 0.07).toDouble(),
        bubble,
      );
    }

    final toppings = selection.ingredients;
    final dotRadius = math.max(4, radius * 0.11).toDouble();
    for (var i = 0; i < toppings.length; i++) {
      final angle = i * math.pi * 2 / toppings.length + 0.9;
      final distance = radius * (0.25 + (i % 3) * 0.16);
      final point = center +
          Offset(math.cos(angle), math.sin(angle)) * distance;
      final color = _toppingColors[toppings[i].id] ?? const Color(0xFF9E3B2E);
      canvas.drawCircle(point, dotRadius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant PizzaArtPainter oldDelegate) =>
      oldDelegate.selection.signature != selection.signature;
}
