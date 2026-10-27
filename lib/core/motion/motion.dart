import 'package:flutter/material.dart';

/// Sistema de movimiento de TOTO'S.
///
/// Animaciones nativas de Flutter, breves y sobrias. Cuando el sistema pide
/// «reducir movimiento» ([MediaQueryData.disableAnimations]) todo se resuelve
/// sin recorrido: los widgets aparecen en su estado final.
class Motion {
  const Motion._();

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 380);
  static const Duration reveal = Duration(milliseconds: 420);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve standard = Curves.easeInOutCubic;

  static const double pressScale = 0.97;
  static const double revealOffset = 16;

  /// ¿Deben ejecutarse animaciones en este contexto?
  static bool enabled(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) return false;
    return !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
  }

  /// Duración que se anula cuando el usuario pide reducir movimiento.
  static Duration resolve(BuildContext context, Duration duration) =>
      enabled(context) ? duration : Duration.zero;
}
