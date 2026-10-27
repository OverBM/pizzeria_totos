import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/core/validation/validators.dart';

void main() {
  group('Correo', () {
    test('exige valor y formato', () {
      expect(Validators.emailError(''), 'Ingresa tu correo electrónico.');
      expect(Validators.emailError('   '), 'Ingresa tu correo electrónico.');
      expect(
        Validators.emailError('ana@'),
        'El correo no tiene un formato válido.',
      );
      expect(Validators.emailError('ana@ejemplo.com'), isNull);
      expect(Validators.emailError(' ana@ejemplo.com '), isNull);
    });
  });

  group('Contraseña del registro (10–64)', () {
    test('rechaza vacía, 9 y 65 caracteres', () {
      expect(Validators.passwordError(''), 'Ingresa una contraseña.');
      expect(
        Validators.passwordError('pizza1234'),
        'La contraseña necesita al menos 10 caracteres.',
      );
      expect(
        Validators.passwordError('a' * 65),
        'La contraseña no puede pasar de 64 caracteres.',
      );
    });

    test('acepta los límites y las letras sin símbolos', () {
      expect(Validators.passwordError('a' * 10), isNull);
      expect(Validators.passwordError('miperroesfiel'), isNull);
      expect(Validators.passwordError('a' * 64), isNull);
    });

    test('no exige mayúsculas, dígitos ni símbolos', () {
      expect(Validators.passwordError('sololetras'), isNull);
      expect(Validators.passwordError('1234567890'), isNull);
      expect(Validators.passwordError('..........'), isNull);
    });

    test('el inicio de sesión solo exige contraseña no vacía', () {
      expect(
        Validators.requiredPasswordError(''),
        'Ingresa tu contraseña.',
      );
      expect(Validators.requiredPasswordError('123456'), isNull);
    });

    test('la confirmación debe coincidir', () {
      expect(
        Validators.confirmPasswordError('', 'miperroesfiel'),
        'Repite tu contraseña.',
      );
      expect(
        Validators.confirmPasswordError('otracosa', 'miperroesfiel'),
        'Las contraseñas no coinciden.',
      );
      expect(
        Validators.confirmPasswordError('miperroesfiel', 'miperroesfiel'),
        isNull,
      );
    });
  });

  group('Fuerza de la contraseña', () {
    test('sube con longitud y variedad, sin bloquear', () {
      expect(Validators.passwordStrength(''), 0);
      // 13 letras: cumple la política pero es el nivel más bajo.
      expect(Validators.passwordStrength('miperroesfiel'), 1);
      final strong = Validators.passwordStrength('MiClaveSegura2026!');
      expect(strong, greaterThan(Validators.passwordStrength('miperroesfiel')));
      expect(strong, 4);
      expect(Validators.passwordStrengthLabel(0), 'Muy débil');
      expect(Validators.passwordStrengthLabel(4), 'Fuerte');
    });
  });

  group('Nombre, teléfono, dirección y reclamo', () {
    test('nombre mínimo de 3 letras', () {
      expect(Validators.nameError(null), isNotNull);
      expect(Validators.nameError('Al'), isNotNull);
      expect(Validators.nameError('Ana'), isNull);
    });

    test('teléfono opcional de 9 a 15 dígitos', () {
      expect(Validators.phoneError(''), isNull);
      expect(Validators.phoneError('12345678'), isNotNull);
      expect(Validators.phoneError('999 111 222'), isNull);
      expect(Validators.phoneError('1' * 16), isNotNull);
      expect(Validators.phoneError('+51 999 111 222'), isNull);
    });

    test('dirección exige etiqueta y línea', () {
      expect(Validators.addressLabelError(''), isNotNull);
      expect(Validators.addressLabelError('Casa'), isNull);
      expect(Validators.addressLineError('Av.'), isNotNull);
      expect(Validators.addressLineError('Av. Giráldez 123'), isNull);
    });

    test('reclamo entre 10 y 500 caracteres', () {
      expect(Validators.claimMessageError('corto'), isNotNull);
      expect(Validators.claimMessageError('a' * 9), isNotNull);
      expect(Validators.claimMessageError('a' * 10), isNull);
      expect(Validators.claimMessageError('a' * 500), isNull);
      expect(Validators.claimMessageError('a' * 501), isNotNull);
    });
  });
}
