part of '../widgets.dart';

/// Imagen de catálogo con la cadena Drive → asset local → placeholder de marca.
///
/// Pide y decodifica la imagen al tamaño en que se pinta, no al de la pantalla.
/// Las miniaturas reservan el recorte de `BoxFit.cover` con
/// `max(ancho, 2 × alto)`; las fotos a sangre pasan [requestWidth] para
/// conservar el ancho de pantalla.
class DriveImage extends StatelessWidget {
  const DriveImage({
    super.key,
    required this.media,
    this.assetName,
    this.fallbackAssetName,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderLabel,
    this.borderRadius,
    this.fadeIn = true,
    this.requestWidth,
  });

  /// Referencia remota (Drive o URL directa).
  final MediaRef? media;

  /// Nombre de asset local de respaldo (`assets/images/products/<name>.<ext>`).
  final String? assetName;

  /// Asset alternativo cuando el principal no existe.
  final String? fallbackAssetName;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? placeholderLabel;
  final BorderRadius? borderRadius;
  final bool fadeIn;

  /// Ancho lógico fijo para fotos a sangre (hero y detalle).
  ///
  /// Si es `null`, la imagen se pide con el presupuesto de recorte de una
  /// miniatura.
  final double? requestWidth;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetPx = _targetPixels(context, constraints);
        final url = DriveImageService.resolve(media, width: targetPx);
        final local = _localAsset();
        return ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            width: width,
            height: height,
            child: url != null
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: fit,
                    width: width,
                    height: height,
                    memCacheWidth: targetPx,
                    maxWidthDiskCache: targetPx,
                    filterQuality: FilterQuality.medium,
                    fadeInDuration: fadeIn
                        ? const Duration(milliseconds: 120)
                        : Duration.zero,
                    placeholder: (context, _) =>
                        const ShimmerBox(height: double.infinity, radius: 0),
                    errorWidget: (context, _, _) =>
                        _localOrPlaceholder(context, local, targetPx),
                  )
                : _localOrPlaceholder(context, local, targetPx),
          ),
        );
      },
    );
  }

  Widget _localOrPlaceholder(
    BuildContext context,
    String? local,
    int targetPx,
  ) {
    if (local != null) {
      return Image.asset(
        local,
        fit: fit,
        width: width,
        height: height,
        cacheWidth: targetPx,
        errorBuilder: (context, _, _) => _placeholder(context),
      );
    }
    return _placeholder(context);
  }

  String? _localAsset() {
    for (final candidate in [assetName, media?.assetName, fallbackAssetName]) {
      if (candidate == null || candidate.isEmpty) continue;
      if (candidate.startsWith('assets/')) return candidate;
      final path = ProductImages.pathFor(candidate);
      if (path != null) return path;
    }
    return null;
  }

  /// Píxeles físicos que se piden a Drive.
  ///
  /// - Con [requestWidth] (fotos a sangre): ancho de pantalla exacto.
  /// - Sin él (miniaturas): `max(ancho, 2 × alto)`, redondeado a 64 px para
  ///   que el mismo tamaño no cambie de URL entre layouts.
  int _targetPixels(BuildContext context, BoxConstraints constraints) {
    final ratio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final requested = requestWidth;
    if (requested != null) {
      return (requested * ratio).round().clamp(120, 2000).toInt();
    }
    final logicalWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : (width ?? 800);
    final logicalHeight = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : (height ?? logicalWidth);
    final needed = math.max(logicalWidth, logicalHeight * 2);
    final pixels = (needed * ratio) / 64;
    return (pixels.ceil() * 64).clamp(320, 1200).toInt();
  }

  Widget _placeholder(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: width,
      height: height,
      color: Brand.maroonLift,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(Brand.s12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          (placeholderLabel ?? "TOTO'S").toUpperCase(),
          textAlign: TextAlign.center,
          style: Brand.display(24, h: 0.95, color: colors.textPrimary),
        ),
      ),
    );
  }
}

/// Ilustración editorial de Reclamos.
class ClaimsIllustration extends StatelessWidget {
  const ClaimsIllustration({super.key, this.height = 160, this.width = 220});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ilustración de atención al cliente',
      child: SvgPicture.asset(
        'assets/illustrations/claims.svg',
        height: height,
        width: width,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => SizedBox(
          height: height,
          width: width,
          child: Center(
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: height * 0.35,
              color: context.colors.action,
            ),
          ),
        ),
      ),
    );
  }
}

/// Icono SVG del quinto destino (teñido con el color activo).
class ClaimsTabIcon extends StatelessWidget {
  const ClaimsTabIcon({super.key, required this.color, this.size = 21});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/claims.svg',
      height: size,
      width: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      placeholderBuilder: (context) =>
          Icon(Icons.chat_bubble_outline_rounded, size: size, color: color),
    );
  }
}
