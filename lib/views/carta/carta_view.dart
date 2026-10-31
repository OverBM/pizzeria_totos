import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/cart_controller.dart';
import '../../controllers/catalog_controller.dart';
import '../../controllers/promotion_controller.dart';
import '../../core/data/product_summary.dart';
import '../../core/format/money.dart';
import '../../core/load_state.dart';
import '../../core/theme/brand.dart';
import '../../widgets/widgets.dart';
import '../../core/theme/theme_context.dart';
import '../../models/product.dart';
import '../../services/settings_service.dart';
import 'catalog_filter_controls.dart';

/// Carta editorial con filtros de categoría y tarjetas horizontales.
class CartaView extends StatefulWidget {
  const CartaView({super.key, required this.onGoToProduct});

  final void Function(Product product) onGoToProduct;

  @override
  State<CartaView> createState() => _CartaViewState();
}

class _CartaViewState extends State<CartaView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  String? _lastCategoryId;

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final catalog = context.read<CatalogController>();
    final id = catalog.selectedCategoryId;
    if (_lastCategoryId == null) {
      _lastCategoryId = id;
      return;
    }
    if (id != _lastCategoryId) {
      _lastCategoryId = id;
      _fade.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final promotions = context.watch<PromotionController>();
    final cart = context.watch<CartController>();

    if (catalog.state == LoadState.loading && !catalog.hasProducts) {
      return const SingleChildScrollView(child: SkeletonList(count: 5));
    }

    if (!catalog.hasProducts) {
      final settings = context.read<SettingsService>();
      final driveFolder = settings.driveFolderUrl;
      return SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: EmptyState(
            title: catalog.state == LoadState.error
                ? 'No pudimos cargar la carta'
                : 'No hay productos disponibles',
            message:
                catalog.error ??
                'El catálogo aún no tiene contenido publicado. '
                    'Vuelve a intentarlo en un momento.',
            icon: catalog.state == LoadState.error
                ? Icons.wifi_off_rounded
                : Icons.local_pizza_outlined,
            onAction: catalog.load,
            // Cuando el negocio aún no ha subido fotos, se le indica dónde
            // hacerlo. Sin carpeta configurada no se muestra enlace roto.
            secondaryLabel: driveFolder == null ? null : 'SUBIR FOTOS A DRIVE',
            onSecondary: driveFolder == null
                ? null
                : () => launchUrl(
                    Uri.parse(driveFolder),
                    mode: LaunchMode.externalApplication,
                  ),
          ),
        ),
      );
    }

    final products = catalog.visibleProducts;
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = math.max(Brand.s16, (width - 520) / 2 + Brand.s16);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ContentWidth(child: _intro(context, catalog)),
        ),
        const SliverToBoxAdapter(
          child: ContentWidth(child: CatalogFilterControls()),
        ),
        SliverToBoxAdapter(
          child: ContentWidth(child: _filters(context, catalog)),
        ),
        SliverToBoxAdapter(
          child: ContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Brand.s16,
                Brand.s12,
                Brand.s16,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    '${catalog.visibleCount} OPCIONES',
                    style: Brand.ui(
                      11,
                      weight: FontWeight.w700,
                      color: context.colors.action,
                    ),
                  ),
                  const Spacer(),
                  if (catalog.state == LoadState.loading)
                    const SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (products.isEmpty)
          SliverToBoxAdapter(
            child: ContentWidth(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Brand.s24),
                child: EmptyState(
                  title: catalog.hasActiveFilters
                      ? 'No encontramos productos'
                      : 'No hay productos en esta categoría',
                  message: catalog.hasActiveFilters
                      ? 'Prueba con otra búsqueda o quita algún filtro para '
                            'ver más opciones de la carta.'
                      : 'Por ahora no tenemos productos disponibles en '
                            '«${catalog.selectedCategoryName.toLowerCase()}». '
                            'Prueba con otra categoría.',
                  icon: Icons.local_pizza_outlined,
                  actionLabel: catalog.hasActiveFilters
                      ? 'LIMPIAR FILTROS'
                      : 'VER LAS MÁS PEDIDAS',
                  onAction: catalog.hasActiveFilters
                      ? catalog.clearFilters
                      : () => catalog.selectCategory(
                          CatalogController.featuredCategoryId,
                        ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 0),
            sliver: SliverList.separated(
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: Brand.s12),
              itemBuilder: (context, index) => _FadeSlide(
                animation: _fade,
                child: _card(context, products[index], promotions, cart),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: Brand.s24)),
      ],
    );
  }

  Widget _intro(BuildContext context, CatalogController catalog) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Brand.s16, Brand.s24, Brand.s16, 0),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '‹ NUESTRA CARTA ›',
              textAlign: TextAlign.left,
              style: Brand.ui(
                11,
                weight: FontWeight.w700,
                color: context.colors.action,
              ),
            ),
            const SizedBox(height: Brand.s4),
            const Align(
              alignment: Alignment.centerLeft,
              child: OutlinedDisplayTitle('LA CARTA', size: 40),
            ),
            const SizedBox(height: Brand.s8),
            Text(
              'Elige tu favorita y la preparamos al momento.',
              textAlign: TextAlign.left,
              style: context.text.bodySm.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters(BuildContext context, CatalogController catalog) {
    // La categoría virtual se antepone una sola vez; cualquier documento real
    // con el mismo id queda fuera aunque siga en Firestore.
    final categories = catalog.menu.activeCategories
        .where((c) => c.id != CatalogController.featuredCategoryId)
        .toList();
    return Padding(
      padding: const EdgeInsets.only(top: Brand.s16),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Brand.s16),
          itemCount: categories.length + 2,
          separatorBuilder: (_, _) => const SizedBox(width: Brand.s8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return FilterPill(
                label: 'Todos',
                selected:
                    catalog.selectedCategoryId == CatalogController.allCategoryId,
                onTap: () => catalog.selectCategory(
                  CatalogController.allCategoryId,
                ),
              );
            }
            if (index == 1) {
              return FilterPill(
                label: 'Las más pedidas',
                selected:
                    catalog.selectedCategoryId ==
                    CatalogController.featuredCategoryId,
                onTap: () => catalog.selectCategory(
                  CatalogController.featuredCategoryId,
                ),
              );
            }
            final category = categories[index - 2];
            return FilterPill(
              label: category.name,
              selected: catalog.selectedCategoryId == category.id,
              onTap: () => catalog.selectCategory(category.id),
            );
          },
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context,
    Product product,
    PromotionController promotions,
    CartController cart,
  ) {
    final variant = product.defaultVariantOrNull;
    final priced = variant == null
        ? null
        : promotions.priceFor(product, variant);
    final price = priced?.finalSoles;
    final originalPrice = priced?.hasDiscount == true
        ? priced!.baseSoles
        : null;
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
      originalPriceLabel: originalPrice == null
          ? null
          : Money.format(originalPrice),
      onTap: () => widget.onGoToProduct(product),
      onAdd: product.isSellable
          ? () {
              cart.add(product, variant!);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('${product.name} agregado al pedido'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              HapticFeedback.lightImpact();
            }
          : null,
    );
  }
}

/// Aplica el fade + 8 dp de desplazamiento del cambio de categoría.
class _FadeSlide extends StatelessWidget {
  const _FadeSlide({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - animation.value)),
          child: child,
        ),
      ),
    );
  }
}
