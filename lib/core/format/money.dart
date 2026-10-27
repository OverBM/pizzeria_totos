import 'package:intl/intl.dart';

/// Importes de dinero en **soles**.
///
/// Los precios se guardan en soles como `double` con 2 decimales, sin un campo
/// paralelo en céntimos. Toda operación pasa por aquí para que el redondeo sea
/// explícito y consistente:
///
/// ```dart
/// Money.format(44)    // 'S/ 44'
/// Money.format(49.9)  // 'S/ 49.90'
/// Money.sum([49.9, 0.1])           // 50.0
/// Money.multiply(49.9, 3)          // 149.7
/// ```
///
/// Reglas que el resto del código debe respetar:
/// - Redondear **al escribir y al sumar**, no solo al mostrar.
/// - Nunca comparar importes con `==`; usar [equals] o [closeTo].
class Money {
  const Money._();

  /// Cantidad de decimales con la que se normaliza todo importe.
  static const int decimals = 2;

  static final NumberFormat _whole = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimals = NumberFormat('#,##0.00', 'en_US');

  /// Normaliza a 2 decimales (redondeo medio arriba, como espera el negocio).
  ///
  /// `49.999999999` → `50.0` · `35.2` → `35.2` · `44` → `44.0`
  static double round(double value) {
    if (!value.isFinite) return 0;
    // `toStringAsFixed` redondea medio arriba y evita el arrastre binario.
    return double.parse(value.toStringAsFixed(decimals));
  }

  /// Suma importes normalizando el resultado: `49.90 + 0.10` da `50.0`.
  static double sum(Iterable<double> values) =>
      round(values.fold(0.0, (total, value) => total + value));

  /// Multiplica un precio unitario por una cantidad y normaliza.
  static double multiply(double unitPrice, int quantity) =>
      round(unitPrice * quantity);

  /// Aplica un descuento porcentual (0–100) con redondeo a 2 decimales.
  static double applyDiscountPercent(double price, num percent) =>
      round(price * (1 - percent / 100));

  /// Importe de un descuento porcentual, normalizado.
  static double discountAmount(double price, num percent) =>
      round(price - applyDiscountPercent(price, percent));

  /// ¿Dos importes son iguales una vez normalizados?
  static bool equals(double a, double b) => round(a) == round(b);

  /// ¿La diferencia entre dos importes es menor que medio céntimo?
  static bool closeTo(double a, double b) => (round(a) - round(b)).abs() < 0.005;

  /// Formatea un importe en soles.
  ///
  /// Omite los decimales cuando el importe es entero (`S/ 44`) y los conserva
  /// cuando existen (`S/ 49.90`).
  static String format(double soles) {
    final value = round(soles);
    final isWhole = value == value.truncateToDouble();
    final text = isWhole ? _whole.format(value) : _decimals.format(value);
    return 'S/ $text';
  }

  /// Convierte céntimos enteros a soles.
  ///
  /// Solo se usa en la frontera con datos legacy (documentos o JSON antiguos
  /// expresados en céntimos); el esquema actual guarda soles.
  static double fromCents(int cents) => round(cents / 100);

  /// Convierte soles a céntimos enteros, para comparar o migrar.
  static int toCents(double soles) => (round(soles) * 100).round();
}
