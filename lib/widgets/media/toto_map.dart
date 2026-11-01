part of '../widgets.dart';

/// Tipo de marcador del mapa.
enum TotoMapMarkerKind { branch, delivery, search }

/// Marcador del mapa de sedes.
class TotoMapMarker {
  const TotoMapMarker({
    required this.id,
    required this.point,
    required this.label,
    this.selected = false,
    this.kind = TotoMapMarkerKind.branch,
  });

  final String id;
  final LatLng point;
  final String label;
  final bool selected;
  final TotoMapMarkerKind kind;
}

/// Mapa interactivo de OpenStreetMap.
///
/// Se usa en Sedes y en cualquier pantalla que necesite ubicar puntos. El
/// proveedor vive en [mapsService], así que migrar a Google Maps no cambia este
/// widget.
class TotoMap extends StatefulWidget {
  const TotoMap({
    super.key,
    required this.markers,
    this.focus,
    this.selectedId,
    this.height = 240,
    this.initialZoom = 12.6,
    this.onMarkerTap,
    this.interactive = true,
    this.showFitButton = true,
    this.flush = false,
    this.userPoint,
    this.onMapTap,
    this.route,
    this.autoFitRoute = false,
    this.expand = false,
  });

  final List<TotoMapMarker> markers;

  /// Punto al que se desplaza el mapa cuando cambia (búsqueda de dirección).
  final LatLng? focus;

  /// Ubicación actual del usuario.
  final LatLng? userPoint;

  /// Se dispara al tocar el mapa, por ejemplo para mover el pin de entrega.
  final ValueChanged<LatLng>? onMapTap;

  /// Ruta por calles que se dibuja como polilínea.
  final MapRoute? route;

  /// Ajusta el encuadre a la ruta cuando cambia.
  final bool autoFitRoute;

  /// Ocupa todo el alto disponible (para pantallas con `Expanded`).
  final bool expand;

  /// Marcador resaltado; el mapa se centra en él cuando cambia.
  final String? selectedId;

  final double height;
  final double initialZoom;
  final ValueChanged<TotoMapMarker>? onMarkerTap;

  /// Permite arrastrar y hacer zoom. Las miniaturas de tarjeta lo desactivan.
  final bool interactive;

  /// Muestra el botón para volver al encuadre con todas las sedes.
  final bool showFitButton;

  /// Sin borde ni radio propios: se usa dentro de una tarjeta o una hoja.
  final bool flush;

  @override
  State<TotoMap> createState() => _TotoMapState();
}

class _TotoMapState extends State<TotoMap> {
  static const double _detailZoom = 15;

  final MapController _controller = MapController();

  @override
  void didUpdateWidget(covariant TotoMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoFitRoute &&
        widget.route != null &&
        widget.route != oldWidget.route &&
        widget.route!.points.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitAll();
      });
      return;
    }
    final selectedId = widget.selectedId;
    if (selectedId != null && selectedId != oldWidget.selectedId) {
      for (final marker in widget.markers) {
        if (marker.id == selectedId) {
          _move(marker.point, _detailZoom);
          return;
        }
      }
    }
    final focus = widget.focus;
    if (focus != null && focus != oldWidget.focus) {
      _move(focus, _detailZoom);
      return;
    }
    final user = widget.userPoint;
    if (user != null && user != oldWidget.userPoint) {
      _move(user, _detailZoom);
    }
  }

  void _move(LatLng point, double zoom) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.move(point, zoom);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initialCenter = widget.focus ??
        widget.userPoint ??
        (widget.markers.isEmpty
            ? huancayoCenter
            : widget.markers.first.point);

    final map = SizedBox(
      height: widget.expand ? double.infinity : widget.height,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: widget.initialZoom,
              minZoom: 10,
              maxZoom: 18,
              backgroundColor: colors.surface,
              interactionOptions: InteractionOptions(
                flags: widget.interactive
                    ? InteractiveFlag.all & ~InteractiveFlag.rotate
                    : InteractiveFlag.none,
              ),
              onTap: widget.onMapTap == null
                  ? null
                  : (_, point) => widget.onMapTap!(point),
            ),
            children: [
              TileLayer(
                urlTemplate: mapsService.tileUrlTemplate,
                userAgentPackageName: 'com.totos.pizzeria',
                maxNativeZoom: 19,
              ),
              if (widget.route != null && widget.route!.points.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.route!.points,
                      color: colors.action,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final marker in widget.markers) _marker(marker),
                  if (widget.userPoint != null)
                    Marker(
                      point: widget.userPoint!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Brand.boneWhite,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.bar.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  mapsService.attribution,
                  style: Brand.ui(9, color: colors.onBar),
                ),
              ),
            ),
          ),
          if (widget.showFitButton &&
              (widget.markers.length > 1 ||
                  widget.userPoint != null ||
                  (widget.route?.points.isNotEmpty ?? false)))
            Positioned(
              right: 8,
              top: 8,
              child: Material(
                color: colors.bar.withValues(alpha: 0.86),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  onPressed: _fitAll,
                  icon: Icon(
                    Icons.zoom_out_map_rounded,
                    size: 18,
                    color: colors.onBar,
                  ),
                  tooltip: 'Centrar mapa',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 38,
                    minHeight: 38,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.flush) return map;

    return ClipRRect(
      borderRadius: Brand.cardRadius,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: Brand.cardRadius,
          border: Border.all(color: colors.border),
        ),
        child: map,
      ),
    );
  }

  void _fitAll() {
    final points = [
      for (final marker in widget.markers) marker.point,
      if (widget.userPoint != null) widget.userPoint!,
      ...?widget.route?.points,
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      _move(points.first, _detailZoom);
      return;
    }
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  Marker _marker(TotoMapMarker marker) {
    final selected = marker.selected || marker.id == widget.selectedId;
    return Marker(
      point: marker.point,
      width: 42,
      height: 42,
      child: GestureDetector(
        onTap: widget.onMarkerTap == null
            ? null
            : () => widget.onMarkerTap!(marker),
        child: Semantics(
          label: marker.label,
          button: widget.onMarkerTap != null,
          child: Container(
            decoration: BoxDecoration(
              color: selected ? Brand.ovenOrange : Brand.signMaroon,
              shape: BoxShape.circle,
              border: Border.all(color: Brand.boneWhite, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              switch (marker.kind) {
                TotoMapMarkerKind.branch => Icons.local_pizza_rounded,
                TotoMapMarkerKind.delivery => Icons.home_rounded,
                TotoMapMarkerKind.search => Icons.location_on_rounded,
              },
              color: Brand.boneWhite,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip flotante con distancia y tiempo de la ruta.
class MapInfoChip extends StatelessWidget {
  const MapInfoChip({super.key, required this.label, this.iconAsset});

  final String label;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Brand.s10,
        vertical: Brand.s4,
      ),
      decoration: BoxDecoration(
        color: colors.bar.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null)
            SvgPicture.asset(
              iconAsset!,
              width: 14,
              height: 14,
              colorFilter: ColorFilter.mode(colors.onBar, BlendMode.srcIn),
            )
          else
            Icon(Icons.route_rounded, size: 14, color: colors.onBar),
          const SizedBox(width: Brand.s4),
          Text(
            label,
            style: Brand.ui(
              11,
              weight: FontWeight.w700,
              color: colors.onBar,
            ),
          ),
        ],
      ),
    );
  }
}
