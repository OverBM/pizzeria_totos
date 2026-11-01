import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/theme/brand.dart';
import '../../widgets/widgets.dart';
import '../../core/theme/theme_context.dart';
import '../../core/validation/validators.dart';
import 'register_view.dart';

/// Inicio de sesión con email y contraseña de Firebase.
class LoginView extends StatefulWidget {
  const LoginView({super.key, this.message});

  /// Texto contextual (por ejemplo, al venir del checkout sin sesión).
  final String? message;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
                const OutlinedDisplayTitle('INICIAR SESIÓN', size: 34),
                const SizedBox(height: Brand.s8),
                Text(
                  widget.message ??
                      'Entra para confirmar tu pedido con tus datos guardados '
                          'y hacer seguimiento de tus reclamos.',
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
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
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
                        validator: Validators.requiredPasswordError,
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
                            ? 'ENTRANDO…'
                            : 'INICIAR SESIÓN',
                        expanded: true,
                        showArrow: true,
                        onPressed: auth.isSubmitting ? null : _submit,
                      ),
                      const SizedBox(height: Brand.s8),
                      TextButton(
                        onPressed: auth.isSubmitting ? null : _recover,
                        child: const Text('OLVIDÉ MI CONTRASEÑA'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Brand.s16),
                Row(
                  children: [
                    Expanded(child: Divider(color: colors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Brand.s8),
                      child: Text(
                        'O',
                        style: context.text.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: colors.border)),
                  ],
                ),
                const SizedBox(height: Brand.s16),
                PillButton(
                  label: 'CREAR UNA CUENTA',
                  filled: false,
                  expanded: true,
                  onPressed: auth.isSubmitting ? null : _goToRegister,
                ),
                const SizedBox(height: Brand.s16),
                Text(
                  'Tu contraseña la gestiona Firebase: no se guarda en el '
                  'dispositivo ni en la base de datos.',
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
    final ok = await auth.signIn(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!mounted || !ok) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _goToRegister() async {
    final registered = await Navigator.of(context)
        .push<bool>(MotionRoute(builder: (_) => const RegisterView()));
    if (!mounted || registered != true) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _recover() async {
    final auth = context.read<AuthController>();
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _RecoveryDialog(initialEmail: _email.text.trim()),
    );
    if (email == null || !mounted) return;
    final ok = await auth.sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Si el correo está registrado, recibirás un enlace para '
                      'restablecer tu contraseña.'
                : auth.error ?? 'No se pudo enviar la solicitud.',
          ),
        ),
      );
  }
}

/// Diálogo de recuperación: valida dentro del diálogo y solo se cierra con un
/// correo válido. El controlador de texto se libera al cerrarlo.
class _RecoveryDialog extends StatefulWidget {
  const _RecoveryDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends State<_RecoveryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('RECUPERAR CONTRASEÑA'),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Correo electrónico'),
          validator: Validators.emailError,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCELAR'),
        ),
        FilledButton(onPressed: _send, child: const Text('ENVIAR')),
      ],
    );
  }

  void _send() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_email.text.trim());
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
