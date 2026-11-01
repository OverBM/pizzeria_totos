part of '../widgets.dart';

/// Tarjeta con distancia, tramo, costo y ETA de una cotización.
class DeliveryQuoteCard extends StatelessWidget {
  const DeliveryQuoteCard({
    super.key,
    required this.quote,
    this.onRetry,
  });

  final DeliveryQuote quote;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (quote.source == DeliveryQuoteSource.pickup) {
      return _box(
        context,
        child: Row(
          children: [
            Icon(Icons.home_rounded, size: 18, color: colors.action),
            const SizedBox(width: Brand.s8),
            Expanded(
              child: Text(
                'Recojo en tienda · Sin costo',
                style: context.text.bodySm,
              ),
            ),
          ],
        ),
      );
    }
    if (!quote.deliverable) {
      return _box(
        context,
        borderColor: colors.action,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_off_outlined, size: 18, color: colors.action),
                const SizedBox(width: Brand.s8),
                Text(
                  'FUERA DE COBERTURA',
                  style: Brand.ui(
                    10,
                    weight: FontWeight.w700,
                    color: colors.action,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Brand.s4),
            Text(
              'El punto está fuera del radio de delivery. Elige recojo en '
              'tienda u otra sede.',
              style: context.text.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('CAMBIAR PUNTO'),
              ),
          ],
        ),
      );
    }
    return _box(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(
            context,
            'Distancia',
            quote.distanceKm > 0 ? quote.distanceLabel : 'Por calcular',
          ),
          if (quote.bandLabel.isNotEmpty)
            _row(context, 'Tramo', quote.bandLabel),
          _row(
            context,
            'Envío',
            quote.feeSoles == 0 ? 'Sin costo' : Money.format(quote.feeSoles),
            accent: true,
          ),
          if (quote.etaMinutes > 0)
            _row(context, 'Tiempo estimado', '~${quote.etaMinutes} min'),
          if (quote.isEstimated) ...[
            const SizedBox(height: Brand.s4),
            Text(
              'Envío estimado, se confirma por WhatsApp.',
              style: context.text.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _box(
    BuildContext context, {
    required Widget child,
    Color? borderColor,
  }) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Brand.s12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(color: borderColor ?? colors.border),
      ),
      child: child,
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool accent = false,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Brand.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: Brand.ui(
              12,
              weight: FontWeight.w700,
              color: accent ? colors.action : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
