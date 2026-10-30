part of '../widgets.dart';

/// Marcador del mapa de sedes.
class TotoMapMarker {
  const TotoMapMarker({
    required this.id,
    required this.point,
    required this.label,
    this.selected = false,
  });

  final String id;
  final LatLng point;
  final String label;
  final bool selected;
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
  });

  final List<TotoMapMarker> markers;

  /// Punto al que se desplaza el mapa cuando cambia (búsqueda de dirección).
  final LatLng? focus;

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
        (widget.markers.isEmpty
            ? huancayoCenter
            : widget.markers.first.point);

    final map = SizedBox(
      height: widget.height,
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
            ),
            children: [
              TileLayer(
                urlTemplate: mapsService.tileUrlTemplate,
                userAgentPackageName: 'com.totos.pizzeria',
                maxNativeZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  for (final marker in widget.markers) _marker(marker),
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
          if (widget.showFitButton && widget.markers.length > 1)
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
                  tooltip: 'Ver todas las sedes',
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
    final points = [for (final marker in widget.markers) marker.point];
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
              selected
                  ? Icons.storefront_rounded
                  : Icons.local_pizza_rounded,
              color: Brand.boneWhite,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
