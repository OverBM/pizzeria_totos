import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../controllers/branch_controller.dart';
import '../../core/format/money.dart';
import '../../core/geo/geo.dart';
import '../../core/load_state.dart';
import '../../core/theme/brand.dart';
import '../../widgets/widgets.dart';
import '../../core/theme/theme_context.dart';
import '../../core/time/lima_time.dart';
import '../../models/branch.dart';
import '../../services/contact_launcher.dart';
import '../../services/maps/maps_service.dart';
import '../../services/settings_service.dart';
import 'branch_detail_sheet.dart';

/// Sedes de Huancayo con mapa real, búsqueda y acciones de contacto.
class BranchesView extends StatefulWidget {
  const BranchesView({super.key});

  @override
  State<BranchesView> createState() => _BranchesViewState();
}

class _BranchesViewState extends State<BranchesView> {
  static const String _focusMarkerId = '__busqueda';

  final TextEditingController _query = TextEditingController();
  Timer? _debounce;
  int _searchSeq = 0;

  List<PlaceResult> _places = const [];
  PlaceResult? _focus;
  String? _selectedId;
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    setState(() {
      if (query.length < 4) {
        _places = const [];
        _searching = false;
      }
    });
    if (query.length < 4) return;
    _debounce = Timer(
      const Duration(milliseconds: 650),
      () => _searchPlaces(query),
    );
  }

  Future<void> _searchPlaces(String query) async {
    final seq = ++_searchSeq;
    setState(() => _searching = true);
    final results = await mapsService.search(query, limit: 4);
    if (!mounted || seq != _searchSeq) return;
    setState(() {
      _places = results;
      _searching = false;
    });
  }

  void _pickPlace(PlaceResult place) {
    final nearest = _nearestBranch(place.point);
    setState(() {
      _focus = place;
      _places = const [];
      _selectedId = nearest?.id;
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchSeq++;
    _query.clear();
    setState(() {
      _places = const [];
      _focus = null;
      _selectedId = null;
      _searching = false;
    });
  }

  Future<void> _openBranch(Branch branch, {double? distance}) async {
    final settings = context.read<SettingsService>();
    final goToMap = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BranchDetailSheet(
        branch: branch,
        phoneFallback: settings.phone,
        whatsappFallback: settings.whatsapp,
        distanceLabel: distance == null ? null : 'A ${_distanceText(distance)}',
      ),
    );
    if (!mounted || goToMap != true) return;
    setState(() => _selectedId = branch.id);
  }

  Branch? _nearestBranch(LatLng point) {
    Branch? nearest;
    var best = double.infinity;
    for (final branch in context.read<BranchController>().branches) {
      final distance = Geo.distanceKm(
        point.latitude,
        point.longitude,
        branch.lat,
        branch.lng,
      );
      if (distance < best) {
        best = distance;
        nearest = branch;
      }
    }
    return nearest;
  }

  double? _distanceTo(Branch branch) {
    final focus = _focus;
    if (focus == null) return null;
    return Geo.distanceKm(
      focus.point.latitude,
      focus.point.longitude,
      branch.lat,
      branch.lng,
    );
  }

  /// Filtra por nombre, distrito o dirección; si la búsqueda es una dirección
  /// que no coincide con ninguna sede, deja la lista completa.
  List<Branch> _visibleBranches(List<Branch> branches) {
    final query = _query.text.trim().toLowerCase();
    if (query.isEmpty) return branches;
    final matches = branches
        .where(
          (branch) => '${branch.name} ${branch.district} ${branch.address}'
              .toLowerCase()
              .contains(query),
        )
        .toList();
    return matches.isEmpty ? branches : matches;
  }

  String _distanceText(double km) => km < 1
      ? '${(km * 1000).round()} m'
      : '${km.toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BranchController>();
    final settings = Provider.of<SettingsService>(context, listen: false);

    if (controller.state == LoadState.loading && controller.isEmpty) {
      return const SingleChildScrollView(
        child: SkeletonList(count: 3, height: 230),
      );
    }

    if (controller.isEmpty) {
      return SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: EmptyState(
            title: controller.state == LoadState.error
                ? 'No pudimos cargar las sedes'
                : 'No hay sedes publicadas',
            message:
                controller.error ??
                'Estamos actualizando nuestras sedes de Huancayo. '
                    'Vuelve a intentarlo en un momento.',
            icon: controller.state == LoadState.error
                ? Icons.wifi_off_rounded
                : Icons.location_off_outlined,
            onAction: controller.load,
          ),
        ),
      );
    }

    final branches = controller.branches;
    final visible = _visibleBranches(branches);
    final now = LimaTime.now();
    final focus = _focus;
    final nearest = focus == null ? null : _nearestBranch(focus.point);

    final markers = <TotoMapMarker>[
      for (final branch in branches)
        TotoMapMarker(
          id: branch.id,
          point: LatLng(branch.lat, branch.lng),
          label: branch.name,
          selected: branch.id == _selectedId,
        ),
      if (focus != null)
        TotoMapMarker(
          id: _focusMarkerId,
          point: focus.point,
          label: 'Dirección buscada',
          selected: true,
        ),
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Brand.s16,
              Brand.s24,
              Brand.s16,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '‹ DÓNDE ESTAMOS ›',
                  style: Brand.ui(
                    11,
                    weight: FontWeight.w700,
                    color: context.colors.action,
                  ),
                ),
                const SizedBox(height: Brand.s4),
                const OutlinedDisplayTitle('SEDES', size: 40),
                const SizedBox(height: Brand.s8),
                Text(
                  'Cuatro puntos en la provincia de Huancayo. Toca un pin o '
                  'busca tu dirección para saber qué sede te atiende.',
                  style: context.text.bodySm.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Brand.s16,
              Brand.s16,
              Brand.s16,
              0,
            ),
            child: TotoMap(
              markers: markers,
              focus: focus?.point,
              selectedId: _selectedId,
              height: 250,
              onMarkerTap: (marker) {
                if (marker.id == _focusMarkerId) return;
                for (final branch in branches) {
                  if (branch.id == marker.id) {
                    setState(() => _selectedId = branch.id);
                    _openBranch(branch, distance: _distanceTo(branch));
                    break;
                  }
                }
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Brand.s16,
              Brand.s12,
              Brand.s16,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _query,
                  onChanged: _onQueryChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Buscar sede o dirección',
                    hintText: 'Av. Giráldez 123, El Tambo…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_query.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: _clearSearch,
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: 'Limpiar búsqueda',
                                )),
                  ),
                ),
                if (_places.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: Brand.s8),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: Brand.cardRadius,
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Column(
                      children: [
                        for (final place in _places)
                          _PlaceRow(
                            place: place,
                            onTap: () => _pickPlace(place),
                          ),
                      ],
                    ),
                  ),
                if (nearest != null)
                  Container(
                    margin: const EdgeInsets.only(top: Brand.s12),
                    padding: const EdgeInsets.fromLTRB(
                      Brand.s12,
                      Brand.s4,
                      Brand.s4,
                      Brand.s4,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: Brand.cardRadius,
                      border: Border.all(
                        color: context.colors.action,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.near_me_rounded,
                          size: 18,
                          color: context.colors.action,
                        ),
                        const SizedBox(width: Brand.s8),
                        Expanded(
                          child: Text(
                            'La sede más cercana es ${nearest.name} · '
                            '${_distanceText(_distanceTo(nearest) ?? 0)}',
                            style: context.text.bodySm,
                          ),
                        ),
                        IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          tooltip: 'Quitar búsqueda',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(Brand.s16),
          sliver: SliverList.separated(
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: Brand.s12),
            itemBuilder: (context, index) {
              final branch = visible[index];
              final open = branch.isOpenAt(now);
              final distance = _distanceTo(branch);
              return BranchMapCard(
                name: branch.name,
                address: branch.address,
                statusLabel: open ? 'ABIERTA' : 'CERRADA',
                open: open,
                selected: branch.id == _selectedId,
                onSelect: () => setState(() => _selectedId = branch.id),
                thumbnail: IgnorePointer(
                  child: TotoMap(
                    markers: [
                      TotoMapMarker(
                        id: branch.id,
                        point: LatLng(branch.lat, branch.lng),
                        label: branch.name,
                      ),
                    ],
                    height: 140,
                    initialZoom: 15.5,
                    interactive: false,
                    showFitButton: false,
                    flush: true,
                  ),
                ),
                hoursLabel: branch.hours.rangeLabel,
                distanceLabel: distance == null
                    ? null
                    : 'A ${_distanceText(distance)} de la dirección buscada',
                deliveryLabel: branch.delivers
                    ? 'Delivery · envío ${Money.format(branch.deliveryFeeSoles)}'
                    : 'Solo recojo en tienda',
                onCall: () => ContactLauncher.call(
                  branch.phone.isEmpty ? settings.phone : branch.phone,
                ),
                onWhatsapp: () => ContactLauncher.whatsapp(
                  phone: branch.whatsapp.isEmpty
                      ? settings.whatsapp
                      : branch.whatsapp,
                  message:
                      'Hola TOTO\'S, quiero hacer un pedido en la sede '
                      '${branch.name}.',
                ),
                onMap: () => ContactLauncher.openMap(
                  branch.lat,
                  branch.lng,
                  label: 'TOTO\'S ${branch.name}',
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Brand.s24)),
      ],
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place, required this.onTap});
  final PlaceResult place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Brand.s12,
          vertical: Brand.s10,
        ),
        child: Row(
          children: [
            Icon(Icons.place_outlined, size: 18, color: colors.action),
            const SizedBox(width: Brand.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySm,
                  ),
                  if (place.detail != null)
                    Text(
                      place.detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
