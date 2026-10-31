part of '../widgets.dart';


/// Tarjeta horizontal de carta: foto de 126 dp y datos a la derecha.
///
/// La foto cubre todo el alto y la columna de texto dicta ese alto: la tarjeta
/// no reserva espacio vacÃ­o. La acciÃ³n de agregar queda fuera del `Semantics`
/// informativo para conservar su nodo. La nutriciÃ³n vive solo en el detalle.
class ProductRowCard extends StatelessWidget {
  const ProductRowCard({
    super.key,
    required this.image,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.summary,
    required this.priceLabel,
    this.originalPriceLabel,
    this.onTap,
    this.onAdd,
  });

  final Widget image;
  final String name;
  final String description;
  final String? categoryId;
  final ProductSummary summary;
  final String priceLabel;
  final String? originalPriceLabel;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final family = ProductFamily.forCategoryId(categoryId);
    final ingredients = summary.visibleIngredients;

    return Stack(
      children: [
        MotionPressable(
          onTap: onTap,
          semanticLabel: summary.semanticsLabel(
            name: name,
            familyLabel: family?.label ?? 'Carta',
          ),
          child: ExcludeSemantics(
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: Brand.cardRadius,
                border: Border.all(color: colors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // La columna informativa dicta el alto de la tarjeta.
                  Padding(
                    padding: const EdgeInsets.only(left: 126),
                    child: Padding(
                      padding: const EdgeInsets.all(Brand.s12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Brand.display(
                              17,
                              h: 1.05,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: Brand.s4),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Brand.ui(
                              12,
                              color: colors.textSecondary,
                              h: 1.3,
                            ),
                          ),
                          if (ingredients.isNotEmpty) ...[
                            const SizedBox(height: Brand.s8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: ProductFamilyIcon(
                                    categoryId: categoryId,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    ingredients,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Brand.ui(
                                      11,
                                      color: colors.textSecondary,
                                      h: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: Brand.s8),
                          SizedBox(
                            height: onAdd == null ? null : 42,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: onAdd == null ? 0 : 44,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (originalPriceLabel != null)
                                      Text(
                                        originalPriceLabel!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Brand.ui(
                                          10,
                                          color: colors.textSecondary,
                                        ).copyWith(
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    Text(
                                      priceLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Brand.ui(
                                        17,
                                        weight: FontWeight.w700,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 126,
                    child: image,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (onAdd != null)
          Positioned(
            right: Brand.s12,
            bottom: Brand.s12,
            child: RoundActionButton(
              icon: const AddToCartIcon(),
              onTap: onAdd,
              label: 'Agregar $name',
              size: 36,
            ),
          ),
      ],
    );
  }
}
