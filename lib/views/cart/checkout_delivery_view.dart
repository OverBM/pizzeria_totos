import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/branch_controller.dart';
import '../../controllers/checkout_controller.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../models/branch.dart';
import '../../models/checkout_step.dart';
import '../../models/delivery_quote.dart';
import '../../models/order.dart';
import '../../services/location/location_service.dart';
import '../../services/maps/maps_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/widgets.dart';
import '../branches/branch_detail_sheet.dart';
import '../branches/branch_route_view.dart';
import '../common/address_search_sheet.dart';
import '../common/location_picker_map.dart';
import 'checkout_navigation.dart';
import 'delivery_map_picker.dart';

/// Paso 2 del checkout: tipo de entrega, sede, dirección y punto.
class CheckoutDeliveryView extends StatefulWidget {
  const CheckoutDeliveryView({super.key});

  @override
  State<CheckoutDeliveryView> createState() => _CheckoutDeliveryViewState();
}

class _CheckoutDeliveryViewState extends State<CheckoutDeliveryView> {
  bool _locating = false;
  LatLng? _userPoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CheckoutController>().quoteDelivery();
    });
  }

  Future<void> _useLocation() async {
    setState(() => _locating = true);
    final location = context.read<LocationService>();
    final result = await location.current();
    if (!mounted) return;
    setState(() => _locating = false);
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result.failure?.message ?? 'No pudimos obtener tu ubicación.',
            ),
          ),
        );
      if (result.failure == LocationFailure.permissionDeniedForever) {
        await location.openSettings();
      }
      return;
    }
    final point = result.point!;
    setState(() => _userPoint = point);
    context.read<CheckoutController>().setDeliveryPoint(
      DeliveryPoint(
        lat: point.latitude,
        lng: point.longitude,
        label: 'Mi ubicación',
      ),
    );
  }

  Future<void> _searchAddress() async {
    final place = await showModalBottomSheet<PlaceResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddressSearchSheet(),
    );
    if (place == null || !mounted) return;
    context.read<CheckoutController>().setDeliveryPoint(
      DeliveryPoint(
        lat: place.point.latitude,
        lng: place.point.longitude,
        label: place.label,
      ),
    );
  }

  Future<void> _openMapPicker() async {
    final checkout = context.read<CheckoutController>();
    final point = await Navigator.of(context).push<DeliveryPoint>(
      MaterialPageRoute(
        builder: (_) => LocationPickerMap(
          initialPoint: checkout.deliveryPoint,
          initialLabel: checkout.deliveryAddressLabel,
          title: 'Punto de entrega',
        ),
      ),
    );
    if (point == null || !mounted) return;
    checkout.setDeliveryPoint(point);
  }

  Future<void> _openBranchDetail(Branch branch) async {
    final settings = context.read<SettingsService>();
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BranchDetailSheet(
        branch: branch,
        phoneFallback: settings.phone,
        whatsappFallback: settings.whatsapp,
        showMapButton: false,
        onDirections: () {
          Navigator.of(context).pop();
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  BranchRouteView(branch: branch, initialUserPoint: _userPoint),
            ),
          );
        },
      ),
    );
  }

  void _continue() {
    final checkout = context.read<CheckoutController>();
    final issues = checkout.validateStep(CheckoutStep.entrega);
    if (issues.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(issues.first.message)));
      return;
    }
    checkout.reachStep(CheckoutStep.confirmar);
    Navigator.of(context).push(AppRoutes.checkoutConfirm());
  }

  @override
  Widget build(BuildContext context) {
    final checkout = context.watch<CheckoutController>();
    final branches = context.watch<BranchController>();
    final auth = context.watch<AuthController>();
    final colors = context.colors;
    final branch = checkout.selectedBranch;
    final delivery = checkout.type == OrderType.delivery;

    return Scaffold(
      appBar: TotoTopBar(
        showWordmark: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Brand.s16,
              0,
              Brand.s16,
              Brand.s12,
            ),
            child: CheckoutProgress(
              step: CheckoutStep.entrega,
              maxStep: checkout.maxStep,
              onSelect: (step) => goToCheckoutStep(context, step),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                Brand.s16,
                Brand.s16,
                Brand.s16,
                Brand.s80,
              ),
              children: [
                Text(
                  'PASO 2 DE 3',
                  style: Brand.ui(
                    10,
                    weight: FontWeight.w700,
                    color: colors.action,
                  ),
                ),
                const SizedBox(height: Brand.s4),
                Text(
                  'ENTREGA',
                  style: Brand.display(28, h: 1, color: colors.textPrimary),
                ),
                const SizedBox(height: Brand.s20),
                const SectionHeading(eyebrow: 'Tipo', title: 'Cómo lo recibes'),
                const SizedBox(height: Brand.s12),
                Wrap(
                  spacing: Brand.s8,
                  runSpacing: Brand.s8,
                  children: [
                    FilterPill(
                      label: 'DELIVERY',
                      selected: delivery,
                      onTap: branch != null && !branch.delivers
                          ? null
                          : () => checkout.setType(OrderType.delivery),
                    ),
                    FilterPill(
                      label: 'RECOJO EN TIENDA',
                      selected: !delivery,
                      onTap: () => checkout.setType(OrderType.pickup),
                    ),
                  ],
                ),
                const SizedBox(height: Brand.s20),
                const SectionHeading(eyebrow: 'Sede', title: 'De dónde sale'),
                const SizedBox(height: Brand.s12),
                if (branches.branches.isEmpty)
                  Text(
                    'No hay sedes disponibles para elegir.',
                    style: context.text.bodySm,
                  )
                else
                  Wrap(
                    spacing: Brand.s8,
                    runSpacing: Brand.s8,
                    children: [
                      for (final item in branches.branches)
                        FilterPill(
                          label: item.name,
                          selected: branch?.id == item.id,
                          onTap: () {
                            checkout.selectBranch(item.id);
                            _openBranchDetail(item);
                          },
                        ),
                    ],
                  ),
                if (branch != null) ...[
                  const SizedBox(height: Brand.s8),
                  Text(
                    '${branch.name} · ${branch.address}',
                    style: context.text.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    'Horario ${branch.hours.rangeLabel}',
                    style: context.text.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                if (delivery) ...[
                  const SizedBox(height: Brand.s20),
                  const SectionHeading(
                    eyebrow: 'Dirección',
                    title: 'Dónde entregamos',
                  ),
                  const SizedBox(height: Brand.s12),
                  if (!auth.isSignedIn)
                    Text(
                      'Inicia sesión para usar tus direcciones guardadas. '
                      'También puedes elegir el punto en el mapa.',
                      style: context.text.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    )
                  else if (auth.account?.addresses.isNotEmpty ?? false)
                    Column(
                      children: [
                        for (final address in auth.account!.addresses) ...[
                          _AddressOption(
                            icon: Icons.home_rounded,
                            title: address.title.toUpperCase(),
                            subtitle: address.line,
                            selected:
                                checkout.selectedAddress?.id == address.id,
                            onTap: () => checkout.selectAddress(address.id),
                          ),
                          const SizedBox(height: Brand.s8),
                        ],
                        _AddressOption(
                          icon: Icons.map_outlined,
                          title: 'OTRO PUNTO EN EL MAPA',
                          subtitle:
                              'Quita la dirección y elige otra ubicación.',
                          selected: checkout.selectedAddress == null,
                          onTap: checkout.clearAddress,
                        ),
                      ],
                    )
                  else
                    Text(
                      'No tienes direcciones guardadas. Elige el punto en el '
                      'mapa.',
                      style: context.text.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  if (checkout.isResolvingAddress) ...[
                    const SizedBox(height: Brand.s8),
                    Row(
                      children: [
                        const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: Brand.s8),
                        Expanded(
                          child: Text(
                            'Ubicando la dirección en el mapa…',
                            style: context.text.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (checkout.addressError != null) ...[
                    const SizedBox(height: Brand.s8),
                    Text(
                      checkout.addressError!,
                      style: context.text.caption.copyWith(
                        color: colors.action,
                      ),
                    ),
                  ],
                  const SizedBox(height: Brand.s12),
                  PillButton(
                    label: 'ABRIR MAPA',
                    icon: Icons.map_outlined,
                    filled: false,
                    expanded: true,
                    onPressed: _openMapPicker,
                  ),
                  const SizedBox(height: Brand.s12),
                  DeliveryMapPicker(
                    point: checkout.deliveryPoint,
                    branchPoint: branch == null
                        ? null
                        : LatLng(branch.lat, branch.lng),
                    userPoint: _userPoint,
                    route: checkout.deliveryRoute,
                    quote: checkout.deliveryQuote,
                    chargedFeeSoles: checkout.shippingSoles,
                    included: checkout.subscriptionBenefitApplies,
                    quoting: checkout.isQuoting,
                    locating: _locating,
                    error: checkout.routeError,
                    onMapTap: (point) => checkout.setDeliveryPoint(
                      DeliveryPoint(
                        lat: point.latitude,
                        lng: point.longitude,
                        label: 'Punto seleccionado',
                      ),
                    ),
                    onSearch: _searchAddress,
                    onUseLocation: _useLocation,
                    onRetry: checkout.quoteDelivery,
                  ),
                ] else ...[
                  const SizedBox(height: Brand.s20),
                  DeliveryQuoteCard(quote: DeliveryQuote.pickup),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(
            Brand.s16,
            Brand.s8,
            Brand.s16,
            Brand.s8,
          ),
          child: PillButton(
            label: 'CONTINUAR AL PAGO',
            expanded: true,
            showArrow: true,
            onPressed: _continue,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta seleccionable de dirección, con el mismo lenguaje que el perfil.
class _AddressOption extends StatelessWidget {
  const _AddressOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: selected
            ? colors.action.withValues(alpha: 0.06)
            : colors.surface,
        borderRadius: Brand.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: Brand.cardRadius,
          child: Container(
            padding: const EdgeInsets.all(Brand.s12),
            decoration: BoxDecoration(
              borderRadius: Brand.cardRadius,
              border: Border.all(
                color: selected ? colors.action : colors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? colors.action : colors.textSecondary,
                ),
                const SizedBox(width: Brand.s10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Brand.ui(11, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: Brand.s2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Brand.s8),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 18,
                  color: selected ? colors.action : colors.border,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
