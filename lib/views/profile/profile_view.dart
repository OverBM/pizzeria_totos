import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../controllers/auth_controller.dart';
import '../../core/app_info.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../core/validation/validators.dart';
import '../../models/account.dart';
import '../../services/maps/maps_service.dart';
import '../../widgets/widgets.dart';
import '../auth/login_view.dart';
import '../cart/orders_view.dart';
import '../common/address_search_sheet.dart';
import 'edit_profile_view.dart';

/// Perfil del usuario: resumen, direcciones y accesos.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final account = auth.account;

    return Scaffold(
      appBar: TotoTopBar(
        showWordmark: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        actions: [
          if (auth.isSignedIn)
            IconButton(
              onPressed: _confirmSignOut,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar sesión',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: account == null
                  ? _signedOut(context)
                  : _profile(context, auth, account),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signedOut(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: Brand.s16),
      child: Column(
        children: [
          const SizedBox(height: Brand.s24),
          EmptyState(
            title: 'Tu perfil',
            message:
                'Inicia sesión para guardar tu teléfono y tus direcciones, '
                'y confirmar tus pedidos sin volver a escribirlos.',
            icon: Icons.person_outline_rounded,
            actionLabel: 'INICIAR SESIÓN',
            onAction: () => Navigator.of(
              context,
            ).push<bool>(MotionRoute(builder: (_) => const LoginView())),
          ),
          _versionFooter(context),
        ],
      ),
    );
  }

  Widget _profile(BuildContext context, AuthController auth, Account account) {
    final colors = context.colors;
    final done = [
      account.name.trim().isNotEmpty,
      account.hasPhone,
      account.hasAddress,
    ].where((value) => value).length;
    final missing = <String>[
      if (!account.hasPhone) 'tu teléfono',
      if (!account.hasAddress) 'una dirección de entrega',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Brand.s16,
        Brand.s24,
        Brand.s16,
        Brand.s24,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(Brand.s16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.surface, colors.bar],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                height: 64,
                width: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.action,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.action.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  account.name.trim().isEmpty
                      ? 'T'
                      : account.name.trim().substring(0, 1).toUpperCase(),
                  style: Brand.display(26, h: 1, color: colors.onAction),
                ),
              ),
              const SizedBox(width: Brand.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MI PERFIL',
                      style: Brand.ui(
                        9,
                        weight: FontWeight.w700,
                        color: colors.action,
                      ),
                    ),
                    const SizedBox(height: Brand.s2),
                    Text(
                      account.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Brand.display(
                        22,
                        h: 1,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: Brand.s2),
                    Text(
                      account.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _openEdit,
                tooltip: 'Editar perfil',
                style: IconButton.styleFrom(
                  backgroundColor: colors.action.withValues(alpha: 0.14),
                  foregroundColor: colors.action,
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: Brand.s16),
        Container(
          padding: const EdgeInsets.all(Brand.s12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: Brand.cardRadius,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Perfil $done de 3',
                    style: Brand.ui(11, weight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    missing.isEmpty ? 'Completo' : 'Falta completar',
                    style: context.text.caption.copyWith(
                      color: missing.isEmpty
                          ? colors.action
                          : colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Brand.s8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: done / 3,
                  minHeight: 6,
                  backgroundColor: colors.border,
                  color: colors.action,
                ),
              ),
              if (missing.isNotEmpty) ...[
                const SizedBox(height: Brand.s8),
                Text(
                  'Falta ${missing.join(' y ')}.',
                  style: context.text.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: Brand.s8),
                OutlinedButton(
                  onPressed: !account.hasAddress
                      ? () => _editAddress(auth, account, null)
                      : _openEdit,
                  child: Text(
                    !account.hasAddress
                        ? 'AGREGAR DIRECCIÓN'
                        : 'COMPLETAR TELÉFONO',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Brand.s24),
        _sectionTitle(context, 'DATOS'),
        const SizedBox(height: Brand.s8),
        _dataRow(
          context,
          'Nombre',
          account.name,
          icon: Icons.person_outline_rounded,
        ),
        _dataRow(
          context,
          'Teléfono',
          account.hasPhone ? _phoneLabel(account.phone) : 'Sin teléfono',
          helper: account.hasPhone ? 'Aún no verificado' : null,
          icon: Icons.phone_outlined,
        ),
        const SizedBox(height: Brand.s24),
        Row(
          children: [
            Expanded(child: _sectionTitle(context, 'DIRECCIONES')),
            TextButton.icon(
              onPressed: () => _editAddress(auth, account, null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('AGREGAR'),
            ),
          ],
        ),
        const SizedBox(height: Brand.s8),
        if (account.addresses.isEmpty)
          Container(
            padding: const EdgeInsets.all(Brand.s16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: Brand.cardRadius,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.location_off_outlined, color: colors.textSecondary),
                const SizedBox(height: Brand.s8),
                Text(
                  'Aún no tienes direcciones guardadas.',
                  textAlign: TextAlign.center,
                  style: context.text.bodySm,
                ),
              ],
            ),
          )
        else
          for (var i = 0; i < account.addresses.length; i++) ...[
            _addressTile(context, auth, account, account.addresses[i], i == 0),
            const SizedBox(height: Brand.s8),
          ],
        const SizedBox(height: Brand.s24),
        _sectionTitle(context, 'ACTIVIDAD'),
        const SizedBox(height: Brand.s8),
        _linkTile(
          context,
          icon: Icons.receipt_long_outlined,
          label: 'Mis pedidos',
          subtitle: 'Historial y estado de tus compras',
          onTap: () =>
              Navigator.of(context).push(MotionRoute(builder: (_) => const OrdersView())),
        ),
        const SizedBox(height: Brand.s8),
        _linkTile(
          context,
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Reclamos',
          subtitle: 'Enviar y revisar tus casos',
          onTap: () => Navigator.of(context).push(
            AppRoutes.claims(
              onOpenAuth: () => Navigator.of(
                context,
              ).push<bool>(MotionRoute(builder: (_) => const LoginView())),
            ),
          ),
        ),
        const SizedBox(height: Brand.s8),
        _linkTile(
          context,
          icon: Icons.local_offer_outlined,
          label: 'Promos',
          subtitle: 'Ofertas vigentes de la casa',
          onTap: () => Navigator.of(context).push(
            AppRoutes.promotions(
              onOpenProduct: (product, {variantLabel}) =>
                  Navigator.of(context).push(
                    AppRoutes.product(product, variantLabel: variantLabel),
                  ),
            ),
          ),
        ),
        const SizedBox(height: Brand.s24),
        Center(
          child: OutlinedButton(
            onPressed: _confirmSignOut,
            child: const Text('CERRAR SESIÓN'),
          ),
        ),
        _versionFooter(context),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String label) => Text(
    label,
    style: Brand.ui(
      10,
      weight: FontWeight.w700,
      color: context.colors.textSecondary,
    ),
  );

  Widget _dataRow(
    BuildContext context,
    String label,
    String value, {
    String? helper,
    IconData? icon,
  }) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: Brand.s8),
      padding: const EdgeInsets.symmetric(
        horizontal: Brand.s12,
        vertical: Brand.s10,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: colors.action.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: colors.action),
            ),
            const SizedBox(width: Brand.s8),
          ],
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: context.text.caption.copyWith(color: colors.textSecondary),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: context.text.bodySm),
                if (helper != null)
                  Text(
                    helper,
                    style: context.text.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _phoneLabel(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('51') ? digits.substring(2) : digits;
    if (local.length == 9) {
      return '+51 ${local.substring(0, 3)} ${local.substring(3, 6)} '
          '${local.substring(6)}';
    }
    return '+51 $local';
  }

  Widget _addressTile(
    BuildContext context,
    AuthController auth,
    Account account,
    Address address,
    bool isDefault,
  ) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(Brand.s12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(
          color: isDefault ? colors.action : colors.border,
          width: isDefault ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        address.title.toUpperCase(),
                        style: Brand.ui(12, weight: FontWeight.w700),
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: Brand.s8),
                      StatusPill(
                        label: 'PREDETERMINADA',
                        filled: false,
                        color: colors.action,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Brand.s4),
                Text(address.line, style: context.text.bodySm),
                if (address.reference != null &&
                    address.reference!.isNotEmpty)
                  Text(
                    'Ref. ${address.reference}',
                    style: context.text.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Acciones de ${address.title}',
            onSelected: (value) {
              switch (value) {
                case 'default':
                  _makeDefault(auth, account, address);
                case 'edit':
                  _editAddress(auth, account, address);
                case 'delete':
                  _deleteAddress(auth, account, address);
              }
            },
            itemBuilder: (_) => [
              if (!isDefault)
                const PopupMenuItem(
                  value: 'default',
                  child: Text('Hacer predeterminada'),
                ),
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linkTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return MotionPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Brand.s12,
          vertical: Brand.s12,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: Brand.cardRadius,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: colors.action.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: colors.action),
            ),
            const SizedBox(width: Brand.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Brand.ui(12, weight: FontWeight.w700),
                  ),
                  Text(
                    subtitle,
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

  void _openEdit() {
    Navigator.of(context).push(MotionRoute(builder: (_) => const EditProfileView()));
  }

  Widget _versionFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Brand.s16),
      child: Center(
        child: Text(
          AppInfo.label,
          style: Brand.ui(
            10,
            weight: FontWeight.w700,
            color: context.colors.textDisabled,
          ),
        ),
      ),
    );
  }

  Future<void> _editAddress(
    AuthController auth,
    Account account,
    Address? current,
  ) async {
    final address = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddressSheet(address: current),
    );
    if (address == null || !mounted) return;
    final next = current == null
        ? [...account.addresses, address]
        : account.addresses
              .map((a) => a.id == address.id ? address : a)
              .toList();
    final ok = await auth.updateProfile(addresses: next);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'No se pudo guardar.')),
      );
    }
  }

  Future<void> _makeDefault(
    AuthController auth,
    Account account,
    Address address,
  ) async {
    final next = [
      address,
      ...account.addresses.where((a) => a.id != address.id),
    ];
    final ok = await auth.updateProfile(addresses: next);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.error ?? 'No se pudo actualizar.')),
    );
  }

  Future<void> _deleteAddress(
    AuthController auth,
    Account account,
    Address address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ELIMINAR DIRECCIÓN'),
        content: Text('¿Eliminar «${address.title}» de tus direcciones?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await auth.removeAddress(address.id);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            auth.error ??
                'No se pudo eliminar la dirección. Inténtalo de nuevo.',
          ),
        ),
      );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('CERRAR SESIÓN'),
        content: const Text(
          'Tu perfil, tus pedidos y tus reclamos se conservan en tu cuenta. '
          'El carrito de este dispositivo no se borra.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('CERRAR SESIÓN'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = context.read<AuthController>();
    await auth.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

/// Hoja de edición de una dirección con etiqueta, línea y referencia.
class _AddressSheet extends StatefulWidget {
  const _AddressSheet({this.address});

  final Address? address;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label = TextEditingController(
    text: widget.address?.label ?? '',
  );
  late final TextEditingController _line = TextEditingController(
    text: widget.address?.line ?? '',
  );
  late final TextEditingController _reference = TextEditingController(
    text: widget.address?.reference ?? '',
  );

  @override
  void dispose() {
    _label.dispose();
    _line.dispose();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.address == null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Brand.s24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNew ? 'NUEVA DIRECCIÓN' : 'EDITAR DIRECCIÓN',
                  style: Brand.display(
                    22,
                    h: 1,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: Brand.s16),
                TextFormField(
                  controller: _label,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Etiqueta',
                    hintText: 'Casa, Trabajo…',
                  ),
                  validator: Validators.addressLabelError,
                ),
                const SizedBox(height: Brand.s12),
                TextFormField(
                  controller: _line,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Dirección completa',
                    hintText: 'Calle, número, distrito',
                    suffixIcon: IconButton(
                      onPressed: _searchAddress,
                      icon: const Icon(Icons.search_rounded),
                      tooltip: 'Buscar dirección',
                    ),
                  ),
                  validator: Validators.addressLineError,
                ),
                const SizedBox(height: Brand.s12),
                TextFormField(
                  controller: _reference,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Referencia (opcional)',
                    hintText: 'Frente al parque, portón negro…',
                  ),
                ),
                const SizedBox(height: Brand.s24),
                PillButton(
                  label: isNew ? 'GUARDAR DIRECCIÓN' : 'ACTUALIZAR',
                  expanded: true,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _searchAddress() async {
    final place = await showModalBottomSheet<PlaceResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddressSearchSheet(initialQuery: _line.text),
    );
    if (place == null || !mounted) return;
    setState(() => _line.text = place.label);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final reference = _reference.text.trim();
    Navigator.of(context).pop(
      Address(
        id: widget.address?.id ?? 'addr-$now',
        label: _label.text.trim(),
        line: _line.text.trim(),
        reference: reference.isEmpty ? null : reference,
        createdAt: widget.address?.createdAt ?? DateTime.now(),
      ),
    );
  }
}
