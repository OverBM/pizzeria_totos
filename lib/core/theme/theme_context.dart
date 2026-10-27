import 'package:flutter/material.dart';

import 'brand_text_styles.dart';
import 'toto_colors.dart';

/// Acceso directo a los roles de color y a la escala tipográfica del tema.
extension TotoThemeContext on BuildContext {
  /// Roles semánticos del único esquema (oscuro).
  TotoColors get colors =>
      Theme.of(this).extension<TotoColors>() ?? TotoColors.dark;

  /// Escala tipográfica ya coloreada por el esquema.
  BrandTextStyles get text => BrandTextStyles(colors);

  /// El esquema de la app es siempre oscuro.
  bool get isDark => true;
}
