import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../controllers/catalog_controller.dart';
import '../../controllers/promotion_controller.dart';
import '../../core/format/money.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/theme/brand.dart';
import '../../widgets/widgets.dart';
import '../../core/theme/product_family.dart';
import '../../core/theme/theme_context.dart';
import '../../models/cart_item.dart';
import '../../models/masa.dart';
import '../../models/product.dart';
import '../../models/product_option.dart';
import '../../models/nutrition.dart';
import '../../models/variant.dart';
import 'combo_configurator_sheet.dart';

/// Detalle de producto con imagen a sangre, ficha y selector de variantes.
class ProductDetailView extends StatefulWidget {
  const ProductDetailView({
    super.key,
    required this.product,
    this.initialVariantLabel,
    this.initialItem,
  });

  final Product product;

  /// Variante preseleccionada (por ejemplo, al abrir una promoción).
  final String? initialVariantLabel;

  /// Línea del carrito que se está editando, si aplica.
  final CartItem? initialItem;

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int _variantIndex = 0;
  int _quantity = 1;
  MasaType? _masa;
  final Set<ProductExtra> _selectedExtras = {};

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    final label = widget.initialVariantLabel ?? item?.variantLabel;
    if (label != null) {
      final index = widget.product.variants.indexWhere(
        (v) => v.label.toLowerCase() == label.toLowerCase(),
      );
      if (index >= 0) _variantIndex = index;
    }
    _masa = item?.masa ??
        (widget.product.masas.isEmpty ? null : widget.product.masas.first);
    if (item != null) {
      _selectedExtras.addAll(item.extras);
      _quantity = item.quantity;
    }
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

  MasaType? _masaFor(Product product) {
    final selected = _masa;
    if (selected != null && product.masas.contains(selected)) return selected;
    return product.masas.isEmpty ? null : product.masas.first;
  }

