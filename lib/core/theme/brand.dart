import 'package:flutter/material.dart';

/// Tokens de marca de TOTO'S Pizza.
///
/// Fuente de verdad visual: `design.md` en la raíz del repositorio.
/// Cinco colores, radios 15/12/38 y unidad base 4 dp. Sin sombras.
class Brand {
  const Brand._();

  // ── Colores ────────────────────────────────────────────────────────────────
  static const Color signMaroon = Color(0xFF5B0F11); // fondo de pantalla
  static const Color maroonLift = Color(0xFF741B1E); // tarjetas / campos
  static const Color ovenOrange = Color(0xFFB74624); // acción / activo
  static const Color signBlack = Color(0xFF000000); // barras / bordes
  static const Color boneWhite = Color(0xFFFFFFFF); // texto principal
  static const Color boneWhite70 = Color(0xB3FFFFFF); // texto secundario
  static const Color boneWhite50 = Color(0x80FFFFFF); // deshabilitado
  static const Color boneWhite40 = Color(0x66FFFFFF); // puntos inactivos
  static const Color boneWhite30 = Color(0x4DFFFFFF); // borde pill inactivo
  static const Color errorBorder = Color(
    0xFFB74624,
  ); // borde de error (naranja)

  // ── Radios ─────────────────────────────────────────────────────────────────
  static const double rButton = 15;
  static const double rCard = 12;
  static const double rFeature = 38;

  // ── Espaciado (unidad base 4 dp) ────────────────────────────────────────────
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s56 = 56;
  static const double s64 = 64;
  static const double s80 = 80;

  static const double screenMargin = 16;
  static const double minTouch = 44;

  // ── Familias tipográficas (empaquetadas en assets/fonts) ────────────────────
  static const String fontDisplay = 'AlfaSlabOne';
  static const String fontUi = 'Inter';

  /// Estilo display (Alfa Slab One), en blanco por defecto. Titulares en
  /// mayúsculas.
  static TextStyle display(
    double size, {
    double h = 0.92,
    double em = 0.02,
    Color color = boneWhite,
  }) => TextStyle(
    fontFamily: fontDisplay,
    fontSize: size,
    height: h,
    letterSpacing: size * em,
    color: color,
  );

  /// Estilo de UI (Inter).
  static TextStyle ui(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = boneWhite,
    double h = 1.4,
    double em = 0.02,
  }) => TextStyle(
    fontFamily: fontUi,
    fontSize: size,
    fontWeight: weight,
    height: h,
    letterSpacing: size * em,
    color: color,
  );

  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(rButton),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(rCard),
  );
  static const BorderRadius featureRadius = BorderRadius.all(
    Radius.circular(rFeature),
  );
}
