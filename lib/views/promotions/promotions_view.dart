import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/catalog_controller.dart';
import '../../controllers/promotion_controller.dart';
import '../../core/format/money.dart';
import '../../core/load_state.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/components.dart';
import '../../core/theme/theme_context.dart';
import '../../models/product.dart';
import '../../models/promotion.dart';
import '../common/drive_image.dart';
import '../common/offline_banner.dart';

/// Pantalla completa de promociones vigentes.
class PromotionsView extends StatefulWidget {
  const PromotionsView({super.key, required this.onOpenProduct});

  final void Function(Product product, {String? variantLabel}) onOpenProduct;

  @override
  State<PromotionsView> createState() => _PromotionsViewState();
}

class _PromotionsViewState extends State<PromotionsView> {
  static final DateFormat _date = DateFormat('dd/MM/yyyy');
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    final promotions = context.watch<PromotionController>();
    final catalog = context.watch<CatalogController>();

    return Scaffold(
      appBar: TotoTopBar(
        showWordmark: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        actions: [
          IconButton(
            onPressed: promotions.load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _body(context, promotions, catalog)),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    PromotionController promotions,
    CatalogController catalog,
  ) {
    if (promotions.state == LoadState.loading && promotions.isEmpty) {
      return const SingleChildScrollView(
        child: SkeletonList(count: 3, height: 280),
      );
    }

    final active = promotions.active
        .where((promotion) => catalog.byId(promotion.productId)?.isSellable ?? false)
        .toList();
    if (active.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(top: Brand.s24),
        child: EmptyState(
          title: 'Sin promociones por ahora',
          message:
              promotions.error ??
              'Estamos preparando nuevas ofertas. Mientras tanto, '
                  'revisa toda la carta.',
          icon: Icons.local_offer_outlined,
          actionLabel: 'VER LA CARTA',
          onAction: () {
            Navigator.of(context).maybePop();
          },
        ),
      );
    }

    final categories = <String, String>{};
    for (final promotion in active) {
      final product = catalog.byId(promotion.productId);
      if (product == null) continue;
      final category = catalog.menu.categoryById(product.categoryId);
      if (category != null) categories[category.id] = category.name;
    }

    final filtered = _categoryId == null
        ? active
        : active.where((promotion) {
            final product = catalog.byId(promotion.productId);
            return product?.categoryId == _categoryId;
          }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Brand.s16,
        Brand.s24,
        Brand.s16,
        Brand.s24,
      ),
      children: [
        Text(
          '‹ SOLO POR AHORA ›',
          style: Brand.ui(
            11,
            weight: FontWeight.w700,
            color: context.colors.action,
          ),
        ),
        const SizedBox(height: Brand.s4),
        const OutlinedDisplayTitle('PROMOS', size: 40),
        const SizedBox(height: Brand.s8),
        Text(
          'Ofertas vigentes en hora de Lima. El precio promocional se aplica '
          'al agregar el producto a tu pedido.',
          style: context.text.bodySm.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        if (categories.length > 1) ...[
          const SizedBox(height: Brand.s16),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterPill(
                  label: 'Todas',
                  selected: _categoryId == null,
                  onTap: () => setState(() => _categoryId = null),
                ),
                for (final entry in categories.entries) ...[
                  const SizedBox(width: Brand.s8),
                  FilterPill(
                    label: entry.value,
                    selected: _categoryId == entry.key,
                    onTap: () => setState(() => _categoryId = entry.key),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: Brand.s16),
        for (var i = 0; i < filtered.length; i++) ...[
          if (i > 0) const SizedBox(height: Brand.s16),
          MotionReveal(
            delay: Duration(milliseconds: 40 * (i.clamp(0, 6))),
            child: _PromotionCard(
              promotion: filtered[i],
              product: catalog.byId(filtered[i].productId)!,
              date: _date,
              onTap: (variantLabel) => widget.onOpenProduct(
                catalog.byId(filtered[i].productId)!,
                variantLabel: variantLabel,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.promotion,
    required this.product,
    required this.date,
    required this.onTap,
  });

  final Promotion promotion;
  final Product product;
  final DateFormat date;
  final void Function(String? variantLabel) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final variant = promotion.variantFor(product);
    final basePrice = promotion.basePriceFor(product);
    final promoPrice = promotion.priceFor(product);
    final fromPrice =
        promotion.appliesToAnyVariant && product.variants.length > 1;
    final priceLabel =
        '${fromPrice ? 'Desde ' : ''}${Money.format(promoPrice)}';
    final savings = basePrice - promoPrice;
    final validity = promotion.endsAt == null
        ? 'Promoción por tiempo limitado'
        : 'Vigente hasta el ${date.format(promotion.endsAt!)}';

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 210,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DriveImage(
                  media: promotion.image ?? product.image,
                  placeholderLabel: promotion.title,
                  fallbackAssetName:
                      promotion.image?.assetName ?? product.image?.assetName,
                ),
                const BrandOverlay(opacity: 0.62),
                Positioned(
                  left: Brand.s12,
                  top: Brand.s12,
                  child: PromoBadge(
                    label: promotion.discountPercent != null
                        ? '-${promotion.discountPercent}%'
                        : 'PRECIO ESPECIAL',
                  ),
                ),
                Positioned(
                  left: Brand.s16,
                  right: Brand.s16,
                  bottom: Brand.s12,
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
                          24,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Brand.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (promoPrice < basePrice)
                          Text(
                            Money.format(basePrice),
                            style: Brand.ui(
                              12,
                              color: colors.textSecondary,
                            ).copyWith(decoration: TextDecoration.lineThrough),
                          ),
                        Text(
                          priceLabel,
                          style: Brand.ui(
                            24,
                            weight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (savings > 0)
                          Text(
                            'Ahorras ${Money.format(savings)}',
                            style: Brand.ui(
                              11,
                              weight: FontWeight.w700,
                              color: colors.action,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    PriceCircle(
                      priceLabel: priceLabel,
                      onTap: () => onTap(variant?.label),
                    ),
                  ],
                ),
                const SizedBox(height: Brand.s8),
                Text(
                  validity,
                  style: context.text.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: Brand.s12),
                PillButton(
                  label: 'PEDIR AHORA',
                  expanded: true,
                  showArrow: true,
                  onPressed: () => onTap(variant?.label),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
