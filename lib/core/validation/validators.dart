/// Un requisito visible del checklist de contraseña.
class PasswordRequirement {
  const PasswordRequirement({required this.label, required this.met});

  final String label;
  final bool met;
}

/// Validadores de formularios, con mensajes en español.
///
/// La contraseña del registro exige **6–64 caracteres**, al menos una
/// mayúscula y al menos una minúscula. El checklist de la vista muestra cada
/// requisito con check verde o X roja.
class Validators {
  const Validators._();

  static const int passwordMinLength = 6;
  static const int passwordMaxLength = 64;
  static const int nameMinLength = 3;
  static const int phoneMinDigits = 9;
  static const int phoneMaxDigits = 9;
  static const int addressLineMinLength = 6;
  static const int claimMinLength = 10;
  static const int claimMaxLength = 500;

  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final RegExp _letter = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]');
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _symbol = RegExp(r'[^A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñ]');

  /// Correo obligatorio y con formato válido.
  static String? emailError(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Ingresa tu correo electrónico.';
    return _email.hasMatch(email)
        ? null
        : 'El correo no tiene un formato válido.';
  }

  /// Contraseña de inicio de sesión: solo obligatoria.
  ///
  /// No aplica la regla del registro para no bloquear cuentas antiguas.
  static String? requiredPasswordError(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña.';
    return null;
  }

  /// Contraseña de registro: entre 6 y 64 caracteres, con mayúscula y
  /// minúscula.
  static String? passwordError(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Ingresa una contraseña.';
    if (password.length < passwordMinLength) {
      return 'La contraseña necesita al menos $passwordMinLength caracteres.';
    }
    if (password.length > passwordMaxLength) {
      return 'La contraseña no puede pasar de $passwordMaxLength caracteres.';
    }
    if (!_uppercase.hasMatch(password)) {
      return 'La contraseña necesita al menos una mayúscula.';
    }
    if (!_lowercase.hasMatch(password)) {
      return 'La contraseña necesita al menos una minúscula.';
    }
    return null;
  }

  static final RegExp _uppercase = RegExp(r'[A-ZÁÉÍÓÚÜÑ]');
  static final RegExp _lowercase = RegExp(r'[a-záéíóúüñ]');

  /// Requisitos visibles del checklist. La confirmación solo se evalúa cuando
  /// se pasa explícitamente.
  static List<PasswordRequirement> passwordRequirements(
    String password, {
    String? confirmation,
  }) => [
    PasswordRequirement(
      label: 'Mínimo $passwordMinLength caracteres',
      met: password.length >= passwordMinLength,
    ),
    PasswordRequirement(
      label: 'Máximo $passwordMaxLength caracteres',
      met: password.isNotEmpty && password.length <= passwordMaxLength,
    ),
    PasswordRequirement(
      label: 'Al menos una mayúscula',
      met: _uppercase.hasMatch(password),
    ),
    PasswordRequirement(
      label: 'Al menos una minúscula',
      met: _lowercase.hasMatch(password),
    ),
    if (confirmation != null)
      PasswordRequirement(
        label: 'Las contraseñas coinciden',
        met: password.isNotEmpty && confirmation == password,
      ),
  ];

  /// Confirmación de la contraseña.
  static String? confirmPasswordError(String? value, String password) {
    if (value == null || value.isEmpty) return 'Repite tu contraseña.';
    return value == password ? null : 'Las contraseñas no coinciden.';
  }

  /// Fuerza de 0 a 4 para la barra visual (informativa, no bloqueante).
  ///
  /// Suma por longitud y por variedad de caracteres. Una contraseña de 10
  /// letras cumple la política y queda en el nivel más bajo.
  static int passwordStrength(String value) {
    if (value.isEmpty) return 0;
    var score = 0;
    if (value.length >= passwordMinLength) score++;
    if (value.length >= 14) score++;
    final hasLetter = _letter.hasMatch(value);
    final hasDigit = _digit.hasMatch(value);
    final hasSymbol = _symbol.hasMatch(value);
    if (hasLetter && (hasDigit || hasSymbol)) score++;
    if (hasDigit && hasSymbol) score++;
    return score.clamp(0, 4);
  }

  /// Etiqueta corta del nivel de fuerza.
  static String passwordStrengthLabel(int score) {
    switch (score.clamp(0, 4)) {
      case 0:
        return 'Muy débil';
      case 1:
        return 'Débil';
      case 2:
        return 'Aceptable';
      case 3:
        return 'Buena';
      default:
        return 'Fuerte';
    }
  }

  /// Nombre obligatorio, mínimo 3 letras.
  static String? nameError(String? value) {
    final name = value?.trim() ?? '';
    if (name.length < nameMinLength) {
      return 'Escribe tu nombre (mínimo $nameMinLength letras).';
    }
    return null;
  }

  /// Teléfono opcional de exactamente 9 dígitos, debe empezar por 9.
  static String? phoneError(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    var digits = text.replaceAll(RegExp(r'\D'), '');
    // Acepta el prefijo de país +51 y lo descarta para validar el número local.
    if (digits.startsWith('51') && digits.length > 9) {
      digits = digits.substring(2);
    }
    if (digits.length < phoneMinDigits) {
      return 'Escribe un teléfono de exactamente $phoneMinDigits dígitos.';
    }
    if (digits.length > phoneMaxDigits) {
      return 'El teléfono debe tener exactamente $phoneMaxDigits dígitos.';
    }
    if (!digits.startsWith('9')) {
      return 'El teléfono debe comenzar con 9.';
    }
    return null;
  }

  /// Deja solo los dígitos locales, sin el prefijo +51.
  static String phoneDigits(String? value) {
    var digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('51') && digits.length > 9) {
      digits = digits.substring(2);
    }
    return digits;
  }

  /// Etiqueta de dirección obligatoria (Casa, Trabajo…).
  static String? addressLabelError(String? value) {
    final label = value?.trim() ?? '';
    if (label.isEmpty) {
      return 'Ponle una etiqueta, como «Casa» o «Trabajo».';
    }
    return null;
  }

  /// Línea de dirección obligatoria.
  static String? addressLineError(String? value) {
    final line = value?.trim() ?? '';
    if (line.length < addressLineMinLength) {
      return 'Escribe la dirección completa.';
    }
    return null;
  }

  /// Mensaje de reclamo de 10 a 500 caracteres.
  static String? claimMessageError(String? value) {
    final message = value?.trim() ?? '';
    if (message.length < claimMinLength) {
      return 'Cuéntanos un poco más (mínimo $claimMinLength caracteres).';
    }
    if (message.length > claimMaxLength) {
      return 'El mensaje no puede pasar de $claimMaxLength caracteres.';
    }
    return null;
  }
}
