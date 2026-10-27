import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/models/media_ref.dart';
import 'package:pizzeria_totos/services/drive_image_service.dart';

void main() {
  const id20 = '1AbCdEfGhIjKlMnOpQrS';
  const id33 = '1a2B3c4D5e6F7g8H9i0J1k2L3m4N5o6P7';

  group('extractId', () {
    test('lee enlaces de compartir de Drive', () {
      expect(
        DriveImageService.extractId(
          'https://drive.google.com/file/d/$id33/view',
        ),
        id33,
      );
      expect(
        DriveImageService.extractId(
          'https://drive.google.com/file/d/$id33/view?usp=sharing',
        ),
        id33,
      );
      expect(
        DriveImageService.extractId(
          'https://drive.google.com/open?id=$id33&authuser=0',
        ),
        id33,
      );
      expect(
        DriveImageService.extractId('https://drive.google.com/d/$id33'),
        id33,
      );
      expect(DriveImageService.extractId('  $id20  '), id20);
    });

    test('descarta referencias que no son de Drive', () {
      expect(DriveImageService.extractId(null), isNull);
      expect(DriveImageService.extractId('   '), isNull);
      expect(DriveImageService.extractId('corto'), isNull);
      expect(
        DriveImageService.extractId('https://cdn.totos.pe/pizza.webp'),
        isNull,
      );
      expect(DriveImageService.extractId('pizza-totos.webp'), isNull);
      expect(DriveImageService.isDriveReference(null), isFalse);
      expect(DriveImageService.isDriveReference(id33), isTrue);
    });
  });

  group('resolve', () {
    test('prioriza driveId, luego el ID dentro de la URL y luego la URL', () {
      const porId = MediaRef(driveId: id33, url: 'https://cdn.totos.pe/x.webp');
      expect(DriveImageService.resolve(porId), contains('id=$id33'));

      const porUrlDrive = MediaRef(
        url: 'https://drive.google.com/file/d/$id20/view',
      );
      expect(DriveImageService.resolve(porUrlDrive), contains('id=$id20'));

      const urlDirecta = MediaRef(url: 'https://cdn.totos.pe/pizza.webp');
      expect(
        DriveImageService.resolve(urlDirecta),
        'https://cdn.totos.pe/pizza.webp',
      );
    });

    test('respaldo local y referencias vacías quedan sin URL', () {
      expect(
        DriveImageService.resolve(const MediaRef(assetName: 'p.webp')),
        isNull,
      );
      expect(DriveImageService.resolve(MediaRef.none), isNull);
      expect(DriveImageService.resolve(null), isNull);
      expect(DriveImageService.resolve(const MediaRef(url: 'ftp://x')), isNull);
      expect(
        DriveImageService.resolve(const MediaRef(url: 'javascript:1')),
        isNull,
      );
    });

    test('la miniatura respeta el ancho y lo acota', () {
      expect(
        DriveImageService.thumbnailUrl(id33, width: 600),
        'https://drive.google.com/thumbnail?id=$id33&sz=w600',
      );
      expect(
        DriveImageService.thumbnailUrl(id33, width: 10),
        contains('sz=w120'),
      );
      expect(
        DriveImageService.thumbnailUrl(id33, width: 9000),
        contains('sz=w2000'),
      );
      expect(
        DriveImageService.resolve(const MediaRef(driveId: id33), width: 400),
        contains('sz=w400'),
      );
    });

    test('una referencia rota no rompe la resolución', () {
      // Enlace no público: el servicio igual devuelve la URL de miniatura y
      // `DriveImage` cae al asset local o al placeholder de marca.
      const noPublico = MediaRef(
        url: 'https://drive.google.com/file/d/$id20/view',
      );
      expect(DriveImageService.resolve(noPublico), isNotNull);
      expect(
        DriveImageService.resolve(const MediaRef(driveId: '1234')),
        isNull,
      );
    });

    test('sin imagen, la cadena de respaldo termina en el placeholder', () {
      const producto = MediaRef.none;
      expect(DriveImageService.resolve(producto), isNull);
    });
  });
}
