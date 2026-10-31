import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/core/format/money.dart';

void main() {
  group('redondeo', () {
    test('normaliza a 2 decimales', () {
      expect(Money.round(49.999999999), 50.0);
      expect(Money.round(35.2), 35.2);
      expect(Money.round(44), 44.0);
      expect(Money.round(0.005), 0.01);
      expect(Money.round(-0.004), 0.0);
    });

    test('no propaga el arrastre binario', () {
      expect(Money.round(0.1 + 0.2), 0.3);
      expect(Money.sum([49.90, 0.10]), 50.0);
      expect(Money.sum([0.1, 0.2]), 0.3);
    });

    test('tolera valores no finitos sin romper', () {
      expect(Money.round(double.nan), 0);
      expect(Money.round(double.infinity), 0);
    });
  });

  group('operaciones', () {
    test('suma de líneas de un pedido', () {
      // 149.70 + 23.00 + 3.00 de envío
      expect(Money.sum([149.70, 23.00, 3.00]), 175.70);
    });

    test('multiplica por cantidad', () {
      expect(Money.multiply(49.90, 3), 149.70);
      expect(Money.multiply(44.00, 1), 44.0);
      expect(Money.multiply(35.20, 2), 70.40);
    });

    test('descuento porcentual', () {
      expect(Money.applyDiscountPercent(44.00, 20), 35.20);
      expect(Money.discountAmount(44.00, 20), 8.80);
      expect(Money.applyDiscountPercent(44.00, 15), 37.40);
      expect(Money.applyDiscountPercent(100.00, 33), 67.0);
    });

    test('el ahorro más el precio promocional reconstruyen el original', () {
      const original = 44.00;
      final promo = Money.applyDiscountPercent(original, 20);
      final ahorro = Money.discountAmount(original, 20);
      expect(Money.sum([promo, ahorro]), original);
    });
  });

  group('comparación sin igualdad exacta', () {
    test('equals normaliza antes de comparar', () {
      expect(Money.equals(49.90, 49.9), isTrue);
      expect(Money.equals(49.90, 49.900000001), isTrue);
      expect(Money.equals(49.90, 49.91), isFalse);
    });

    test('closeTo admite menos de medio céntimo', () {
      expect(Money.closeTo(50.0, 49.999999999), isTrue);
      expect(Money.closeTo(50.0, 49.99), isFalse);
    });
  });

  group('formato', () {
    test('muestra siempre dos decimales', () {
      expect(Money.format(44), 'S/ 44.00');
      expect(Money.format(44.0), 'S/ 44.00');
      expect(Money.format(55), 'S/ 55.00');
    });

    test('conserva decimales cuando existen', () {
      expect(Money.format(49.9), 'S/ 49.90');
      expect(Money.format(35.2), 'S/ 35.20');
      expect(Money.format(175.7), 'S/ 175.70');
      expect(Money.format(8.8), 'S/ 8.80');
    });

    test('separa miles', () {
      expect(Money.format(1234.5), 'S/ 1,234.50');
      expect(Money.format(1200), 'S/ 1,200.00');
    });

    test('formatea cero', () {
      expect(Money.format(0), 'S/ 0.00');
    });
  });

  group('terminaciones comerciales', () {
    test('base entera baja diez céntimos', () {
      expect(Money.baseCommercial(44), 43.90);
      expect(Money.baseCommercial(28), 27.90);
      expect(Money.baseCommercial(3), 2.90);
    });

    test('base que ya termina en .90 se conserva', () {
      expect(Money.baseCommercial(49.90), 49.90);
      expect(Money.baseCommercial(0.90), 0.90);
    });

    test('precio promocional baja al .90 inmediatamente inferior', () {
      expect(Money.promoCommercial(35.12), 34.90);
      expect(Money.promoCommercial(10.71), 9.90);
      expect(Money.promoCommercial(11.90), 11.90);
    });
  });

  group('frontera con céntimos', () {
    test('fromCents convierte datos legacy', () {
      expect(Money.fromCents(4400), 44.0);
      expect(Money.fromCents(4990), 49.9);
      expect(Money.fromCents(35), 0.35);
    });

    test('toCents vuelve a enteros para migrar', () {
      expect(Money.toCents(44.0), 4400);
      expect(Money.toCents(49.9), 4990);
      expect(Money.toCents(0.1 + 0.2), 30);
    });

    test('ida y vuelta es estable', () {
      for (final cents in [4400, 4990, 3500, 35, 1, 123456]) {
        expect(Money.toCents(Money.fromCents(cents)), cents);
      }
    });
  });
}
