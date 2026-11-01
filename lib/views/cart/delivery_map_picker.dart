import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/format/money.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../models/delivery_quote.dart';
import '../../widgets/widgets.dart';

/// Mapa de entrega embebido en el Paso 2.
///
/// Dibuja la ruta sede → punto y permite mover el pin tocando el mapa.
class DeliveryMapPicker extends StatelessWidget {
  const DeliveryMapPicker({
    super.key,
    required this.point,
    required this.branchPoint,
    this.userPoint,
    this.route,
    this.quote,
    this.quoting = false,
    this.locating = false,
    this.error,
    required this.onMapTap,
    required this.onSearch,
    required this.onUseLocation,
    required this.onRetry,
  });

  final DeliveryPoint? point;
  final LatLng? branchPoint;
  final LatLng? userPoint;
  final MapRoute? route;
  final DeliveryQuote? quote;
  final bool quoting;
  final bool locating;
  final String? error;
  final ValueChanged<LatLng> onMapTap;
  final VoidCallback onSearch;
  final VoidCallback onUseLocation;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: Brand.cardRadius,
          child: SizedBox(
            height: 240,
            child: Stack(
              children: [
                Positioned.fill(
                  child: TotoMap(
                    markers: [
                      if (branchPoint != null)
                        TotoMapMarker(
                          id: 'branch',
                          point: branchPoint!,
                          label: 'Sede',
                        ),
                      if (point != null)
                        TotoMapMarker(
                          id: 'delivery',
                          point: point!.latLng,
                          label: 'Punto de entrega',
                          selected: true,
                          kind: TotoMapMarkerKind.delivery,
                        ),
                    ],
                    focus: point?.latLng,
                    userPoint: userPoint,
                    route: route,
                    onMapTap: onMapTap,
                    initialZoom: 14,
                    showFitButton: true,
                  ),
                ),
                if (point != null &&
                    quote != null &&
                    quote!.etaMinutes > 0)
                  Positioned(
                    left: Brand.s8,
                    top: Brand.s8,
                    child: MapInfoChip(
                      label:
                          '${quote!.distanceLabel} · '
                          '~${quote!.etaMinutes} min',
                      iconAsset: 'assets/icons/delivery.svg',
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Brand.s8),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'BUSCAR DIRECCIÓN',
                filled: false,
                onPressed: onSearch,
              ),
            ),
            const SizedBox(width: Brand.s8),
            Expanded(
              child: PillButton(
                label: locating ? 'UBICANDO…' : 'MI UBICACIÓN',
                filled: false,
                onPressed: locating ? null : onUseLocation,
              ),
            ),
          ],
        ),
        const SizedBox(height: Brand.s8),
        if (quoting)
          const LinearProgressIndicator()
        else if (error != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  error!,
                  style: context.text.caption.copyWith(
                    color: colors.action,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text('REINTENTAR'),
              ),
            ],
          )
        else if (quote != null && !quote!.deliverable)
          Text(
            'Fuera de cobertura. Elige recojo u otra sede.',
            style: context.text.caption.copyWith(color: colors.action),
          )
        else if (quote != null)
          Row(
            children: [
              Icon(Icons.route_rounded, size: 16, color: colors.action),
              const SizedBox(width: Brand.s4),
              Expanded(
                child: Text(
                  '${quote!.bandLabel} · '
                  'Envío ${Money.format(quote!.feeSoles)}',
                  style: context.text.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            'Toca el mapa para elegir el punto de entrega.',
            style: context.text.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
      ],
    );
  }
}
