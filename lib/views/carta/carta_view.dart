import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/cart_controller.dart';
import '../../controllers/catalog_controller.dart';
import '../../controllers/promotion_controller.dart';
import '../../core/format/money.dart';
import '../../core/load_state.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/components.dart';
import '../../core/theme/theme_context.dart';
import '../../models/product.dart';
import '../../services/settings_service.dart';
import '../common/drive_image.dart';

/// Carta editorial con filtros de categoría y tarjetas horizontales.
class CartaView extends StatelessWidget {
  const CartaView({super.key, required this.onGoToProduct});

  final void Function(Product product) onGoToProduct;

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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _intro(context, catalog)),
        SliverToBoxAdapter(child: _filters(context, catalog)),
        SliverToBoxAdapter(
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
        SliverToBoxAdapter(
          child: products.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: Brand.s24),
                  child: EmptyState(
                    title: 'No hay productos en esta categoría',
                    message:
                        'Por ahora no tenemos productos disponibles en '
                        '«${catalog.selectedCategoryName.toLowerCase()}». '
                        'Prueba con otra categoría.',
                    icon: Icons.local_pizza_outlined,
                    actionLabel: 'VER LAS MÁS PEDIDAS',
                    onAction: () => catalog.selectCategory(
                      CatalogController.featuredCategoryId,
                    ),
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Padding(
                    key: ValueKey(catalog.selectedCategoryId),
                    padding: const EdgeInsets.all(Brand.s16),
                    child: Column(
                      children: [
                        for (var i = 0; i < products.length; i++) ...[
                          if (i > 0) const SizedBox(height: Brand.s12),
                          _card(
                            context,
                            products[i],
                            catalog,
                            promotions,
                            cart,
                          ),
                        ],
                      ],
                    ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '‹ NUESTRA CARTA ›',
            style: Brand.ui(
              11,
              weight: FontWeight.w700,
              color: context.colors.action,
            ),
          ),
          const SizedBox(height: Brand.s4),
          const OutlinedDisplayTitle('LA CARTA', size: 40),
          const SizedBox(height: Brand.s8),
          Text(
            'Pizzas de masa madre, pastas y combos para compartir. '
            'Elige tu favorita y la preparamos al momento.',
            style: context.text.bodySm.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
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
          itemCount: categories.length + 1,
          separatorBuilder: (_, _) => const SizedBox(width: Brand.s8),
          itemBuilder: (context, index) {
            if (index == 0) {
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
            final category = categories[index - 1];
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
    CatalogController catalog,
    PromotionController promotions,
    CartController cart,
  ) {
    final variant = product.defaultVariantOrNull;
    final promotion = variant == null
        ? null
        : promotions.forVariant(product.id, variant.label);
    final price = variant == null
        ? null
        : promotion?.discountedPrice(variant.priceSoles) ?? variant.priceSoles;
    final categoryName =
        catalog.menu.categoryById(product.categoryId)?.name ?? 'CARTA';
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
      description: product.description,
      categoryLabel: categoryName,
      priceLabel: price == null ? 'No disponible' : Money.format(price),
      onTap: () => onGoToProduct(product),
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
