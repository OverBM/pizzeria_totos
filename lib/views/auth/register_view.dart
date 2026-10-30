import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                              'Entre ${Validators.passwordMinLength} y '
                              '${Validators.passwordMaxLength} caracteres. '
                              'No necesitas mayúsculas ni símbolos.',
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
                      _PasswordStrength(password: _password.text),
                      const SizedBox(height: Brand.s12),
                      TextFormField(
                        controller: _confirm,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
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
                  'coordinar tus pedidos y reclamos. La contraseña solo la '
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
    auth.clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await auth.signUp(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted || !ok) return;
    Navigator.of(context).pop(true);
  }
}

/// Medidor informativo de fuerza: nunca bloquea el envío.
///
/// Se llena por tramos con el semáforo pedido por el negocio: rojo (débil),
/// ámbar (aceptable) y verde (buena o fuerte).
class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});

  final String password;

  static const Color _weak = Color(0xFFE5484D); // rojo
  static const Color _medium = Color(0xFFE0A100); // ámbar
  static const Color _strong = Color(0xFF3FA66A); // verde

  static Color _colorFor(int score) {
    if (score <= 1) return _weak;
    if (score == 2) return _medium;
    return _strong;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final score = Validators.passwordStrength(password);
    final levelColor = _colorFor(score);
    return Padding(
      padding: const EdgeInsets.only(top: Brand.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: Brand.s4),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < score ? levelColor : colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Brand.s4),
          Text(
            'Seguridad: ${Validators.passwordStrengthLabel(score)}',
            style: context.text.caption.copyWith(color: levelColor),
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
