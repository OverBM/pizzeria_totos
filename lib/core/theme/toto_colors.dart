import 'package:flutter/material.dart';

import 'brand.dart';

/// Colores de TOTO'S por **rol semántico** en el único esquema de la app: oscuro.
///
/// Los widgets leen estos roles (nunca los hex de marca directamente). `Brand`
/// sigue siendo la fuente de verdad de los cinco colores.
@immutable
class TotoColors extends ThemeExtension<TotoColors> {
  const TotoColors({
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.border,
    required this.action,
    required this.onAction,
    required this.bar,
    required this.onBar,
    required this.promo,
    required this.overlay,
  });

  /// Fondo de pantalla.
  final Color canvas;

  /// Superficie de tarjetas y campos.
  final Color surface;

  /// Superficie alternativa (chips, bloques suaves).
  final Color surfaceAlt;

  /// Texto principal.
  final Color textPrimary;

  /// Texto secundario.
  final Color textSecondary;

  /// Texto/íconos deshabilitados o tenues.
  final Color textDisabled;

  /// Bordes de 1 px.
  final Color border;

  /// Relleno de acción (botón primario, pills activos, contornos display).
  final Color action;

  /// Texto/íconos sobre `action`.
  final Color onAction;

  /// Barras superior e inferior.
  final Color bar;

  /// Texto/íconos sobre `bar`.
  final Color onBar;

  /// Color de la insignia «PROMO».
  final Color promo;

  /// Velo sobre fotografías (hero y banners).
  final Color overlay;

  /// Único esquema de la app (oscuro).
  static const TotoColors dark = TotoColors(
    canvas: Brand.signMaroon,
    surface: Brand.maroonLift,
    surfaceAlt: Brand.maroonLift,
    textPrimary: Brand.boneWhite,
    textSecondary: Brand.boneWhite70,
    textDisabled: Brand.boneWhite40,
    border: Brand.signBlack,
    action: Brand.ovenOrange,
    onAction: Brand.boneWhite,
    bar: Brand.signBlack,
    onBar: Brand.boneWhite,
    promo: Brand.ovenOrange,
    overlay: Color(0x995B0F11),
  );

  /// Alias histórico del esquema de la marca.
  static const TotoColors standard = dark;

  @override
  TotoColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? border,
    Color? action,
    Color? onAction,
    Color? bar,
    Color? onBar,
    Color? promo,
    Color? overlay,
  }) {
    return TotoColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      action: action ?? this.action,
      onAction: onAction ?? this.onAction,
      bar: bar ?? this.bar,
      onBar: onBar ?? this.onBar,
      promo: promo ?? this.promo,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  TotoColors lerp(covariant TotoColors? other, double t) {
    if (other == null) return this;
    return TotoColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      action: Color.lerp(action, other.action, t)!,
      onAction: Color.lerp(onAction, other.onAction, t)!,
      bar: Color.lerp(bar, other.bar, t)!,
      onBar: Color.lerp(onBar, other.onBar, t)!,
      promo: Color.lerp(promo, other.promo, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
    );
  }
}
