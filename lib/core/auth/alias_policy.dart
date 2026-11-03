/// Reglas de alias de acceso.
class AliasPolicy {
  const AliasPolicy._();

  static final RegExp _valid = RegExp(r'^[a-z0-9][a-z0-9._-]{2,19}$');
  static final RegExp _allDigits = RegExp(r'^\d+$');

  static const Set<String> reserved = {
    'admin',
    'administrador',
    'root',
    'superuser',
    'sysadmin',
    'system',
    'security',
    'seguridad',
    'abuse',
    'reportes',
    'denuncias',
    'soporte',
    'support',
    'ayuda',
    'help',
    'contacto',
    'contact',
    'atencion',
    'atencionalcliente',
    'servicioalcliente',
    'totos',
    'totos_pizza',
    'totos.pizza',
    'totospizza',
    'pizzeria',
    'pizza',
    'delivery',
    'plus',
    'totosplus',
    'promos',
    'promociones',
    'cupones',
    'coupons',
    'pedidos',
    'orders',
    'menu',
    'carta',
    'sedes',
    'local',
    'cocina',
    'staff',
    'equipo',
    'legal',
    'legales',
    'privacidad',
    'privacy',
    'terminos',
    'terms',
    'facturacion',
    'billing',
    'pagos',
    'payments',
    'cobranzas',
    'api',
    'www',
    'web',
    'mail',
    'email',
    'correo',
    'noreply',
    'postmaster',
    'hostmaster',
    'webmaster',
    'ftp',
    'smtp',
    'dns',
    'guest',
    'invitado',
    'usuario',
    'user',
    'cliente',
    'client',
    'account',
    'cuenta',
    'perfil',
    'profile',
    'puta',
    'puto',
    'putita',
    'putito',
    'pvta',
    'pvto',
    'mierda',
    'verga',
    'vergazo',
    'pene',
    'culo',
    'culito',
    'culiao',
    'culiada',
    'cono',
    'cabron',
    'cabrona',
    'pendejo',
    'pendeja',
    'concha',
    'conchatumadre',
    'chupame',
    'chupamela',
    'hijodeputa',
    'hijueputa',
    'malparido',
    'malparida',
    'maricon',
    'maricona',
    'zorra',
    'perra',
    'idiota',
    'imbecil',
    'estupido',
    'estupida',
    'tarado',
    'tarada',
    'mamaguevo',
    'mamagueba',
    'pajero',
    'pajera',
    'pija',
    'pijudo',
    'cagada',
    'cagado',
    'cagona',
    'ojete',
    'ojeton',
    'nalga',
    'nalgon',
    'tetas',
    'tetona',
    'pinga',
    'pingon',
    'semen',
    'orgia',
    'violador',
    'violadora',
    'nazi',
  };

  static const List<RegExp> reservedPatterns = [
    // Se usa una lista literal para evitar expresiones dinámicas.
    // Los patrones se validan también con startsWith en isValid.
  ];

  static bool isEmail(String value) => value.trim().contains('@');

  static String normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s._-]+'), '');

  static String deLeet(String value) => value
      .replaceAll('4', 'a')
      .replaceAll('3', 'e')
      .replaceAll('1', 'i')
      .replaceAll('0', 'o')
      .replaceAll('5', 's')
      .replaceAll('7', 't');

  static bool isReserved(String alias) {
    final normalized = deLeet(normalize(alias));
    if (reserved.contains(normalized)) return true;
    return normalized.startsWith('admin') ||
        normalized.startsWith('soporte') ||
        normalized.startsWith('totos') ||
        normalized.startsWith('staff');
  }

  static String? validate(String? value) {
    final alias = (value ?? '').trim().toLowerCase();
    if (alias.isEmpty) return 'Escribe un alias.';
    if (isEmail(alias)) return 'El alias no puede contener @.';
    if (alias.length < 3) return 'El alias necesita al menos 3 caracteres.';
    if (alias.length > 20) return 'El alias no puede pasar de 20 caracteres.';
    if (!_valid.hasMatch(alias)) {
      return 'Usa minúsculas, números, punto, guion o guion bajo.';
    }
    if (_allDigits.hasMatch(alias)) {
      return 'El alias no puede ser solo números.';
    }
    if (isReserved(alias)) {
      return 'Ese alias no está permitido. Elige otro.';
    }
    return null;
  }

  static String? validateIdentifier(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Escribe tu alias o correo.';
    if (isEmail(text)) {
      final email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
      return email.hasMatch(text) ? null : 'El correo no tiene un formato válido.';
    }
    return validate(text);
  }

  /// Devuelve el correo si el valor ya es un email; de lo contrario, el alias.
  static String normalizedIdentifier(String value) =>
      value.trim().toLowerCase();
}
