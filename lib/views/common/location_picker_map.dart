import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../models/delivery_quote.dart';
import '../../services/location/location_service.dart';
import '../../services/maps/maps_service.dart';
import '../../widgets/widgets.dart';
import '../common/address_search_sheet.dart';

/// Selector de punto de entrega a pantalla completa.
class LocationPickerMap extends StatefulWidget {
  const LocationPickerMap({
    super.key,
    this.initialPoint,
    this.initialLabel,
    this.title = 'Elige el punto de entrega',
  });

  final DeliveryPoint? initialPoint;
  final String? initialLabel;
  final String title;

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late LatLng _point;
  late String _label;
  LatLng? _userPoint;
  bool _loadingLocation = false;
  bool _resolving = false;
  String? _error;
  Timer? _debounce;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _point = widget.initialPoint?.latLng ?? huancayoCenter;
    _label = widget.initialLabel ?? widget.initialPoint?.label ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _movePin(LatLng point) {
    setState(() {
      _point = point;
      _label = '';
      _error = null;
    });
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _reverse(point),
    );
  }

  Future<void> _reverse(LatLng point) async {
    final seq = ++_seq;
    setState(() => _resolving = true);
    final place = await mapsService.reverse(point);
    if (!mounted || seq != _seq) return;
    setState(() {
      _resolving = false;
      if (place != null) _label = place.label;
    });
  }

  Future<void> _useCurrentLocation() async {
    final location = context.read<LocationService>();
    setState(() {
      _loadingLocation = true;
      _error = null;
    });
    final result = await location.current();
    if (!mounted) return;
    if (result.isSuccess) {
      final point = result.point!;
      setState(() {
        _loadingLocation = false;
        _userPoint = point;
        _point = point;
        _label = 'Mi ubicación';
      });
      await _reverse(point);
      return;
    }
    setState(() {
      _loadingLocation = false;
      _error = result.failure?.message ?? 'No pudimos obtener tu ubicación.';
    });
    if (result.failure == LocationFailure.permissionDeniedForever) {
      await _offerSettings(location);
    }
  }

  Future<void> _offerSettings(LocationService location) async {
    if (!mounted) return;
    final open = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('PERMISO DE UBICACIÓN'),
        content: const Text(
          'Abre los ajustes del sistema para permitir la ubicación y volver '
          'a intentarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ABRIR AJUSTES'),
          ),
        ],
      ),
    );
    if (open == true) await location.openSettings();
  }

  Future<void> _search() async {
    final place = await showModalBottomSheet<PlaceResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddressSearchSheet(),
    );
    if (place == null || !mounted) return;
    setState(() {
      _point = place.point;
      _label = place.label;
      _error = null;
    });
  }

  void _confirm() {
    Navigator.of(context).pop(
      DeliveryPoint(
        lat: _point.latitude,
        lng: _point.longitude,
        label: _label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.bar,
        foregroundColor: colors.onBar,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                TotoMap(
                  markers: [
                    TotoMapMarker(
                      id: 'delivery',
                      point: _point,
                      label: 'Punto de entrega',
                      selected: true,
                      kind: TotoMapMarkerKind.delivery,
                    ),
                  ],
                  focus: _point,
                  userPoint: _userPoint,
                  onMapTap: _movePin,
                  initialZoom: 15,
                  showFitButton: false,
                  expand: true,
                ),
                Positioned(
                  left: Brand.s16,
                  right: Brand.s16,
                  top: Brand.s16,
                  child: Material(
                    color: colors.surface.withValues(alpha: 0.94),
                    borderRadius: Brand.cardRadius,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Brand.s12,
                        vertical: Brand.s8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: colors.action,
                          ),
                          const SizedBox(width: Brand.s8),
                          Expanded(
                            child: Text(
                              _label.isEmpty
                                  ? 'Toca el mapa para mover el pin'
                                  : _label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySm,
                            ),
                          ),
                          if (_resolving)
                            const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colors.canvas,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Brand.s16,
                  Brand.s8,
                  Brand.s16,
                  Brand.s12 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: Brand.s12),
                    Text(
                      'TU PUNTO DE PARTIDA',
                      style: Brand.display(
                        18,
                        h: 1,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: Brand.s4),
                    Text(
                      _label.isEmpty
                          ? 'Toca el mapa o busca una dirección.'
                          : _label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: Brand.s12),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: context.text.caption.copyWith(
                          color: colors.action,
                        ),
                      ),
                      const SizedBox(height: Brand.s8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: PillButton(
                            label: 'BUSCAR DIRECCIÓN',
                            filled: false,
                            onPressed: _search,
                          ),
                        ),
                        const SizedBox(width: Brand.s8),
                        Expanded(
                          child: PillButton(
                            label: _loadingLocation
                                ? 'UBICANDO…'
                                : 'USAR MI UBICACIÓN',
                            filled: false,
                            onPressed: _loadingLocation
                                ? null
                                : _useCurrentLocation,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Brand.s8),
                    PillButton(
                      label: 'USAR ESTE PUNTO',
                      expanded: true,
                      showArrow: true,
                      onPressed: _confirm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
