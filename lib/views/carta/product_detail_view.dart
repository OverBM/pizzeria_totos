import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/cart_controller.dart';
import '../../controllers/catalog_controller.dart';
import '../../controllers/promotion_controller.dart';
import '../../core/format/money.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/components.dart';
import '../../core/theme/theme_context.dart';
import '../../models/product.dart';
import '../../models/variant.dart';
import '../common/drive_image.dart';
import '../common/offline_banner.dart';

/// Detalle de producto con imagen a sangre, ficha y selector de variantes.
class ProductDetailView extends StatefulWidget {
  const ProductDetailView({
    super.key,
    required this.product,
    this.initialVariantLabel,
  });

  final Product product;

  /// Variante preseleccionada (por ejemplo, al abrir una promoción).
  final String? initialVariantLabel;

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int _variantIndex = 0;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    final label = widget.initialVariantLabel;
    if (label == null) return;
    final index = widget.product.variants.indexWhere((v) => v.label == label);
    if (index >= 0) _variantIndex = index;
  }

  Product get _product {
    final latest = context.read<CatalogController>().byId(widget.product.id);
    return latest ?? widget.product;
  }

  Variant? get _variant {
    final variants = _product.variants;
    if (variants.isEmpty) return null;
    return variants[_variantIndex.clamp(0, variants.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final promotions = context.watch<PromotionController>();
    final colors = context.colors;
    final variant = _variant;
    final promotion = variant == null
        ? null
        : promotions.forVariant(product.id, variant.label);
    final unitPrice = variant == null
        ? 0.0
        : promotion?.discountedPrice(variant.priceSoles) ?? variant.priceSoles;
    final category = context.read<CatalogController>().menu.categoryById(
      product.categoryId,
    );

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 345,
                  pinned: true,
                  backgroundColor: colors.bar,
                  leading: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Volver',
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => _share(product),
                      icon: const Icon(Icons.share_outlined),
                      tooltip: 'Compartir',
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'product-${product.id}',
                          child: DriveImage(
                            media: product.image,
                            placeholderLabel: product.name,
                            fallbackAssetName: product.image?.assetName,
                          ),
                        ),
                        const BrandOverlay(opacity: 0.35),
                        if (promotion != null)
                          Positioned(
                            left: Brand.s16,
                            bottom: Brand.s16,
                            child: PromoBadge(
                              label: promotion.discountPercent != null
                                  ? '-${promotion.discountPercent}%'
                                  : 'PRECIO ESPECIAL',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(Brand.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (category?.name ?? 'CARTA').toUpperCase(),
                          style: Brand.ui(
                            10,
                            weight: FontWeight.w700,
                            color: colors.action,
                          ),
                        ),
                        const SizedBox(height: Brand.s4),
                        Text(
                          product.name.toUpperCase(),
                          style: Brand.display(
                            32,
                            h: 1,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: Brand.s8),
                        Text(
                          product.description,
                          style: context.text.bodySm.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        if (product.tags.isNotEmpty) ...[
                          const SizedBox(height: Brand.s12),
                          Wrap(
                            spacing: Brand.s8,
                            runSpacing: Brand.s8,
                            children: product.tags
                                .map(
                                  (tag) => StatusPill(
                                    label: tag,
                                    filled: false,
                                    color: colors.action,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (!product.isSellable) ...[
                          const SizedBox(height: Brand.s12),
                          StatusPill(
                            label: 'No disponible',
                            filled: false,
                            color: colors.action,
                          ),
                        ],
                        if (product.hasDetail) ...[
                          const SizedBox(height: Brand.s24),
                          const SectionHeading(
                            eyebrow: 'La ficha',
                            title: 'Qué lleva',
                          ),
                          const SizedBox(height: Brand.s12),
                          if (product.ingredients.isNotEmpty)
                            _InfoBlock(
                              label: 'INGREDIENTES',
                              value: product.ingredients.join(' · '),
                            ),
                          if (product.allergens.isNotEmpty) ...[
                            const SizedBox(height: Brand.s12),
                            _InfoBlock(
                              label: 'ALÉRGENOS',
                              value: product.allergens.join(' · '),
                            ),
                          ],
                          if (product.portion != null ||
                              product.calories != null) ...[
                            const SizedBox(height: Brand.s12),
                            Row(
                              children: [
                                if (product.portion != null)
                                  Expanded(
                                    child: _InfoBlock(
                                      label: 'PORCIÓN',
                                      value: product.portion!,
                                    ),
                                  ),
                                if (product.calories != null)
                                  Expanded(
                                    child: _InfoBlock(
                                      label: 'CALORÍAS',
                                      value: '${product.calories} kcal',
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                        if (product.images.length > 1) ...[
                          const SizedBox(height: Brand.s24),
                          const SectionHeading(
                            eyebrow: 'Galería',
                            title: 'Más de cerca',
                          ),
                          const SizedBox(height: Brand.s12),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: product.images.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: Brand.s8),
                              itemBuilder: (context, index) => SizedBox(
                                height: 120,
                                width: 140,
                                child: DriveImage(
                                  media: product.images[index],
                                  borderRadius: Brand.cardRadius,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (product.variants.length > 1) ...[
                          const SizedBox(height: Brand.s24),
                          const SectionHeading(
                            eyebrow: 'Elige tu tamaño',
                            title: 'La variante',
                          ),
                          const SizedBox(height: Brand.s12),
                          Wrap(
                            spacing: Brand.s8,
                            runSpacing: Brand.s8,
                            children: [
                              for (var i = 0; i < product.variants.length; i++)
                                FilterPill(
                                  label: product.variants[i].displayLabel,
                                  selected: i == _variantIndex,
                                  onTap: () =>
                                      setState(() => _variantIndex = i),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: Brand.s24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(
        context,
        product,
        unitPrice,
        promotion != null,
      ),
    );
  }

  Widget _bottomBar(
    BuildContext context,
    Product product,
    double unitPrice,
    bool hasPromo,
  ) {
    final colors = context.colors;
    final variant = _variant;
    final sellable = product.isSellable && variant != null;
    final total = sellable ? Money.multiply(unitPrice, _quantity) : 0.0;
    return Container(
      decoration: BoxDecoration(
        color: colors.bar,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Brand.s16,
            Brand.s12,
            Brand.s16,
            Brand.s12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasPromo && sellable)
                      Text(
                        Money.format(variant.priceSoles),
                        style: Brand.ui(
                          11,
                          color: colors.textSecondary,
                        ).copyWith(decoration: TextDecoration.lineThrough),
                      ),
                    Text(
                      sellable ? Money.format(total) : 'No disponible',
                      style: Brand.ui(
                        18,
                        weight: FontWeight.w700,
                        color: colors.onBar,
                      ),
                    ),
                  ],
                ),
              ),
              if (sellable) ...[
                const SizedBox(width: Brand.s12),
                QuantityStepper(
                  quantity: _quantity,
                  compact: true,
                  onIncrement: () => setState(() => _quantity++),
                  onDecrement: () {
                    if (_quantity > 1) setState(() => _quantity--);
                  },
                ),
              ],
              const SizedBox(width: Brand.s12),
              PillButton(
                label: 'AGREGAR',
                onPressed: sellable ? () => _add(context, product) : null,
                showArrow: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _add(BuildContext context, Product product) {
    final variant = _variant;
    if (variant == null) return;
    context.read<CartController>().add(product, variant, quantity: _quantity);
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$_quantity × ${product.name} agregado al pedido'),
          duration: const Duration(seconds: 2),
        ),
      );
    Navigator.of(context).maybePop();
  }

  void _share(Product product) {
    final price = product.isSellable
        ? ' — ${Money.format(product.minPriceSoles)}'
        : '';
    final text = '${product.name} en TOTO\'S Pizza$price';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto copiado para compartir')),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Brand.s12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Brand.ui(9, weight: FontWeight.w700, color: colors.action),
          ),
          const SizedBox(height: Brand.s4),
          Text(value, style: Brand.ui(12, color: colors.textSecondary, h: 1.4)),
        ],
      ),
    );
  }
}
