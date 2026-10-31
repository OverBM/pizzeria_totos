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

  group('Contraseña del registro (6–64, mayúscula y minúscula)', () {
    test('rechaza vacía, corta y larga', () {
      expect(Validators.passwordError(''), 'Ingresa una contraseña.');
      expect(
        Validators.passwordError('Ab1'),
        'La contraseña necesita al menos 6 caracteres.',
      );
      expect(
        Validators.passwordError('Aa1${'a' * 62}'),
        'La contraseña no puede pasar de 64 caracteres.',
      );
    });

    test('exige mayúscula y minúscula', () {
      expect(
        Validators.passwordError('sololetras'),
        'La contraseña necesita al menos una mayúscula.',
      );
      expect(
        Validators.passwordError('SOLOLETRAS'),
        'La contraseña necesita al menos una minúscula.',
      );
      expect(Validators.passwordError('MiClave'), isNull);
      expect(Validators.passwordError('miClave'), isNull);
    });

    test('no exige dígitos ni símbolos', () {
      expect(Validators.passwordError('MiClave'), isNull);
      expect(Validators.passwordError('MiClaveSegura'), isNull);
    });

    test('el checklist refleja cada requisito', () {
      final short = Validators.passwordRequirements('abc');
      expect(short.first.met, isFalse);
      expect(
        short.firstWhere((r) => r.label.contains('mayúscula')).met,
        isFalse,
      );
      expect(
        short.firstWhere((r) => r.label.contains('minúscula')).met,
        isTrue,
      );

      final full = Validators.passwordRequirements(
        'MiClave',
        confirmation: 'MiClave',
      );
      expect(full.every((r) => r.met), isTrue);
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

    test('teléfono opcional de exactamente 9 dígitos y empieza por 9', () {
      expect(Validators.phoneError(''), isNull);
      expect(Validators.phoneError('12345678'), isNotNull);
      expect(Validators.phoneError('999 111 222'), isNull);
      expect(Validators.phoneError('999 111 222 3'), isNotNull);
      expect(Validators.phoneError('1' * 16), isNotNull);
      expect(Validators.phoneError('+51 999 111 222'), isNull);
      expect(Validators.phoneError('888 111 222'), isNotNull);
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
