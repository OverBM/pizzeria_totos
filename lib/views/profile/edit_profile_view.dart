import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../core/validation/validators.dart';
import '../../widgets/widgets.dart';

/// Pantalla dedicada a editar nombre y teléfono del perfil.
class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final String _email;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final account = context.read<AuthController>().account;
    _name = TextEditingController(text: account?.name ?? '');
    _phone = TextEditingController(
      text: Validators.phoneDigits(account?.phone ?? ''),
    );
    _email = account?.email ?? '';
    _name.addListener(_markDirty);
    _phone.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmDiscard();
        if (leave && mounted) Navigator.of(this.context).pop();
      },
      child: Scaffold(
        appBar: TotoTopBar(
          showWordmark: false,
          leading: IconButton(
            onPressed: () async {
              if (!_dirty) {
                Navigator.of(context).maybePop();
                return;
              }
              final leave = await _confirmDiscard();
              if (leave && context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Volver',
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Brand.s16,
                Brand.s24,
                Brand.s16,
                Brand.s24,
              ),
              children: [
                Center(
                  child: ProfileChip(
                    name: _name.text.isEmpty ? 'Tu perfil' : _name.text,
                    subtitle: _email,
                    avatarSize: 56,
                  ),
                ),
                const SizedBox(height: Brand.s24),
                Text(
                  'DATOS PERSONALES',
                  style: Brand.ui(
                    11,
                    weight: FontWeight.w700,
                    color: colors.action,
                  ),
                ),
                const SizedBox(height: Brand.s12),
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixText: '+51 ',
                    helperText: 'Aún no verificado',
                    hintText: '999 111 222',
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
                      Expanded(child: Text(_email)),
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Brand.s8),
                Text(
                  'El correo no se puede cambiar desde la app.',
                  style: context.text.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: Brand.s24),
                PillButton(
                  label: _saving ? 'GUARDANDO…' : 'GUARDAR CAMBIOS',
                  expanded: true,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('DESCARTAR CAMBIOS'),
        content: const Text('¿Quieres salir sin guardar los cambios?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('SEGUIR EDITANDO'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('DESCARTAR'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final auth = context.read<AuthController>();
    final ok = await auth.updateProfile(
      name: _name.text.trim(),
      phone: Validators.phoneDigits(_phone.text),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'No se pudo guardar.')),
      );
      return;
    }
    _dirty = false;
    Navigator.of(context).pop(true);
  }
}
