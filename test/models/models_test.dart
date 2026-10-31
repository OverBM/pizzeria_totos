import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/models/account.dart';
import 'package:pizzeria_totos/models/branch.dart';
import 'package:pizzeria_totos/models/cart_item.dart';
import 'package:pizzeria_totos/models/category.dart';
import 'package:pizzeria_totos/models/claim.dart';
import 'package:pizzeria_totos/models/delivery_config.dart';
import 'package:pizzeria_totos/models/media_ref.dart';
import 'package:pizzeria_totos/models/menu_data.dart';
import 'package:pizzeria_totos/models/model_utils.dart';
import 'package:pizzeria_totos/models/order.dart';
import 'package:pizzeria_totos/models/payment_method.dart';
import 'package:pizzeria_totos/models/product.dart';
import 'package:pizzeria_totos/models/promotion.dart';
import 'package:pizzeria_totos/models/settings.dart';
import 'package:pizzeria_totos/models/variant.dart';

void main() {
  group('ModelUtils', () {
    test('normaliza números y cadenas sin lanzar', () {
      expect(ModelUtils.asInt('4400'), 4400);
      expect(ModelUtils.asInt(44.9), 44);
      expect(ModelUtils.asInt(null, fallback: 7), 7);
      expect(ModelUtils.asIntOrNull('no-es-numero'), isNull);
      expect(ModelUtils.asDouble('12.5'), 12.5);
      expect(ModelUtils.asDoubleOrNull('x'), isNull);
      expect(ModelUtils.asBool('true'), isTrue);
      expect(ModelUtils.asBool(0), isFalse);
      expect(ModelUtils.asBool(null, fallback: true), isTrue);
      expect(ModelUtils.asStringOrNull(''), isNull);
      expect(ModelUtils.asString(123), '123');
    });

    test('parsea fechas de Firestore, ISO y epoch', () {
      expect(ModelUtils.asDateTime('2026-10-25T10:00:00Z')?.year, 2026);
      expect(ModelUtils.asDateTime(0)?.toUtc(), DateTime.utc(1970));
      expect(ModelUtils.asDateTime(null), isNull);
      expect(ModelUtils.asDateTime('basura'), isNull);
      expect(
        ModelUtils.asDateTime(_FakeTimestamp(DateTime(2026, 3, 4)))?.day,
        4,
      );
    });

    test('filtra listas heterogéneas', () {
      expect(ModelUtils.asStringList(['a', null, '', 3]), ['a', '3']);
      expect(ModelUtils.asIntList(['1', 2.9]), [1, 2]);
      expect(
        ModelUtils.asMapList([
          {'a': 1},
          'x',
        ]),
        [
          {'a': 1},
        ],
      );
      expect(ModelUtils.asMap(null), isEmpty);
    });
  });

  group('MediaRef', () {
    test('acepta cadenas y mapas, y descarta vacíos', () {
      expect(MediaRef.fromValue('https://x/y.png')?.url, 'https://x/y.png');
      expect(MediaRef.fromValue({'driveId': 'abc'})?.driveId, 'abc');
      expect(MediaRef.fromValue(''), isNull);
      expect(MediaRef.fromValue(<String, dynamic>{}), isNull);
      expect(MediaRef.none.isEmpty, isTrue);
      expect(const MediaRef(assetName: 'pizza.webp').isNotEmpty, isTrue);
    });

    test('serializa solo los campos presentes', () {
      const ref = MediaRef(driveId: 'id-1', assetName: 'pizza.webp');
      expect(ref.toMap(), {'driveId': 'id-1', 'assetName': 'pizza.webp'});
      expect(ref.copyWith(url: 'https://x/y.png').url, 'https://x/y.png');
    });
  });

  group('Producto y variantes', () {
    test('roundtrip completo conserva precios en céntimos', () {
      const product = Product(
        id: 'pizza-totos',
        categoryId: 'pizzas',
        name: "PIZZA TOTO'S",
        description: 'La de la casa.',
        image: MediaRef(driveId: 'drive-pizza'),
        tags: ['favorita'],
        featured: true,
        ingredients: ['Masa madre'],
        allergens: ['gluten'],
        calories: 1120,
        portion: '8 porciones',
        gallery: [MediaRef(assetName: 'pizza-2.webp')],
        variants: [
          Variant(label: 'entera', priceSoles: 43.90, slices: 8),
          Variant(label: 'media', priceSoles: 22.90, slices: 4),
        ],
      );

      final restored = Product.fromMap(product.toMap());
      expect(restored.id, 'pizza-totos');
      expect(restored.minPriceSoles, 22.90);
      expect(restored.variants.first.priceSoles, 43.90);
      expect(restored.hasVariants, isTrue);
      expect(restored.hasDetail, isTrue);
      expect(restored.images.length, 2);
      expect(restored.image?.driveId, 'drive-pizza');
      expect(restored.toMap(), product.toMap());
    });

    test('tolera documentos incompletos de Firestore', () {
      final product = Product.fromMap({
        'id': 'coca-600',
        'categoriaId': 'bebidas',
        'nombre': 'COCA COLA 600 ML',
        'variantes': [
          {'etiqueta': 'única', 'precio': 5},
        ],
      });
      expect(product.description, '');
      expect(product.available, isTrue);
      expect(product.featured, isFalse);
      expect(product.tags, isEmpty);
      expect(product.hasDetail, isFalse);
      expect(product.images, isEmpty);
      expect(product.minPriceSoles, 5);
    });

    test('lee un documento legacy en céntimos durante la transición', () {
      // Esquema anterior: campos en inglés y precio en céntimos.
      final legacy = Product.fromMap({
        'id': 'coca-600',
        'categoryId': 'bebidas',
        'name': 'COCA COLA 600 ML',
        'available': true,
        'variants': [
          {'label': 'única', 'priceCents': 500},
        ],
      });
      expect(legacy.name, 'COCA COLA 600 ML');
      expect(legacy.categoryId, 'bebidas');
      expect(legacy.minPriceSoles, 5);
    });

    test('Variant muestra rebanadas solo cuando aporta', () {
      const entera = Variant(label: 'entera', priceSoles: 4400, slices: 8);
      const unica = Variant(label: 'única', priceSoles: 500, slices: 8);
      expect(entera.displayLabel, 'ENTERA · 8 REBANADAS');
      expect(unica.displayLabel, 'ÚNICA');
      expect(Variant.fromMap(entera.toMap()).slices, 8);
    });

    test('un producto sin variantes no es vendible y no inventa precio', () {
      const sinVariantes = Product(
        id: 'sin-variantes',
        categoryId: 'pizzas',
        name: 'SIN VARIANTES',
        description: 'Documento incompleto.',
        variants: [],
      );
      expect(sinVariantes.defaultVariantOrNull, isNull);
      expect(sinVariantes.cheapestVariant, isNull);
      expect(sinVariantes.isSellable, isFalse);
      expect(sinVariantes.minPriceSoles, 0);

      const conVariantes = Product(
        id: 'ok',
        categoryId: 'pizzas',
        name: 'OK',
        description: '',
        variants: [
          Variant(label: 'entera', priceSoles: 44),
          Variant(label: 'media', priceSoles: 23),
        ],
      );
      expect(conVariantes.isSellable, isTrue);
      expect(conVariantes.defaultVariantOrNull?.label, 'entera');
      expect(conVariantes.cheapestVariant?.label, 'media');
      expect(conVariantes.variantForLabel('MEDIA')?.priceSoles, 23);

      const agotado = Product(
        id: 'agotado',
        categoryId: 'pizzas',
        name: 'AGOTADO',
        description: '',
        available: false,
        variants: [Variant(label: 'única', priceSoles: 10)],
      );
      expect(agotado.isSellable, isFalse);
    });
  });

  group('Carrito', () {
    test('calcula total de línea y ahorro en soles', () {
      const item = CartItem(
        productId: 'pizza-totos',
        name: "PIZZA TOTO'S",
        variantLabel: 'ENTERA',
        unitPriceSoles: 35.20,
        originalUnitPriceSoles: 44,
        quantity: 2,
      );
      expect(item.key, 'pizza-totos|ENTERA');
      expect(item.lineTotalSoles, 70.40);
      expect(item.isOnPromo, isTrue);
      expect(item.savingsSoles, 17.60);
      expect(item.copyWith(quantity: 1).savingsSoles, 8.80);
      expect(CartItem.fromMap(item.toMap()).quantity, 2);
    });

    test('sin promoción no hay ahorro y tolera claves heredadas', () {
      final item = CartItem.fromMap({
        'productoId': 'coca-600',
        'nombre': 'COCA COLA 600 ML',
        'etiquetaVariante': 'ÚNICA',
        'precioUnitario': 5,
      });
      expect(item.unitPriceSoles, 5);
      expect(item.quantity, 1);
      expect(item.isOnPromo, isFalse);
      expect(item.savingsSoles, 0);
    });

    test('lee un ítem legacy con precio en céntimos', () {
      final legacy = CartItem.fromMap({
        'productId': 'coca-600',
        'name': 'COCA COLA 600 ML',
        'variantLabel': 'ÚNICA',
        'unitPriceCents': 500,
      });
      expect(legacy.unitPriceSoles, 5);
    });
  });

  group('Carta', () {
    final menu = MenuData(
      categories: const [
        MenuCategory(id: 'pizzas', name: 'PIZZAS', order: 1),
        MenuCategory(id: 'bebidas', name: 'BEBIDAS', order: 2, active: false),
      ],
      products: const [
        Product(
          id: 'p1',
          categoryId: 'pizzas',
          name: 'PIZZA TOTO\'S',
          description: 'La de la casa.',
          featured: true,
          variants: [Variant(label: 'entera', priceSoles: 4400)],
        ),
        Product(
          id: 'b1',
          categoryId: 'bebidas',
          name: 'COCA COLA 600 ML',
          description: 'Bien fría.',
          variants: [Variant(label: 'única', priceSoles: 500)],
        ),
      ],
    );

    test('filtra por categoría y destacados', () {
      expect(menu.productsOf('pizzas').single.id, 'p1');
      expect(menu.featured.single.id, 'p1');
      expect(menu.byId('b1')?.name, 'COCA COLA 600 ML');
      expect(menu.categoryById('bebidas')?.order, 2);
      expect(menu.activeCategories.map((c) => c.id), ['pizzas']);
      expect(MenuData.empty.isEmpty, isTrue);
      expect(menu.isEmpty, isFalse);
    });

    test('categoría inactiva por defecto se activa al leer Firestore', () {
      expect(MenuCategory.fromMap({'id': 'x', 'name': 'X'}).active, isTrue);
      expect(
        MenuCategory.fromMap({'id': 'x', 'active': false}).active,
        isFalse,
      );
      expect(MenuCategory.featuredId, 'mas-pedidas');
    });

    test('la categoría virtual no entra en las categorías activas', () {
      final menu = MenuData(
        categories: const [
          MenuCategory(id: 'mas-pedidas', name: 'LAS MÁS PEDIDAS', order: 0),
          MenuCategory(id: 'pizzas', name: 'PIZZAS', order: 1),
          MenuCategory(id: 'bebidas', name: 'BEBIDAS', order: 2, active: false),
        ],
        products: const [],
      );
      expect(menu.activeCategories.map((c) => c.id), ['pizzas']);
    });
  });

  group('Cuenta y direcciones', () {
    test('deriva completitud del perfil', () {
      const account = Account(
        uid: 'uid-1',
        name: 'Ana',
        email: 'ana@example.com',
      );
      expect(account.hasPhone, isFalse);
      expect(account.hasAddress, isFalse);
      expect(account.isComplete, isFalse);
      expect(account.defaultAddress, isNull);

      final complete = account.copyWith(
        phone: '999 111 222',
        addresses: const [
          Address(id: 'a1', label: 'Casa', line: 'Av. Giráldez 123'),
        ],
      );
      expect(complete.isComplete, isTrue);
      expect(complete.defaultAddress?.label, 'Casa');
      expect(complete.addresses.single.title, 'Casa');
      expect(const Address(id: 'x', line: 'L').title, 'Dirección');
    });

    test('agrega, reemplaza y elimina direcciones por id', () {
      const base = Account(uid: 'uid-1', name: 'Ana', email: 'a@b.c');
      const first = Address(id: 'a1', label: 'Casa', line: 'L1');
      const second = Address(id: 'a2', label: 'Trabajo', line: 'L2');

      final withBoth = base.withAddress(first).withAddress(second);
      expect(withBoth.addresses.length, 2);

      final replaced = withBoth.withAddress(
        const Address(id: 'a1', label: 'Casa', line: 'L1 bis'),
      );
      expect(replaced.addresses.length, 2);
      expect(replaced.addresses.first.line, 'L1 bis');

      expect(withBoth.withoutAddress('a1').addresses.single.id, 'a2');
      expect(Account.fromMap(withBoth.toMap()).addresses.length, 2);
    });
  });

  group('Pedido', () {
    test('roundtrip con campos opcionales', () {
      final order = Order(
        id: 'order-1',
        code: 'TOT-20261015-1234',
        uid: 'uid-1',
        createdAt: DateTime(2026, 10, 15, 13),
        type: OrderType.delivery,
        branchId: 'huancayo',
        branchName: 'HUANCAYO',
        items: const [
          CartItem(
            productId: 'pizza-totos',
            name: "PIZZA TOTO'S",
            variantLabel: 'ENTERA',
            unitPriceSoles: 34.90,
            quantity: 1,
          ),
        ],
        subtotalSoles: 43.90,
        shippingSoles: 3.00,
        discountSoles: 9.00,
        totalSoles: 37.90,
        customerName: 'Ana Torres',
        phone: '999 111 222',
        paymentMethodId: 'efectivo',
        paymentMethodLabel: 'Efectivo contra entrega',
        address: 'Av. Giráldez 123',
        reference: 'Portón negro',
        note: 'Sin cebolla',
        savingsSoles: 9.00,
      );

      final restored = Order.fromMap(order.toMap(), id: 'order-1');
      expect(restored.id, 'order-1');
      expect(restored.status, OrderStatus.pendienteConfirmacion);
      expect(restored.status.name, 'pendiente_confirmacion');
      expect(restored.type.label, 'DELIVERY');
      expect(restored.items.single.unitPriceSoles, 34.90);
      expect(restored.address, 'Av. Giráldez 123');
      expect(restored.reference, 'Portón negro');
      expect(restored.note, 'Sin cebolla');
      expect(restored.savingsSoles, 9.00);
      expect(restored.toMap(), order.toMap());
    });

    test('sin opcionales no los serializa y cae en valores seguros', () {
      final order = Order.fromMap({
        'code': 'TOT-1',
        'uid': 'uid-1',
        'type': 'pickup',
        'subtotalSoles': 500,
        'totalSoles': 500,
        'paymentMethod': 'yape',
      });
      expect(order.type, OrderType.pickup);
      expect(order.type.name, 'pickup');
      expect(order.paymentMethodId, 'yape');
      expect(order.createdAt, DateTime(2000));
      expect(order.toMap().containsKey('address'), isFalse);
      expect(order.toMap().containsKey('note'), isFalse);
      expect(order.whatsappSent, isFalse);
      expect(OrderType.fromName('otro'), OrderType.delivery);
    });
  });

  group('Sedes', () {
    test('horario y visibilidad por provincia', () {
      final branch = Branch.fromMap({
        'id': 'huancayo',
        'nombre': 'HUANCAYO',
        'direccion': 'Prolongación San Carlos 123',
        'lat': '-12.0651',
        'lng': -75.2049,
        'costoDelivery': '3.00',
        'horario': {
          'abre': '12:45',
          'cierra': '21:30',
          'dias': [1, 2, 3],
        },
      });
      expect(branch.lat, closeTo(-12.0651, 0.0001));
      expect(branch.deliveryFeeSoles, 3);
      expect(branch.delivers, isTrue);
      expect(branch.hours.attendsDay(2), isTrue);
      expect(branch.hours.attendsDay(6), isFalse);
      expect(branch.hours.rangeLabel, '12:45 – 21:30');
      expect(branch.isVisible, isTrue);

      final otraProvincia = Branch.fromMap({
        'id': 'jauja',
        'provincia': 'Jauja',
      });
      expect(otraProvincia.isVisible, isFalse);
      expect(Branch.fromMap({'id': 'x'}).province, 'Huancayo');
      expect(BranchHours.fromMap({}).days, BranchHours.fallback.days);
      expect(Branch.fromMap(branch.toMap()).hours.close, '21:30');
    });

    test('horario de apertura, cierre y fechas cerradas', () {
      const hours = BranchHours(
        open: '12:45',
        close: '21:30',
        days: [1, 2, 3, 4, 5, 6, 7],
      );
      expect(BranchHours.minutesOf('12:45'), 765);
      expect(BranchHours.minutesOf('9:05'), 545);
      expect(BranchHours.minutesOf('basura'), isNull);
      expect(BranchHours.minutesOf('1'), isNull);

      // Dentro y fuera del rango del mismo día.
      expect(hours.isOpenAt(DateTime(2026, 10, 15, 13)), isTrue);
      expect(hours.isOpenAt(DateTime(2026, 10, 15, 12, 45)), isTrue);
      expect(hours.isOpenAt(DateTime(2026, 10, 15, 21, 30)), isTrue);
      expect(hours.isOpenAt(DateTime(2026, 10, 15, 12, 44)), isFalse);
      expect(hours.isOpenAt(DateTime(2026, 10, 15, 21, 31)), isFalse);

      final branch = Branch(
        id: 'huancayo',
        name: 'HUANCAYO',
        address: 'Prolongación San Carlos 123',
        lat: -12.0651,
        lng: -75.2049,
        delivers: true,
        hours: hours,
        closedDates: const ['2026-10-15'],
      );
      expect(branch.isOpenAt(DateTime(2026, 10, 15, 13)), isFalse);
      expect(branch.isOpenAt(DateTime(2026, 10, 16, 13)), isTrue);

      // Un día no atendido cierra la sede.
      const entreSemana = BranchHours(
        open: '12:45',
        close: '21:30',
        days: [1, 2, 3, 4, 5],
      );
      // 2026-10-17 es sábado.
      expect(entreSemana.isOpenAt(DateTime(2026, 10, 17, 13)), isFalse);
      expect(entreSemana.isOpenAt(DateTime(2026, 10, 16, 13)), isTrue);

      // Horario inválido: si el día atiende, no se bloquea el pedido por un
      // horario mal cargado (se asume abierta).
      expect(
        const BranchHours(
          open: 'x',
          close: 'y',
          days: [1, 2, 3, 4, 5, 6, 7],
        ).isOpenAt(DateTime(2026, 10, 15, 13)),
        isTrue,
      );
    });
  });

  group('Promociones', () {
    test('descuento porcentual y precio fijo', () {
      const percent = Promotion(
        id: 'promo',
        title: '-20%',
        productId: 'pizza-totos',
        discountPercent: 20,
      );
      expect(percent.discountedPrice(43.90), 34.90);
      expect(percent.appliesToPrice, isTrue);
      expect(percent.matches('pizza-totos', 'entera'), isTrue);
      expect(percent.matches('otra', 'entera'), isFalse);

      const fixed = Promotion(
        id: 'promo2',
        title: 'Combo',
        productId: 'pizza-totos',
        priceSoles: 29.90,
        variantLabel: 'familiar',
      );
      expect(fixed.discountedPrice(43.90), 29.90);
      expect(fixed.matches('pizza-totos', 'familiar'), isTrue);
      expect(fixed.matches('pizza-totos', 'entera'), isFalse);

      const noPrice = Promotion(id: 'p', title: 'Solo banner', productId: 'x');
      expect(noPrice.appliesToPrice, isFalse);
      expect(noPrice.discountedPrice(10.00), 10.00);
    });

    test('el precio promocional se calcula sobre la variante correcta', () {
      const product = Product(
        id: 'pizza-totos',
        categoryId: 'pizzas',
        name: "PIZZA TOTO'S",
        description: '',
        variants: [
          Variant(label: 'entera', priceSoles: 44),
          Variant(label: 'familiar', priceSoles: 60),
        ],
      );

      // Promoción atada a «familiar»: no debe usar el precio de «entera».
      const familiar = Promotion(
        id: 'promo-familiar',
        title: 'Familiar',
        productId: 'pizza-totos',
        variantLabel: 'familiar',
        discountPercent: 10,
      );
      expect(familiar.variantFor(product)?.label, 'familiar');
      expect(familiar.basePriceFor(product), 60);
      expect(familiar.priceFor(product), 53.90);
      expect(familiar.appliesToAnyVariant, isFalse);

      // Promoción abierta: se usa la variante más barata y se marca «desde».
      const abierta = Promotion(
        id: 'promo-abierta',
        title: 'Toda la pizza',
        productId: 'pizza-totos',
        priceSoles: 40,
      );
      expect(abierta.appliesToAnyVariant, isTrue);
      expect(abierta.variantFor(product)?.label, 'entera');
      expect(abierta.priceFor(product), 40);

      // Si la variante ya no existe, cae en la más barata sin lanzar.
      const huerfana = Promotion(
        id: 'promo-huerfana',
        title: 'Variante borrada',
        productId: 'pizza-totos',
        variantLabel: 'gigante',
        discountPercent: 50,
      );
      expect(huerfana.variantFor(product)?.label, 'entera');
      expect(huerfana.priceFor(product), 21.90);
    });

    test('vigencia y roundtrip', () {
      final promotion = Promotion(
        id: 'promo',
        title: 'PIZZA TOTO\'S -20%',
        subtitle: 'La de la casa, más barata',
        productId: 'pizza-totos',
        discountPercent: 20,
        image: const MediaRef(driveId: 'drive-promo'),
        startsAt: DateTime(2026, 10, 1),
        endsAt: DateTime(2026, 10, 31),
      );
      expect(promotion.isActive(DateTime(2026, 10, 15)), isTrue);
      expect(promotion.isActive(DateTime(2026, 9, 30)), isFalse);
      expect(promotion.isActive(DateTime(2026, 11, 1)), isFalse);
      expect(promotion.hasImage, isTrue);

      final restored = Promotion.fromMap(promotion.toMap());
      expect(restored.discountPercent, 20);
      expect(restored.image?.driveId, 'drive-promo');
      expect(restored.banner, isTrue);
      expect(restored.toMap(), promotion.toMap());

      expect(
        const Promotion(
          id: 'p',
          title: 't',
          productId: 'x',
          active: false,
        ).isActive(DateTime(2026)),
        isFalse,
      );
    });
  });

  group('Reclamos', () {
    test('estado único enviado y roundtrip', () {
      final claim = Claim(
        id: 'claim-1',
        code: 'REC-20261016-4821',
        uid: 'uid-1',
        orderId: 'order-1',
        categoryId: 'demora',
        categoryLabel: 'Demora en la entrega',
        message: 'Mi pedido llegó tarde.',
        createdAt: DateTime(2026, 10, 16, 20),
        updatedAt: DateTime(2026, 10, 16, 20),
      );
      expect(claim.status, ClaimStatus.enviado);
      expect(claim.status.label, 'ENVIADO');
      expect(ClaimStatus.fromName('resuelto'), ClaimStatus.enviado);

      final restored = Claim.fromMap(claim.toMap(), id: 'claim-1');
      expect(restored.message, 'Mi pedido llegó tarde.');
      expect(restored.orderId, 'order-1');
      expect(restored.toMap(), claim.toMap());
    });

    test('motivo por defecto cuando el documento está incompleto', () {
      final claim = Claim.fromMap({'message': 'x'});
      expect(claim.categoryId, 'otro');
      expect(claim.categoryLabel, 'Otro motivo');
      expect(claim.branchId, isNull);
      expect(ClaimReason.fallback.length, greaterThanOrEqualTo(3));
      expect(ClaimReason.fromMap({'id': 'a', 'label': 'A'}).label, 'A');
    });
  });

  group('Configuración', () {
    test('WhatsApp efectivo cae en el placeholder de la beta', () {
      expect(AppSettings.fallback.effectiveWhatsapp, '51900000000');
      expect(
        const AppSettings(whatsapp: '   ', phone: '').effectiveWhatsapp,
        AppSettings.placeholderWhatsapp,
      );
      expect(
        const AppSettings(whatsapp: '5112345678', phone: '').effectiveWhatsapp,
        '5112345678',
      );
    });

    test('medios de pago y motivos activos con respaldo', () {
      expect(AppSettings.fallback.activePaymentMethods.length, 2);
      expect(AppSettings.fallback.activeClaimReasons.length, 5);

      const onlyInactive = AppSettings(
        whatsapp: '5',
        phone: '',
        paymentMethods: [PaymentMethod(id: 'x', label: 'X', active: false)],
      );
      expect(onlyInactive.activePaymentMethods, PaymentMethod.fallback);
    });

    test('roundtrip de configuracion/app', () {
      final settings = AppSettings(
        whatsapp: '51900000000',
        phone: '51900000000',
        phoneDisplay: '900 000 000',
        driveFolderUrl: 'https://drive.google.com/drive/folders/abc',
        heroImage: const MediaRef(assetName: 'hero-1.webp'),
        paymentMethods: PaymentMethod.fallback,
        claimReasons: ClaimReason.fallback,
        delivery: DeliveryConfig.fallback,
        updatedAt: DateTime(2026, 10, 25),
      );
      final restored = AppSettings.fromMap(settings.toMap());
      expect(restored.phoneDisplay, '900 000 000');
      expect(restored.heroImage?.assetName, 'hero-1.webp');
      expect(restored.driveFolderUrl, 'https://drive.google.com/drive/folders/abc');
      expect(restored.paymentMethods.length, 2);
      expect(restored.delivery.baseSoles, 3);
      expect(restored.updatedAt?.year, 2026);
      expect(restored.toMap(), settings.toMap());
    });

    test('delivery calcula tarifa por distancia con redondeo hacia arriba', () {
      const config = DeliveryConfig.fallback;
      expect(config.feeForKm(0), 3);
      expect(config.feeForKm(1.2), 6);
      expect(config.feeForKm(8), 0);
      expect(config.isDeliverable(14), isTrue);
      expect(config.isDeliverable(16), isFalse);
      expect(
        DeliveryConfig.fromMap({'baseSoles': 0, 'perKmSoles': 0}).feeForKm(1),
        0,
      );
      expect(DeliveryConfig.fromMap({}).freeAboveKm, double.infinity);
    });
  });
}

class _FakeTimestamp {
  const _FakeTimestamp(this._date);

  final DateTime _date;

  DateTime toDate() => _date;
}
