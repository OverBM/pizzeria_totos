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

  /// Formatea un importe en soles con exactamente dos decimales.
  ///
  /// La carta publica precios terminados en `.90`; el formateo es siempre
  /// explícito para que una tarjeta y un total no parezcan importes distintos.
  static String format(double soles) {
    return 'S/ ${_decimals.format(round(soles))}';
  }

  /// Precio base comercial: conserva los `.90` y baja diez céntimos a los
  /// importes enteros (`44.00` → `43.90`).
  ///
  /// Se usa solo al publicar/editar la carta; el runtime no transforma precios.
  static double baseCommercial(double value) {
    final current = round(value);
    final cents = (current * 100).round() % 100;
    if (cents == 90) return current;
    return round(current.floorToDouble() - 0.10);
  }

  /// Precio promocional comercial: lleva el resultado de un descuento al `.90`
  /// inmediatamente inferior. Así el cliente nunca recibe menos descuento del
  /// anunciado y el precio final siempre es comercial.
  static double promoCommercial(double value) {
    final current = round(value);
    final cents = (current * 100).round() % 100;
    if (cents == 90) return current;
    final floor = current.floorToDouble();
    final candidate = round(floor + 0.90);
    if (candidate <= current) return candidate;
    return round(floor - 0.10).clamp(0.90, double.infinity).toDouble();
  }

  /// Convierte céntimos enteros a soles.
  ///
  /// Solo se usa en la frontera con datos legacy (documentos o JSON antiguos
  /// expresados en céntimos); el esquema actual guarda soles.
  static double fromCents(int cents) => round(cents / 100);

  /// Convierte soles a céntimos enteros, para comparar o migrar.
  static int toCents(double soles) => (round(soles) * 100).round();
}
