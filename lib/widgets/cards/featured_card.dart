part of '../widgets.dart';


/// Tarjeta destacada de radio 22 con foto, etiqueta, resumen y precio circular.
///
/// Ocupa el alto del carrusel para que todas las tarjetas queden alineadas; el
/// resumen llena el centro y el precio/carrito cierran la tarjeta abajo.
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({
    super.key,
    required this.image,
    required this.title,
    required this.priceLabel,
    this.eyebrow,
    this.description,
    this.categoryId,
    this.summary,
    this.onTap,
    this.onAdd,
    this.width = 268,
    this.imageHeight = 223,
  });

  final Widget image;
  final String title;
  final String priceLabel;
  final String? eyebrow;
  final String? description;
  final String? categoryId;
  final ProductSummary? summary;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final double width;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ingredients = summary?.visibleIngredients ?? '';
    return SizedBox(
      width: width,
      child: MotionPressable(
        onTap: onTap,
        semanticLabel: title,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: image,
                  ),
                  if (eyebrow != null)
                    Positioned(
                      left: Brand.s12,
                      top: Brand.s12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Brand.s8,
                          vertical: Brand.s4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.bar,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colors.action),
                        ),
                        child: Text(
                          eyebrow!.toUpperCase(),
                          style: Brand.ui(
                            9,
                            weight: FontWeight.w700,
                            color: colors.onBar,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Brand.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Brand.display(
                          17,
                          h: 1.05,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: Brand.s4),
                        Text(
                          description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySm.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      if (ingredients.isNotEmpty) ...[
                        const SizedBox(height: Brand.s4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: ProductFamilyIcon(
                                categoryId: categoryId,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                ingredients,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Brand.ui(
                                  11,
                                  color: colors.textSecondary,
                                  h: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          PriceCircle(priceLabel: priceLabel, onTap: onTap),
                          const SizedBox(width: Brand.s8),
                          if (onAdd != null)
                            Expanded(
                              child: _FeaturedAddButton(
                                onTap: onAdd!,
                                label: 'Agregar $title',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón ancho de agregar con el carrito dentro.
class _FeaturedAddButton extends StatelessWidget {
  const _FeaturedAddButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: colors.action,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AddToCartIcon(size: 26),
              const SizedBox(width: Brand.s8),
              Text(
                'AGREGAR',
                style: Brand.ui(
                  11,
                  weight: FontWeight.w700,
                  color: colors.onAction,
                  h: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Precio en círculo naranja de 54 dp.
class PriceCircle extends StatelessWidget {
  const PriceCircle({
    super.key,
    required this.priceLabel,
    this.onTap,
    this.size = 54,
  });

  final String priceLabel;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final circle = Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.action, shape: BoxShape.circle),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            priceLabel,
            style: Brand.ui(
              12,
              weight: FontWeight.w700,
              color: colors.onAction,
              h: 1,
            ),
          ),
        ),
      ),
    );
    if (onTap == null) return circle;
    return GestureDetector(onTap: onTap, child: circle);
  }
}
