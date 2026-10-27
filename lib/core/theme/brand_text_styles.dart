import 'package:flutter/material.dart';

import 'brand.dart';
import 'toto_colors.dart';

/// Escala tipográfica móvil de TOTO'S (ver `design.md`).
///
/// Resuelve los colores por rol semántico del esquema activo; en oscuro el
/// texto es blanco y en claro, vino. Alfa Slab One solo en `headingSm` (24 dp)
/// hacia arriba; Inter por debajo.
class BrandTextStyles {
  const BrandTextStyles(this.colors);

  final TotoColors colors;

  /// Inter 400 10 dp — metadatos mínimos.
  TextStyle get caption => Brand.ui(10, color: colors.textPrimary);

  /// Inter 400 14 dp — descripciones, texto de pills.
  TextStyle get bodySm => Brand.ui(14, color: colors.textPrimary);

  /// Inter 400 16 dp — texto de lectura.
  TextStyle get body => Brand.ui(16, color: colors.textPrimary);

  /// Inter 700 22 dp — nombre de producto, precio.
  TextStyle get subheading =>
      Brand.ui(22, weight: FontWeight.w700, h: 1.15, color: colors.textPrimary);

  /// Inter 700 22 dp — precio en formato `S/ 28`.
  TextStyle get price =>
      Brand.ui(22, weight: FontWeight.w700, color: colors.textPrimary);

  /// Alfa Slab One 24 dp — títulos de pantalla.
  TextStyle get headingSm =>
      Brand.display(24, h: 1.1, color: colors.textPrimary);

  /// Alfa Slab One 32 dp — títulos de sección.
  TextStyle get heading => Brand.display(32, h: 1.0, color: colors.textPrimary);

  /// Alfa Slab One 44 dp — apertura de sección.
  TextStyle get headingLg =>
      Brand.display(44, h: 0.95, color: colors.textPrimary);

  /// Alfa Slab One 64 dp — hero.
  TextStyle get display => Brand.display(64, color: colors.textPrimary);

  /// Inter 500 12 dp — etiquetas de navegación.
  TextStyle get navLabel =>
      Brand.ui(12, weight: FontWeight.w500, color: colors.textPrimary);

  /// Inter 500 14 dp — texto de botones y pills (mayúsculas).
  TextStyle get label =>
      Brand.ui(14, weight: FontWeight.w500, color: colors.textPrimary);
}
