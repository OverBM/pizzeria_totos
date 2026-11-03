import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/format/money.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../models/delivery_quote.dart';
import '../../widgets/widgets.dart';

/// Mapa de entrega embebido en el Paso 2.
///
/// Dibuja la ruta sede → punto y permite mover el pin tocando el mapa. Cuando
/// la ruta llega, el encuadre se ajusta solo para que se vean los dos extremos.
class DeliveryMapPicker extends StatelessWidget {
  const DeliveryMapPicker({
    super.key,
    required this.point,
    required this.branchPoint,
    this.userPoint,
    this.route,
    this.quote,
    this.chargedFeeSoles,
    this.included = false,
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
  final double? chargedFeeSoles;
  final bool included;
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
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 210,
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
                    // Con ruta, el encuadre lo manda `autoFitRoute`; así el
                    // mapa no salta dos veces (pin y luego ruta).
                    focus: point?.latLng,
                    userPoint: userPoint,
                    route: route,
                    onMapTap: onMapTap,
                    initialZoom: 14,
                    showFitButton: true,
                    autoFitRoute: true,
                    centerOnFocus: false,
                    flush: true,
                  ),
                ),
                if (point != null && quote != null && quote!.etaMinutes > 0)
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Brand.s12,
              Brand.s10,
              Brand.s12,
              Brand.s12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: colors.action,
                    ),
                    const SizedBox(width: Brand.s4),
                    Expanded(
                      child: Text(
                        point?.label.trim().isNotEmpty ?? false
                            ? point!.label
                            : 'Sin punto de entrega',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Brand.ui(
                          11,
                          weight: FontWeight.w700,
                          color: point == null
                              ? colors.textSecondary
                              : colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
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
                // Barra fija de 2 dp: evita que el bloque salte al cotizar.
                SizedBox(
                  height: 2,
                  child: quoting
                      ? LinearProgressIndicator(
                          minHeight: 2,
                          color: colors.action,
                          backgroundColor: colors.border,
                        )
                      : null,
                ),
                const SizedBox(height: Brand.s8),
                _status(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(BuildContext context) {
    final colors = context.colors;
    final caption = context.text.caption.copyWith(color: colors.textSecondary);
    if (quoting) {
      return Text('Calculando ruta y envío…', style: caption);
    }
    if (error != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              error!,
              style: context.text.caption.copyWith(color: colors.action),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('REINTENTAR')),
        ],
      );
    }
    if (quote == null) {
      return Text(
        'Toca el mapa para elegir el punto de entrega.',
        style: caption,
      );
    }
    if (!quote!.deliverable) {
      return Text(
        'Fuera del rango de delivery. Elige recojo u otra sede.',
        style: context.text.caption.copyWith(color: colors.action),
      );
    }
    return Row(
      children: [
        Icon(Icons.route_rounded, size: 16, color: colors.action),
        const SizedBox(width: Brand.s4),
        Expanded(
          child: Text(
            included
                ? '${quote!.bandLabel} · Envío incluido con tu plan'
                : '${quote!.bandLabel} · Envío '
                    '${Money.format(chargedFeeSoles ?? quote!.feeSoles)}',
            style: caption,
          ),
        ),
      ],
    );
  }
}
