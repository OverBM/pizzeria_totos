import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../models/branch.dart';
import '../../models/delivery_quote.dart';
import '../../services/contact_launcher.dart';
import '../../services/location/location_service.dart';
import '../../services/maps/maps_service.dart';
import '../../widgets/widgets.dart';
import '../common/location_picker_map.dart';

/// Ruta en la app desde la ubicación del usuario hasta una sede.
class BranchRouteView extends StatefulWidget {
  const BranchRouteView({
    super.key,
    required this.branch,
    this.initialUserPoint,
  });

  final Branch branch;
  final LatLng? initialUserPoint;

  @override
  State<BranchRouteView> createState() => _BranchRouteViewState();
}

class _BranchRouteViewState extends State<BranchRouteView> {
  LatLng? _userPoint;
  MapRoute? _route;
  bool _loading = true;
  String? _error;

  LatLng get _branchPoint => LatLng(widget.branch.lat, widget.branch.lng);

  @override
  void initState() {
    super.initState();
    _userPoint = widget.initialUserPoint;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_userPoint != null) {
        _routeFrom(_userPoint!);
      } else {
        _locate();
      }
    });
  }

  Future<void> _locate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await context.read<LocationService>().current();
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() {
        _loading = false;
        _error = result.failure?.message ?? 'No pudimos obtener tu ubicación.';
      });
      return;
    }
    await _routeFrom(result.point!);
  }

  Future<void> _routeFrom(LatLng point) async {
    setState(() {
      _loading = true;
      _error = null;
      _userPoint = point;
    });
    final route = await mapsService.route(point, _branchPoint);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _route = route.isEmpty ? null : route;
      if (route.isEmpty) {
        _error = 'No pudimos calcular la ruta. Revisa tu conexión e inténtalo '
            'de nuevo.';
      }
    });
  }

  Future<void> _pickPoint() async {
    final point = await Navigator.of(context).push<DeliveryPoint>(
      MaterialPageRoute(
        builder: (_) => LocationPickerMap(
          initialPoint: _userPoint == null
              ? null
              : DeliveryPoint(
                  lat: _userPoint!.latitude,
                  lng: _userPoint!.longitude,
                  label: 'Tu punto de partida',
                ),
          title: 'Tu punto de partida',
        ),
      ),
    );
    if (point == null || !mounted) return;
    await _routeFrom(point.latLng);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final route = _route;
    return Scaffold(
      appBar: TotoTopBar(
        showWordmark: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      TotoMap(
                        markers: [
                          TotoMapMarker(
                            id: widget.branch.id,
                            point: _branchPoint,
                            label: widget.branch.name,
                            selected: true,
                          ),
                        ],
                        userPoint: _userPoint,
                        route: route,
                        focus: _userPoint ?? _branchPoint,
                        initialZoom: 14,
                        showFitButton: true,
                        autoFitRoute: true,
                        expand: true,
                      ),
                      if (route != null)
                        Positioned(
                          left: Brand.s8,
                          top: Brand.s8,
                          child: MapInfoChip(
                            label:
                                '${route.distanceKm.toStringAsFixed(1)} km · '
                                '~${route.durationMinutes} min',
                          ),
                        ),
                      if (_error != null)
                        Positioned(
                          left: Brand.s16,
                          right: Brand.s16,
                          bottom: Brand.s16,
                          child: Container(
                            padding: const EdgeInsets.all(Brand.s12),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: Brand.cardRadius,
                              border: Border.all(color: colors.action),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _error!,
                                  style: context.text.bodySm,
                                ),
                                const SizedBox(height: Brand.s8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: PillButton(
                                        label: 'REINTENTAR',
                                        onPressed: _locate,
                                      ),
                                    ),
                                    const SizedBox(width: Brand.s8),
                                    Expanded(
                                      child: PillButton(
                                        label: 'ELEGIR PUNTO',
                                        filled: false,
                                        onPressed: _pickPoint,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (route != null && _error == null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _routeCard(context, route),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _routeCard(BuildContext context, MapRoute route) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Brand.s16,
            Brand.s12,
            Brand.s16,
            Brand.s12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.branch.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.display(
                        20,
                        h: 1,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Brand.s2),
              Text(
                widget.branch.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: Brand.s8),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'GOOGLE MAPS',
                      filled: false,
                      onPressed: () => ContactLauncher.openMap(
                        widget.branch.lat,
                        widget.branch.lng,
                        label: "TOTO'S ${widget.branch.name}",
                      ),
                    ),
                  ),
                  const SizedBox(width: Brand.s8),
                  Expanded(
                    child: PillButton(
                      label: 'CAMBIAR PUNTO',
                      filled: false,
                      onPressed: _pickPoint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
