import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../controllers/branch_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/catalog_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/promotion_controller.dart';
import '../../core/data/product_summary.dart';
import '../../core/format/money.dart';
import '../../core/load_state.dart';
import '../../core/theme/brand.dart';
import '../../widgets/widgets.dart';
import '../../core/theme/theme_context.dart';
import '../../core/time/lima_time.dart';
import '../../models/branch.dart';
import '../../models/product.dart';
import '../../services/contact_launcher.dart';
import '../../services/settings_service.dart';
import '../branches/branch_detail_sheet.dart';

/// Inicio editorial: hero, categorías, favoritas, promoción y sedes.
class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    required this.onGoToCarta,
    required this.onGoToSedes,
    required this.onGoToPromotions,
    required this.onGoToProduct,
    this.now,
  });

  final void Function(String? categoryId) onGoToCarta;
  final VoidCallback onGoToSedes;
  final VoidCallback onGoToPromotions;
  final void Function(Product product) onGoToProduct;

  /// Reloj para el estado de la sede. Las pruebas lo fijan; en producción se
  /// usa la hora de `America/Lima`.
  final DateTime Function()? now;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ScrollController _scroll = ScrollController();
  final PageController _featuredPages = PageController(viewportFraction: 0.86);
  final PageController _promoPages = PageController();
  int _featuredIndex = 0;
  int _promoIndex = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.hasClients) setState(() {});
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _featuredPages.dispose();
    _promoPages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final promotions = context.watch<PromotionController>();
    final branches = context.watch<BranchController>();
    final orders = context.watch<OrderController>();
    final settings = Provider.of<SettingsService>(context, listen: false);
    final loading = catalog.state == LoadState.loading && !catalog.hasProducts;
    final heroHeight = math.min(
      460.0,
      math.max(320.0, MediaQuery.sizeOf(context).height * 0.62),
    );

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverToBoxAdapter(
          child: RepaintBoundary(
            child: HeroBanner(
              image: settings.settings.heroImage == null
                  ? Image.asset(
                      'assets/images/hero-1.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, _) =>
                          Container(color: Brand.maroonLift),
                    )
                  : DriveImage(
                      media: settings.settings.heroImage,
                      fallbackAssetName: 'hero-1',
                      requestWidth: MediaQuery.sizeOf(context).width,
                    ),
              title: 'PIZZA',
              titleTail: '(Y PASTAS)',
              height: heroHeight,
              scrollOffset: _scroll.hasClients ? _scroll.offset : 0,
              onPrimary: () => widget.onGoToCarta(null),
              onSecondary: widget.onGoToSedes,
            ),
          ),
        ),
        if (loading)
          const SliverToBoxAdapter(child: SkeletonList(count: 3, height: 132))
        else if (catalog.state == LoadState.error && !catalog.hasProducts)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              title: 'No pudimos cargar la carta',
              message:
                  catalog.error ?? 'Revisa tu conexión e inténtalo de nuevo.',
              icon: Icons.wifi_off_rounded,
              onAction: catalog.load,
            ),
          )
        else if (!catalog.hasProducts)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              title: 'No hay productos disponibles',
              message:
                  'El catálogo aún no tiene contenido publicado. '
                  'Vuelve a intentarlo en un momento.',
              icon: Icons.local_pizza_outlined,
              onAction: catalog.load,
            ),
          )
        else ...[
          SliverToBoxAdapter(child: ContentWidth(child: _categories(catalog))),
          SliverToBoxAdapter(
            child: ContentWidth(child: _featured(catalog, promotions)),
          ),
          SliverToBoxAdapter(
            child: ContentWidth(child: _preview(catalog, promotions, orders)),
          ),
          SliverToBoxAdapter(
            child: ContentWidth(child: _promotions(catalog, promotions)),
          ),
          SliverToBoxAdapter(
            child: ContentWidth(child: _branches(branches, settings)),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Brand.s32)),
        ],
      ],
    );
  }

  Widget _categories(CatalogController catalog) {
    final categories = catalog.menu.activeCategories;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Brand.s16, Brand.s24, Brand.s16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            eyebrow: 'Antojo del día',
            title: '¿Qué se te antoja?',
            actionLabel: 'Ver carta',
            onAction: () => widget.onGoToCarta(null),
          ),
          const SizedBox(height: Brand.s12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: Brand.s8),
              itemBuilder: (context, index) {
                final category = categories[index];
                return FilterPill(
                  label: category.name,
                  selected: false,
                  onTap: () => widget.onGoToCarta(category.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _featured(CatalogController catalog, PromotionController promotions) {
    final featured = catalog.homeHighlights;
    if (featured.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Brand.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Brand.s16),
            child: SectionHeading(
              eyebrow: 'Recomendadas',
              title: 'Favoritas de la casa',
              actionLabel: 'Ver carta',
              onAction: () => widget.onGoToCarta(null),
            ),
          ),
          const SizedBox(height: Brand.s12),
          RepaintBoundary(
            child: SizedBox(
              height: 392,
              child: PageView.builder(
                controller: _featuredPages,
                padEnds: false,
                itemCount: featured.length,
                onPageChanged: (index) =>
                    setState(() => _featuredIndex = index),
                itemBuilder: (context, index) {
                  final product = featured[index];
                  final variant = product.defaultVariantOrNull;
                  final promotion = variant == null
                      ? null
                      : promotions.forVariant(product.id, variant.label);
                  final price = variant == null
                      ? null
                      : promotion?.discountedPrice(variant.priceSoles) ??
                            variant.priceSoles;
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? Brand.s16 : Brand.s8,
                      right: index == featured.length - 1 ? Brand.s16 : 0,
                    ),
                    child: FeaturedCard(
                      image: Hero(
                        tag: 'product-${product.id}',
                        child: DriveImage(
                          media: product.image,
                          placeholderLabel: product.name,
                          fallbackAssetName: product.image?.assetName,
                        ),
                      ),
                      title: product.name,
                      description: product.displaySummary,
                      eyebrow: product.tags.isEmpty
                          ? 'DE LA CASA'
                          : product.tags.first,
                      priceLabel: price == null
                          ? 'No disponible'
                          : Money.format(price),
                      categoryId: product.categoryId,
                      summary: ProductSummary.of(product),
                      onTap: () => widget.onGoToProduct(product),
                      onAdd: product.isSellable
                          ? () => _addToCart(context, product)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: Brand.s12),
          Center(
            child: PageDots(count: featured.length, index: _featuredIndex),
          ),
        ],
      ),
    );
  }

  /// Sección «Del horno a tu mesa»: combos pedidos recientemente o, si no
  /// hay historial, productos que no repiten las favoritas.
  Widget _preview(
    CatalogController catalog,
    PromotionController promotions,
    OrderController orders,
  ) {
    final recent = _recentCombos(catalog, orders);
    final products = recent.isNotEmpty ? recent : catalog.homePreview;
    if (products.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Brand.s16, Brand.s24, Brand.s16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            eyebrow: recent.isNotEmpty ? 'Tu último pedido' : 'Recién horneadas',
            title: recent.isNotEmpty
                ? 'Tus combos recientes'
                : 'Del horno a tu mesa',
            actionLabel: 'Ver carta',
            onAction: () => widget.onGoToCarta(null),
          ),
          const SizedBox(height: Brand.s12),
          for (var i = 0; i < products.length; i++) ...[
            if (i > 0) const SizedBox(height: Brand.s12),
            _previewCard(context, products[i], promotions),
          ],
        ],
      ),
    );
  }

  /// Combos de los pedidos del usuario, sin repetir y en orden de historial.
  List<Product> _recentCombos(
    CatalogController catalog,
    OrderController orders,
  ) {
    final seen = <String>{};
    final result = <Product>[];
    for (final order in orders.orders) {
      for (final item in order.items) {
        final product = catalog.byId(item.productId);
        if (product == null || !product.available) continue;
        if (product.categoryId != 'combos') continue;
        if (!seen.add(product.id)) continue;
        result.add(product);
        if (result.length >= 6) return result;
      }
    }
    return result;
  }

  Widget _previewCard(
    BuildContext context,
    Product product,
    PromotionController promotions,
  ) {
    final variant = product.defaultVariantOrNull;
    final promotion = variant == null
        ? null
        : promotions.forVariant(product.id, variant.label);
    final price = variant == null
        ? null
        : promotion?.discountedPrice(variant.priceSoles) ?? variant.priceSoles;
    return ProductRowCard(
      image: Hero(
        tag: 'product-${product.id}',
        child: DriveImage(
          media: product.image,
          placeholderLabel: product.name,
          fallbackAssetName: product.image?.assetName,
        ),
      ),
      name: product.name,
      description: product.displaySummary,
      categoryId: product.categoryId,
      summary: ProductSummary.of(product),
      priceLabel: price == null ? 'No disponible' : Money.format(price),
      onTap: () => widget.onGoToProduct(product),
      onAdd: product.isSellable ? () => _addToCart(context, product) : null,
    );
  }

  /// Agrega la variante por defecto y confirma con un aviso breve.
  void _addToCart(BuildContext context, Product product) {
    final variant = product.defaultVariantOrNull;
    if (variant == null) return;
    context.read<CartController>().add(product, variant);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${product.name} agregado al pedido'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Widget _promotions(
    CatalogController catalog,
    PromotionController promotions,
  ) {
    final banners = promotions.banners
        .where((promotion) => catalog.byId(promotion.productId)?.isSellable ?? false)
        .toList();
    if (banners.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Brand.s16, Brand.s24, Brand.s16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            eyebrow: 'Solo por ahora',
            title: 'La promo de la casa',
            actionLabel: 'Ver todas',
            onAction: widget.onGoToPromotions,
          ),
          const SizedBox(height: Brand.s12),
          RepaintBoundary(
            child: SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _promoPages,
                physics: banners.length > 1
                    ? null
                    : const NeverScrollableScrollPhysics(),
                itemCount: banners.length,
                onPageChanged: (index) => setState(() => _promoIndex = index),
                itemBuilder: (context, index) {
                  final promotion = banners[index];
                  final product = catalog.byId(promotion.productId)!;
                  return PromoBanner(
                    promotion: promotion,
                    product: product,
                    onTap: () => widget.onGoToProduct(product),
                  );
                },
              ),
            ),
          ),
          if (banners.length > 1) ...[
            const SizedBox(height: Brand.s12),
            Center(
              child: PageDots(
                count: banners.length,
                index: _promoIndex.clamp(0, banners.length - 1),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _branches(BranchController branches, SettingsService settings) {
    final Branch? branch = branches.branches.isEmpty
        ? null
        : branches.branches.first;
    final clock = widget.now ?? LimaTime.now;
    final open = branch == null ? false : branch.isOpenAt(clock());
    return Padding(
      padding: const EdgeInsets.fromLTRB(Brand.s16, Brand.s24, Brand.s16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            eyebrow: 'Cerca de ti',
            title: 'Nuestras sedes',
            actionLabel: 'Ver todas',
            onAction: widget.onGoToSedes,
          ),
          const SizedBox(height: Brand.s12),
          if (branch == null)
            Text(
              'Estamos cargando las sedes de Huancayo.',
              style: context.text.bodySm,
            )
          else
            BranchMapCard(
              name: branch.name,
              address: branch.address,
              statusLabel: open ? 'ABIERTA' : 'CERRADA',
              open: open,
              onSelect: () => _openBranch(branch, settings),
              thumbnail: IgnorePointer(
                child: TotoMap(
                  markers: [
                    TotoMapMarker(
                      id: branch.id,
                      point: LatLng(branch.lat, branch.lng),
                      label: branch.name,
                    ),
                  ],
                  height: 140,
                  initialZoom: 15.5,
                  interactive: false,
                  showFitButton: false,
                  flush: true,
                ),
              ),
              hoursLabel: branch.hours.rangeLabel,
              deliveryLabel: branch.delivers
                  ? 'Delivery disponible'
                  : 'Solo recojo en tienda',
              onCall: () => ContactLauncher.call(
                branch.phone.isEmpty ? settings.phone : branch.phone,
              ),
              onWhatsapp: () => ContactLauncher.whatsapp(
                phone: branch.whatsapp.isEmpty
                    ? settings.whatsapp
                    : branch.whatsapp,
                message:
                    'Hola TOTO\'S, quiero hacer un pedido en la sede '
                    '${branch.name}.',
              ),
              onMap: () => ContactLauncher.openMap(
                branch.lat,
                branch.lng,
                label: "TOTO'S ${branch.name}",
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openBranch(Branch branch, SettingsService settings) async {
    final goToMap = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BranchDetailSheet(
        branch: branch,
        phoneFallback: settings.phone,
        whatsappFallback: settings.whatsapp,
      ),
    );
    if (!mounted || goToMap != true) return;
    widget.onGoToSedes();
  }
}
