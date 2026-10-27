import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/data/product_images.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../models/media_ref.dart';
import '../../services/drive_image_service.dart';

/// Imagen de catálogo con la cadena Drive → asset local → placeholder de marca.
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

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    final url = DriveImageService.resolve(media, width: _targetWidth(context));
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
                fadeInDuration: fadeIn
                    ? const Duration(milliseconds: 220)
                    : Duration.zero,
                placeholder: (context, _) =>
                    const ShimmerBox(height: double.infinity, radius: 0),
                errorWidget: (context, _, _) =>
                    _localOrPlaceholder(context, local),
              )
            : _localOrPlaceholder(context, local),
      ),
    );
  }

  Widget _localOrPlaceholder(BuildContext context, String? local) {
    if (local != null) {
      return Image.asset(
        local,
        fit: fit,
        width: width,
        height: height,
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

  int _targetWidth(BuildContext context) {
    final ratio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1;
    final logical = width ?? MediaQuery.maybeOf(context)?.size.width ?? 800;
    return (logical * ratio).round();
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
