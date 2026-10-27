import 'package:flutter/material.dart';

/// Superficie donde se coloca el logo, para elegir la versión correcta.
enum LogoSurface {
  /// Fondo vino `signMaroon`: usa el letrero v1 (fondo vino horneado).
  maroon,

  /// Fondo negro o tarjeta: usa la insignia circular transparente.
  transparent,
}

/// Logo oficial de TOTO'S. Nunca se recolorea, estira ni reescribe.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.surface, this.height = 120});

  final LogoSurface surface;
  final double height;

  static const String _letrero = 'assets/images/Totos_logo_v1.webp';
  static const String _badge = 'assets/images/totos_pizza_logo.png';

  @override
  Widget build(BuildContext context) {
    final asset = surface == LogoSurface.maroon ? _letrero : _badge;
    return Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: "TOTO'S Pizza",
    );
  }
}
