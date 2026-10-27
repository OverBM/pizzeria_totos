import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/app_info.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/components.dart';
import '../../core/theme/theme_context.dart';
import '../../core/validation/validators.dart';
import '../../models/account.dart';
import '../auth/login_view.dart';
import '../cart/orders_view.dart';
import '../common/offline_banner.dart';

/// Perfil del usuario: datos de contacto, direcciones e historial.
///
/// No existe rol, panel de administración ni conmutador de tema.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  /// `uid` con el que se llenaron los campos por última vez.
  String? _seededUid;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final account = context.read<AuthController>().account;
    if (account == null) {
      // Al cerrar sesión se olvida el sembrado para volver a llenar los campos
      // cuando entre otra cuenta.
      _seededUid = null;
      return;
    }
    if (_seededUid == account.uid) return;
    _name.text = account.name;
    _phone.text = account.phone;
    _seededUid = account.uid;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

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
            onAction: () =>
                Navigator.of(context)
                    .push<bool>(MotionRoute(builder: (_) => const LoginView())),
          ),
          _versionFooter(context),
        ],
      ),
    );
  }

  Widget _profile(BuildContext context, AuthController auth, Account account) {
    final colors = context.colors;
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
        Center(
          child: ProfileChip(
            name: account.name,
            subtitle: account.email,
            avatarSize: 56,
          ),
        ),
        const SizedBox(height: Brand.s16),
        SectionHeading(eyebrow: 'Tus datos', title: 'Contacto'),
        const SizedBox(height: Brand.s8),
        if (missing.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(Brand.s12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: Brand.cardRadius,
              border: Border.all(color: colors.action, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colors.action,
                ),
                const SizedBox(width: Brand.s8),
                Expanded(
                  child: Text(
                    'Para confirmar pedidos con delivery completa '
                    '${missing.join(' y ')}.',
                    style: context.text.bodySm,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Brand.s12),
        ],
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: Validators.nameError,
              ),
              const SizedBox(height: Brand.s12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono / WhatsApp',
                  hintText: '999 999 999',
                ),
                validator: Validators.phoneError,
              ),
              const SizedBox(height: Brand.s12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Brand.s16,
                  vertical: Brand.s12,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: Brand.buttonRadius,
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(account.email)),
                    Text(
                      'CUENTA',
                      style: Brand.ui(
                        9,
                        weight: FontWeight.w700,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Brand.s16),
              PillButton(
                label: _saving ? 'GUARDANDO…' : 'GUARDAR CAMBIOS',
                expanded: true,
                onPressed: _saving ? null : () => _save(auth),
              ),
            ],
          ),
        ),
        const SizedBox(height: Brand.s24),
        SectionHeading(
          eyebrow: 'Entrega',
          title: 'Tus direcciones',
          actionLabel: 'Agregar',
          onAction: () => _editAddress(auth, account, null),
        ),
        const SizedBox(height: Brand.s12),
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
                const SizedBox(height: Brand.s12),
                OutlinedButton.icon(
                  onPressed: () => _editAddress(auth, account, null),
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: const Text('AGREGAR DIRECCIÓN'),
                ),
              ],
            ),
          )
        else
          for (var i = 0; i < account.addresses.length; i++) ...[
            _addressTile(context, auth, account, account.addresses[i], i == 0),
            const SizedBox(height: Brand.s8),
          ],
        const SizedBox(height: Brand.s16),
        _linkTile(
          context,
          icon: Icons.receipt_long_outlined,
          label: 'Mis pedidos',
          onTap: () =>
              Navigator.of(context)
                  .push(MotionRoute(builder: (_) => const OrdersView())),
        ),
        const SizedBox(height: Brand.s24),
        Center(
          child: Text(
            "TOTO'S PIZZA · HUANCAYO",
            style: Brand.ui(
              9,
              weight: FontWeight.w700,
              color: colors.textDisabled,
            ),
          ),
        ),
        _versionFooter(context),
      ],
    );
  }

  /// Pie de versión: exactamente `V1.1.1`, sin número de build.
  ///
  /// Se pinta con y sin sesión para que cualquier beta tester pueda reportar
  /// la versión instalada.
  Widget _versionFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Brand.s8),
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
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  address.title.toUpperCase(),
                  style: Brand.ui(
                    12,
                    weight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (isDefault)
                StatusPill(
                  label: 'PREDETERMINADA',
                  filled: false,
                  color: colors.action,
                ),
            ],
          ),
          const SizedBox(height: Brand.s4),
          Text(address.line, style: context.text.bodySm),
          if (address.reference != null && address.reference!.isNotEmpty)
            Text(
              'Ref. ${address.reference}',
              style: context.text.caption.copyWith(color: colors.textSecondary),
            ),
          const SizedBox(height: Brand.s4),
          Wrap(
            spacing: Brand.s4,
            children: [
              if (!isDefault)
                TextButton(
                  onPressed: () => _makeDefault(auth, account, address),
                  child: const Text('PREDETERMINADA'),
                ),
              TextButton(
                onPressed: () => _editAddress(auth, account, address),
                child: const Text('EDITAR'),
              ),
              TextButton(
                onPressed: () => _deleteAddress(auth, account, address),
                child: const Text('ELIMINAR'),
              ),
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
            Icon(icon, size: 18, color: colors.textPrimary),
            const SizedBox(width: Brand.s8),
            Expanded(child: Text(label, style: context.text.bodySm)),
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

  Future<void> _save(AuthController auth) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final ok = await auth.updateProfile(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Perfil actualizado.' : auth.error ?? 'No se pudo guardar.',
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
                  decoration: const InputDecoration(
                    labelText: 'Dirección completa',
                    hintText: 'Calle, número, distrito',
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
