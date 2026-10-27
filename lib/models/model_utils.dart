/// Utilidades de parseo compartidas por los modelos.
///
/// Los modelos no importan Flutter ni Firebase: aceptan mapas planos con
/// `DateTime`, cadenas ISO-8601 o marcas de tiempo con `toDate()`.
class ModelUtils {
  const ModelUtils._();

  static DateTime? asDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    try {
      // `Timestamp` de Firestore expone `toDate()`; se resuelve sin importar
      // el paquete para mantener los modelos puros.
      final dynamic dynamicValue = value;
      final dynamic date = dynamicValue.toDate();
      return date is DateTime ? date : null;
    } catch (_) {
      return null;
    }
  }

  static int asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? asIntOrNull(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double asDouble(Object? value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? asDoubleOrNull(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String asString(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static String? asStringOrNull(Object? value) {
    if (value == null) return null;
    final text = value is String ? value : value.toString();
    return text.isEmpty ? null : text;
  }

  static bool asBool(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return fallback;
  }

  static List<String> asStringList(Object? value) {
    if (value is List) {
      return value
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<int> asIntList(Object? value) {
    if (value is List) {
      return value.map((e) => asInt(e)).toList();
    }
    return const [];
  }

  static List<Map<String, dynamic>> asMapList(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  static Map<String, dynamic> asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  /// Lee un importe en **soles** de un documento.
  ///
  /// Acepta el esquema nuevo (`precio`, en soles) y los documentos legacy
  /// (`priceCents`, en céntimos) mientras dura la transición. El orden importa:
  /// si el campo en soles existe se usa tal cual; solo si falta se recurre a la
  /// clave en céntimos, dividiéndola entre 100.
  ///
  /// ```dart
  /// asMoney({'precio': 44.0})                 // 44.0
  /// asMoney({'priceCents': 4400})             // 44.0
  /// asMoney({}, fallback: 0)                  // 0.0
  /// ```
  static double asMoney(
    Map<String, dynamic> json,
    String solesKey, {
    String? centsKey,
    double fallback = 0,
  }) {
    final soles = json[solesKey];
    if (soles != null) return asDouble(soles, fallback: fallback);
    if (centsKey != null) {
      final cents = json[centsKey];
      if (cents != null) return asDouble(cents) / 100;
    }
    return fallback;
  }

  /// Igual que [asMoney] pero devuelve `null` si no hay ningún importe.
  static double? asMoneyOrNull(
    Map<String, dynamic> json,
    String solesKey, {
    String? centsKey,
  }) {
    final soles = json[solesKey];
    if (soles != null) return asDoubleOrNull(soles);
    if (centsKey != null) {
      final cents = json[centsKey];
      if (cents != null) {
        final value = asDoubleOrNull(cents);
        return value == null ? null : value / 100;
      }
    }
    return null;
  }

  /// Lista de importes en soles (acepta la clave en céntimos como respaldo).
  static List<double> asMoneyList(
    Map<String, dynamic> json,
    String solesKey, {
    String? centsKey,
  }) {
    final soles = json[solesKey];
    if (soles is List) {
      return soles.map(asDouble).toList();
    }
    if (centsKey != null) {
      final cents = json[centsKey];
      if (cents is List) return cents.map((e) => asDouble(e) / 100).toList();
    }
    return const [];
  }
}