  double get _extrasTotal =>
      Money.sum(_selectedExtras.map((extra) => extra.precioSoles));

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final promotions = context.watch<PromotionController>();
    final colors = context.colors;
    final variant = _variant;
    final priced = variant == null
        ? null
        : promotions.priceFor(product, variant);
    final promotion = priced?.promotion;
    final masa = _masaFor(product);
    final extrasTotal = _extrasTotal;
    final unitPrice = Money.round((priced?.finalSoles ?? 0) + extrasTotal);
    final originalUnitPrice = Money.round(
      (priced?.baseSoles ?? variant?.priceSoles ?? 0) + extrasTotal,
    );
    final discountPercent = promotion?.effectiveDiscountPercent(
          variant?.priceSoles ?? 0,
        ) ??
        0;
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
                            requestWidth: MediaQuery.sizeOf(context).width,
                          ),
                        ),
                        const BrandOverlay(opacity: 0.35),
                        if (promotion != null)
                          Positioned(
                            left: Brand.s16,
                            bottom: Brand.s16,
                            child: PromoBadge(
                              label: discountPercent > 0
                                  ? '-$discountPercent%'
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
                        Row(
                          children: [
                            ProductFamilyIcon(
                              categoryId: product.categoryId,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                (category?.name ?? 'CARTA').toUpperCase(),
                                style: Brand.ui(
                                  10,
                                  weight: FontWeight.w700,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ],
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
                        if (product.componentes.isNotEmpty) ...[
                          const SizedBox(height: Brand.s24),
                          const SectionHeading(
                            eyebrow: 'Incluye',
                            title: 'El combo',
                          ),
                          const SizedBox(height: Brand.s12),
                          for (final component in product.componentes)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: Brand.s8,
                              ),
                              child: _InfoBlock(
                                label:
                                    '${component.cantidad}× ${component.nombre}',
                                value: component.opciones.isEmpty
                                    ? 'Incluido'
                                    : component.opciones.join(' · '),
                                iconAsset:
                                    'assets/icons/ficha_ingredientes.svg',
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
                        if (product.masas.isNotEmpty) ...[
                          const SizedBox(height: Brand.s24),
                          const SectionHeading(
                            eyebrow: 'Elige tu masa',
                            title: 'La masa',
                          ),
                          const SizedBox(height: Brand.s12),
                          if (product.masas.length == 1)
                            _InfoBlock(
                              label: 'MASA',
                              value:
                                  '${masa!.label} · ${masa.description}',
                              iconAsset: 'assets/icons/ficha_ingredientes.svg',
                            )
                          else
                            Wrap(
                              spacing: Brand.s8,
                              runSpacing: Brand.s8,
                              children: [
                                for (final option in product.masas)
                                  FilterPill(
                                    label: option.label,
                                    selected: masa == option,
                                    onTap: () =>
                                        setState(() => _masa = option),
                                  ),
                              ],
                            ),
                          if (product.masas.length > 1 && masa != null) ...[
                            const SizedBox(height: Brand.s8),
                            Text(
                              masa.description,
                              style: context.text.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                        if (product.extras.isNotEmpty) ...[
                          const SizedBox(height: Brand.s24),
                          const SectionHeading(
                            eyebrow: 'Agrega extras',
                            title: 'Extras',
                          ),
                          const SizedBox(height: Brand.s12),
                          for (final extra in product.extras)
                            _ExtraRow(
                              extra: extra,
                              selected: _selectedExtras.contains(extra),
                              onChanged: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedExtras.add(extra);
                                  } else {
                                    _selectedExtras.remove(extra);
                                  }
                                });
                              },
                            ),
                        ],
                        const SizedBox(height: Brand.s24),
                          const SectionHeading(
                            eyebrow: 'La ficha',
                            title: 'Qué lleva',
                          ),
                          const SizedBox(height: Brand.s12),
                          if (product.ingredients.isNotEmpty)
                            _ExpandableSection(
                              title: 'INGREDIENTES',
                              iconAsset: 'assets/icons/ficha_ingredientes.svg',
                              child: _IngredientList(
                                ingredients: product.ingredients,
                              ),
                            ),
                          const SizedBox(height: Brand.s12),
                          Row(
                            children: [
                              Expanded(
                                child: _InfoBlock(
                                  label: 'PORCIÓN',
                                  value: product.portion ?? 'No declarado',
                                  iconAsset: 'assets/icons/ficha_porcion.svg',
                                ),
                              ),
                              Expanded(
                                child: _InfoBlock(
                                  label: 'CALORÍAS',
                                  value: product.calories != null
                                      ? '${product.calories} kcal'
                                      : 'No declarado',
                                  iconAsset: 'assets/icons/nutrition_flame.svg',
                                ),
                              ),
                            ],
                          ),
                          if (product.allergens.isNotEmpty) ...[
                            const SizedBox(height: Brand.s12),
                            _ExpandableSection(
                              title: 'ALÉRGENOS',
                              iconAsset: 'assets/icons/ficha_alergenos.svg',
                              child: Wrap(
                                spacing: Brand.s8,
                                runSpacing: Brand.s8,
                                children: [
                                  for (final allergen in product.allergens)
                                    StatusPill(
                                      label: allergen,
                                      filled: false,
                                      color: colors.action,
                                    ),
                                ],
                              ),
                            ),
                          ],
                          if (product.nutrition != null) ...[
                            const SizedBox(height: Brand.s12),
                            _ExpandableSection(
                              title: 'NUTRICIÓN POR PORCIÓN',
                              iconAsset: 'assets/icons/nutrition_flame.svg',
                              child: _NutritionTable(
                                nutrition: product.nutrition!,
                                flat: true,
                              ),
                            ),
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
        masa,
        unitPrice,
        originalUnitPrice,
        promotion != null,
      ),
    );
  }

  Widget _bottomBar(
    BuildContext context,
    Product product,
    MasaType? masa,
    double unitPrice,
    double originalUnitPrice,
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
                        Money.format(originalUnitPrice),
                        style: Brand.ui(
                          11,
                          color: colors.textSecondary,
                        ).copyWith(decoration: TextDecoration.lineThrough),
                      ),
                    if (sellable)
                      AnimatedMoney(
                        value: total,
                        style: Brand.ui(
                          18,
                          weight: FontWeight.w700,
                          color: colors.onBar,
                        ),
                      )
                    else
                      Text(
                        'No disponible',
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
                onPressed: sellable
                    ? () => _add(context, product, masa)
                    : null,
                showArrow: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _add(
    BuildContext context,
    Product product,
    MasaType? masa,
  ) async {
    final variant = _variant;
    if (variant == null) return;
    final added = await addProductToCart(
      context,
      product,
      variant,
      quantity: _quantity,
      masa: masa,
      extras: _selectedExtras.toList(),
      initialComponents: widget.initialItem?.componentes,
      replaceKey: widget.initialItem?.key,
    );
    if (!added || !context.mounted) return;
    HapticFeedback.lightImpact();
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

class _NutritionTable extends StatelessWidget {
  const _NutritionTable({required this.nutrition, this.flat = false});

  final NutritionInfo nutrition;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rows = <(String, String)>[
      ('Calorías', '${nutrition.calories} kcal'),
      ('Proteínas', '${nutrition.proteinG} g'),
      ('Carbohidratos', '${nutrition.carbsG} g'),
      ('Grasas', '${nutrition.fatG} g'),
      ('Grasas saturadas', '${nutrition.saturatedFatG} g'),
      ('Azúcares', '${nutrition.sugarsG} g'),
      ('Fibra', '${nutrition.fiberG} g'),
      ('Sodio', '${nutrition.sodiumMg} mg'),
      if (nutrition.alcoholG > 0) ('Alcohol', '${nutrition.alcoholG} g'),
    ];
    final content = Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: Brand.s4),
          Row(
            children: [
              Expanded(
                child: Text(
                  rows[i].$1,
                  style: context.text.bodySm.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Text(
                rows[i].$2,
                style: Brand.ui(12, weight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ],
    );
    if (flat) return content;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Brand.s12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(color: colors.border),
      ),
      child: content,
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  const _ExpandableSection({
    required this.title,
    required this.child,
    this.iconAsset,
  });

  final String title;
  final Widget child;
  final String? iconAsset;

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: Brand.s8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(Brand.s12),
              child: Row(
                children: [
                  if (widget.iconAsset != null) ...[
                    SvgPicture.asset(
                      widget.iconAsset!,
                      width: 12,
                      height: 12,
                      colorFilter: ColorFilter.mode(
                        ProductFamily.flameAccent,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: Brand.s4),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Brand.ui(
                        10,
                        weight: FontWeight.w700,
                        color: ProductFamily.flameAccent,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                Brand.s12,
                0,
                Brand.s12,
                Brand.s12,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: widget.child,
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _IngredientList extends StatelessWidget {
  const _IngredientList({required this.ingredients});

  final List<String> ingredients;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        for (final ingredient in ingredients)
          Padding(
            padding: const EdgeInsets.only(bottom: Brand.s8),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/ficha_ingredientes.svg',
                  width: 12,
                  height: 12,
                  colorFilter: ColorFilter.mode(
                    ProductFamily.flameAccent,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: Brand.s8),
                Expanded(
                  child: Text(
                    ingredient,
                    style: Brand.ui(
                      12,
                      color: colors.textSecondary,
                      h: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExtraRow extends StatelessWidget {
  const _ExtraRow({
    required this.extra,
    required this.selected,
    required this.onChanged,
  });

  final ProductExtra extra;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: Brand.s8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(
          color: selected ? colors.action : colors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!selected),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Brand.s12,
            vertical: Brand.s8,
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ficha_ingredientes.svg',
                width: 12,
                height: 12,
                colorFilter: ColorFilter.mode(
                  selected ? colors.action : ProductFamily.flameAccent,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: Brand.s8),
              Expanded(
                child: Text(extra.nombre, style: context.text.bodySm),
              ),
              Text(
                '+ ${Money.format(extra.precioSoles)}',
                style: Brand.ui(12, weight: FontWeight.w700),
              ),
              const SizedBox(width: Brand.s8),
              Checkbox(
                value: selected,
                onChanged: (value) => onChanged(value ?? false),
                activeColor: colors.action,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
    this.iconAsset,
  });

  final String label;
  final String value;
  final String? iconAsset;

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
          Row(
            children: [
              if (iconAsset != null) ...[
                SvgPicture.asset(
                  iconAsset!,
                  width: 11,
                  height: 11,
                  colorFilter: ColorFilter.mode(
                    ProductFamily.flameAccent,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: Brand.s4),
              ],
              Text(
                label,
                style: Brand.ui(
                  10,
                  weight: FontWeight.w700,
                  color: ProductFamily.flameAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: Brand.s4),
          Text(value, style: Brand.ui(12, color: colors.textSecondary, h: 1.4)),
        ],
      ),
    );
  }
}
