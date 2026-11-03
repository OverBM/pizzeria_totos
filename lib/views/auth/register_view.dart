import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/alias_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/theme/brand.dart';
import '../../widgets/widgets.dart';
import '../../core/theme/theme_context.dart';
import '../../core/validation/validators.dart';

/// Registro de una cuenta nueva en Firebase Authentication.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final colors = context.colors;
    return Scaffold(
      appBar: TotoTopBar(
        showWordmark: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(Brand.s16),
          child: MotionReveal(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '‹ TU CUENTA ›',
                  style: Brand.ui(
                    11,
                    weight: FontWeight.w700,
                    color: colors.action,
                  ),
                ),
                const SizedBox(height: Brand.s4),
                const OutlinedDisplayTitle('CREAR CUENTA', size: 34),
                const SizedBox(height: Brand.s8),
                Text(
                  'Solo necesitamos tu nombre y un correo. El teléfono y las '
                  'direcciones los completas en tu perfil.',
                  style: context.text.bodySm.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: Brand.s24),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nombre y apellido',
                        ),
                        validator: Validators.nameError,
                      ),
                      const SizedBox(height: Brand.s12),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          hintText: 'tucorreo@ejemplo.com',
                        ),
                        validator: Validators.emailError,
                      ),
                      const SizedBox(height: Brand.s12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          helperText:
                              'Mínimo ${Validators.passwordMinLength} caracteres, '
                              'con mayúscula y minúscula.',
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            tooltip: _obscure
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                          ),
                        ),
                        validator: Validators.passwordError,
                      ),
                      _PasswordChecklist(
                        password: _password.text,
                        confirmation: _confirm.text,
                      ),
                      const SizedBox(height: Brand.s12),
                      TextFormField(
                        controller: _confirm,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {}),
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Repite tu contraseña',
                        ),
                        validator: (value) =>
                            Validators.confirmPasswordError(value, _password.text),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: auth.error == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: Brand.s12),
                                child: _ErrorBox(message: auth.error!),
                              ),
                      ),
                      const SizedBox(height: Brand.s16),
                      PillButton(
                        label: auth.isSubmitting
                            ? 'CREANDO CUENTA…'
                            : 'CREAR CUENTA',
                        expanded: true,
                        showArrow: true,
                        onPressed: auth.isSubmitting ? null : _submit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Brand.s16),
                Text(
                  'Al crear tu cuenta aceptas que TOTO\'S use tus datos para '
                  'coordinar tus pedidos y casos de soporte. La contraseña solo la '
                  'gestiona Firebase.',
                  textAlign: TextAlign.center,
                  style: context.text.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    final aliases = context.read<AliasController>();
    auth.clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    final ok = await auth.signUp(
      name: _name.text.trim(),
      email: email,
      password: _password.text,
    );
    if (!mounted || !ok) return;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final uid = auth.uid;
    if (uid.isNotEmpty) {
      final base = aliases.suggestFromEmail(email);
      final unique = await aliases.uniqueAlias(base);
      final claimed = await aliases.claim(
        uid: uid,
        alias: unique,
        email: email,
      );
      if (claimed != null) {
        await auth.updateProfile(alias: unique);
      } else if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                aliases.error ?? 'No se pudo asignar tu alias. Cámbialo en tu perfil.',
              ),
            ),
          );
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}

/// Checklist de requisitos de contraseña: check verde o X roja.
class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({
    required this.password,
    required this.confirmation,
  });

  final String password;
  final String confirmation;

  static const Color _ok = Color(0xFF3FA66A);
  static const Color _pending = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty && confirmation.isEmpty) {
      return const SizedBox.shrink();
    }
    final requirements = Validators.passwordRequirements(
      password,
      confirmation: confirmation,
    );
    return Padding(
      padding: const EdgeInsets.only(top: Brand.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final requirement in requirements)
            Padding(
              padding: const EdgeInsets.only(top: Brand.s4),
              child: Row(
                children: [
                  Icon(
                    requirement.met
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 16,
                    color: requirement.met ? _ok : _pending,
                  ),
                  const SizedBox(width: Brand.s4),
                  Expanded(
                    child: Text(
                      requirement.label,
                      style: context.text.caption.copyWith(
                        color: requirement.met ? _ok : _pending,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Brand.s12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.buttonRadius,
        border: Border.all(color: colors.action, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: colors.action),
          const SizedBox(width: Brand.s8),
          Expanded(child: Text(message, style: context.text.bodySm)),
        ],
      ),
    );
  }
}
