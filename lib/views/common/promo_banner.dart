import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/components.dart';
import '../../core/theme/theme_context.dart';
import '../../models/product.dart';
import '../../models/promotion.dart';
import 'drive_image.dart';

/// Banner editorial de promoción reutilizado en inicio y en la carta.
class PromoBanner extends StatelessWidget {
  const PromoBanner({
    super.key,
    required this.promotion,
    this.product,
    this.onTap,
    this.dense = false,
  });

  final Promotion promotion;
  final Product? product;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final item = product;
    final basePrice = item == null ? 0.0 : promotion.basePriceFor(item);
    final promoPrice = promotion.discountedPrice(basePrice);
    final hasDiscount = item != null && promoPrice < basePrice;
    // Promoción abierta a cualquier variante: el precio es el más barato.
    final fromPrice =
        item != null &&
        promotion.appliesToAnyVariant &&
        item.variants.length > 1;
    final priceLabel = fromPrice
        ? 'Desde ${Money.format(promoPrice)}'
        : Money.format(promoPrice);
    final height = dense ? 220.0 : 300.0;

    // Imagen propia de la promoción → foto del producto → bloque de marca.
    final promoImage = promotion.hasImage ? promotion.image : product?.image;
    final fallbackAsset = promotion.hasImage
        ? 'promotions/${promotion.id}'
        : product?.image?.assetName;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DriveImage(
              media: promoImage,
              placeholderLabel: promotion.title,
              fallbackAssetName: fallbackAsset,
            ),
            const BrandOverlay(opacity: 0.68),
            Positioned(
              left: Brand.s16,
              top: Brand.s16,
              child: Row(
                children: [
                  PromoBadge(
                    label: promotion.discountPercent != null
                        ? '-${promotion.discountPercent}%'
                        : 'PRECIO ESPECIAL',
                  ),
                ],
              ),
            ),
            Positioned(
              left: Brand.s16,
              right: Brand.s16,
              bottom: Brand.s16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PROMO DE LA CASA',
                    style: Brand.ui(
                      9,
                      weight: FontWeight.w700,
                      color: colors.action,
                    ),
                  ),
                  const SizedBox(height: Brand.s4),
                  Text(
                    promotion.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Brand.display(
                      dense ? 20 : 26,
                      h: 0.98,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (promotion.subtitle != null) ...[
                    const SizedBox(height: Brand.s4),
                    Text(
                      promotion.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.ui(12, color: colors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: Brand.s12),
                  Row(
                    children: [
                      if (hasDiscount)
                        Padding(
                          padding: const EdgeInsets.only(right: Brand.s8),
                          child: Text(
                            Money.format(basePrice),
                            style: Brand.ui(
                              12,
                              color: colors.textSecondary,
                            ).copyWith(decoration: TextDecoration.lineThrough),
                          ),
                        ),
                      if (product != null)
                        PriceCircle(
                          priceLabel: priceLabel,
                          onTap: onTap,
                        ),
                      const Spacer(),
                      if (onTap != null)
                        PillButton(
                          label: 'APROVECHAR',
                          onPressed: onTap,
                          showArrow: true,
                          height: 44,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
