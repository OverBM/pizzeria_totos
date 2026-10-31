import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/core/data/product_summary.dart';
import 'package:pizzeria_totos/core/motion/motion_widgets.dart';
import 'package:pizzeria_totos/widgets/widgets.dart';
import 'package:pizzeria_totos/core/theme/product_family.dart';
import 'package:pizzeria_totos/core/theme/toto_theme.dart';
import 'package:pizzeria_totos/models/media_ref.dart';
import 'package:pizzeria_totos/models/menu_data.dart';
import 'package:pizzeria_totos/models/category.dart';
import 'package:pizzeria_totos/models/order.dart';
import 'package:pizzeria_totos/models/cart_item.dart';
import 'package:pizzeria_totos/models/product.dart';
import 'package:pizzeria_totos/models/variant.dart';
import 'package:pizzeria_totos/views/carta/carta_view.dart';
import 'package:pizzeria_totos/views/carta/product_detail_view.dart';
import 'package:pizzeria_totos/views/home/home_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/harness.dart';

const _driveId = '1ddbLJ071UfFgFd9pZOBYKyIceDWTcje2';

Product _product({
  String id = 'p',
  String name = 'PIZZA TOTO\'S',
  String description = 'La de la casa.',
  String categoryId = 'pizzas',
  List<String> ingredients = const ['Masa madre', 'Mozzarella'],
  List<String> allergens = const [],
  String? portion,
  int? calories,
  String? summary,
}) {
  return Product(
    id: id,
    categoryId: categoryId,
    name: name,
    description: description,
    ingredients: ingredients,
    allergens: allergens,
    portion: portion,
    calories: calories,
    summary: summary,
    variants: const [Variant(label: 'única', priceSoles: 10)],
  );
}

Widget _wrap(Widget child) => MaterialApp(
  theme: totoTheme(),
  darkTheme: totoTheme(),
  themeMode: ThemeMode.dark,
  home: Scaffold(body: child),
);

Widget _cardFor(Product product, {VoidCallback? onAdd}) {
  return _wrap(
    Center(
      child: SizedBox(
        width: 328,
        child: ProductRowCard(
          image: const ColoredBox(color: Colors.black),
          name: product.name,
          description: product.displaySummary,
          categoryId: product.categoryId,
          summary: ProductSummary.of(product),
          priceLabel: 'S/ 38',
          onTap: () {},
          onAdd: onAdd,
        ),
      ),
    ),
  );
}

MenuData _bigMenu(int count) {
  return MenuData(
    categories: const [
      MenuCategoryFixture.featured,
      MenuCategoryFixture.pizzas,
      MenuCategoryFixture.bebidas,
    ],
    products: [
      for (var i = 0; i < count; i++)
        _product(
          id: 'p$i',
          name: 'PIZZA $i',
          ingredients: const [
            'Masa madre',
            'Mozzarella',
            'Pepperoni',
            'Orégano',
          ],
        ),
    ],
  );
}

void main() {
  setUpAll(loadBrandFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    useDeterministicCursor();
  });

  group('ProductRowCard', () {
    testWidgets('muestra los ingredientes distintivos y la familia', (
      tester,
    ) async {
      final product = sampleFourCheese;
      await tester.pumpWidget(_cardFor(product, onAdd: () {}));

      expect(
        find.text('Mozzarella · Queso parmesano · Queso azul · Queso edam'),
        findsOneWidget,
      );
      expect(find.byType(ProductFamilyIcon), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no muestra información nutricional en la tarjeta', (
      tester,
    ) async {
      final product = sampleFourCheese;
      await tester.pumpWidget(_cardFor(product, onAdd: () {}));

      expect(find.textContaining('kcal'), findsNothing);
    });

    testWidgets('sin calorías no muestra el chip', (tester) async {
      final product = _product(
        id: 'bebida',
        name: 'AGUA MINERAL',
        ingredients: const ['Agua mineral'],
        portion: '500 ml',
      );
      await tester.pumpWidget(_cardFor(product, onAdd: () {}));

      expect(find.textContaining('kcal'), findsNothing);
      expect(find.text('Agua mineral · 500 ml'), findsOneWidget);
    });

    testWidgets('sin ingredientes muestra la porción', (tester) async {
      final product = _product(
        id: 'sin-ingredientes',
        ingredients: const [],
        portion: 'Porción personal',
      );
      await tester.pumpWidget(_cardFor(product, onAdd: () {}));

      expect(find.text('Porción personal'), findsOneWidget);
      expect(find.byType(ProductFamilyIcon), findsOneWidget);
    });

    testWidgets('sin ingredientes ni porción no deja línea', (tester) async {
      final product = _product(id: 'vacio', ingredients: const []);
      await tester.pumpWidget(_cardFor(product, onAdd: () {}));

      expect(find.byType(ProductFamilyIcon), findsNothing);
      expect(find.textContaining(' · '), findsNothing);
    });

    testWidgets('no muestra alérgenos', (tester) async {
      final product = _product(
        allergens: const ['Gluten', 'Lácteos'],
        calories: 1120,
      );
      await tester.pumpWidget(_cardFor(product, onAdd: () {}));

      expect(find.textContaining('Gluten'), findsNothing);
      expect(find.textContaining('Lácteos'), findsNothing);
    });

    testWidgets('usa el carrito y no el símbolo +', (tester) async {
      final product = sampleFourCheese;
      await tester.pumpWidget(_cardFor(product, onAdd: () {}));

      expect(find.byType(AddToCartIcon), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsNothing);
    });

    testWidgets('el selector de cantidad conserva el +', (tester) async {
      await tester.pumpWidget(
        _wrap(const Center(child: QuantityStepper(quantity: 2))),
      );

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('la etiqueta accesible incluye la lista completa y las kcal', (
      tester,
    ) async {
      final product = sampleFourCheese;
      await tester.pumpWidget(_cardFor(product, onAdd: () {}));

      final pressable = tester.widget<MotionPressable>(
        find.descendant(
          of: find.byType(ProductRowCard),
          matching: find.byType(MotionPressable),
        ),
      );
      expect(pressable.semanticLabel, contains('PIZZA 4 QUESOS'));
      expect(
        pressable.semanticLabel,
        contains('Masa madre · Salsa de tomate · Mozzarella'),
      );
      expect(pressable.semanticLabel, contains('Pizza'));
      expect(pressable.semanticLabel, isNot(contains('kcal')));
    });

    testWidgets('un texto corto no reserva 151 dp', (tester) async {
      final product = _product(
        name: 'AGUA',
        description: 'Fría.',
        ingredients: const ['Agua'],
      );
      await tester.pumpWidget(_cardFor(product));

      expect(
        tester.getSize(find.byType(ProductRowCard)).height,
        lessThan(151),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('la descripción se muestra en hasta dos líneas', (tester) async {
      final product = _product(
        description: 'La de la casa, con salsa especial y orégano.',
      );
      await tester.pumpWidget(_cardFor(product));

      final text = tester.widget<Text>(
        find.text('La de la casa, con salsa especial y orégano.'),
      );
      expect(text.maxLines, 2);
    });

    testWidgets('la tarjeta usa el resumen y no la descripción larga', (
      tester,
    ) async {
      final product = _product(
        summary: 'Resumen corto para la tarjeta.',
        description: 'Descripción larga que solo debe verse en el detalle.',
      );
      await tester.pumpWidget(_cardFor(product));

      expect(find.text('Resumen corto para la tarjeta.'), findsOneWidget);
      expect(find.textContaining('Descripción larga'), findsNothing);
    });

    testWidgets('el detalle muestra la descripción larga', (tester) async {
      usePhoneViewport(tester);
      final app = TestApp();
      await app.loadAll();
      addTearDown(app.dispose);
      final product = _product(
        id: 'detalle',
        summary: 'Resumen corto.',
        description: 'Descripción larga que solo debe verse en el detalle.',
      );

      await tester.pumpWidget(
        app.wrap(Scaffold(body: ProductDetailView(product: product))),
      );
      await tester.pump();

      expect(
        find.textContaining('Descripción larga que solo debe verse'),
        findsOneWidget,
      );
    });

    testWidgets('la tarjeta de favoritas usa el resumen y no deja hueco', (
      tester,
    ) async {
      final product = sampleFourCheese;
      await tester.pumpWidget(
        _wrap(
          Center(
            child: SizedBox(
              height: 392,
              child: FeaturedCard(
                image: const ColoredBox(color: Colors.black),
                title: product.name,
                priceLabel: 'S/ 38',
                description: product.displaySummary,
                categoryId: product.categoryId,
                summary: ProductSummary.of(product),
                onTap: () {},
                onAdd: () {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('Mozzarella · Queso parmesano · Queso azul · Queso edam'),
        findsOneWidget,
      );
      expect(find.text('AGREGAR'), findsOneWidget);
      expect(tester.getSize(find.byType(FeaturedCard)).height, 392);
    });

    testWidgets('el carrito del Inicio agrega al pedido, no navega', (
      tester,
    ) async {
      usePhoneViewport(tester, height: 2400);
      final app = TestApp();
      await app.loadAll();
      addTearDown(app.dispose);

      await tester.pumpWidget(
        app.wrap(
          Scaffold(
            body: HomeView(
              onGoToCarta: (_) {},
              onGoToSedes: () {},
              onGoToPromotions: () {},
              onGoToProduct: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      final card = tester.widget<FeaturedCard>(
        find.byType(FeaturedCard).first,
      );
      expect(card.onAdd, isNotNull);
      card.onAdd!();
      await tester.pump();

      expect(app.cart.count, greaterThan(0));
    });

    testWidgets('Recién horneadas muestra los combos pedidos', (tester) async {
      usePhoneViewport(tester);
      final combo = Product(
        id: 'combo-1',
        categoryId: 'combos',
        name: 'COMBO 1',
        description: 'Pizza + gaseosa 600 ml.',
        summary: 'Pizza mediana y gaseosa 600 ml.',
        variants: const [Variant(label: 'única', priceSoles: 21)],
      );
      final menu = MenuData(
        categories: const [
          MenuCategoryFixture.featured,
          MenuCategoryFixture.pizzas,
          MenuCategoryFixture.bebidas,
          MenuCategory(id: 'combos', name: 'COMBOS', order: 3),
        ],
        products: [combo],
      );
      final order = Order(
        id: 'o1',
        code: 'TOT-20261015-1234',
        uid: 'uid-1',
        createdAt: DateTime(2026, 10, 15, 13),
        type: OrderType.pickup,
        branchId: 'huancayo',
        branchName: 'HUANCAYO',
        items: const [
          CartItem(
            productId: 'combo-1',
            name: 'COMBO 1',
            variantLabel: 'única',
            unitPriceSoles: 21,
            quantity: 1,
          ),
        ],
        subtotalSoles: 21,
        shippingSoles: 0,
        totalSoles: 21,
        customerName: 'Ana',
        phone: '999999999',
        paymentMethodId: 'efectivo',
        paymentMethodLabel: 'Efectivo',
      );
      final app = TestApp(
        catalogRepository: FakeCatalogRepository(menu: menu),
        orderRepository: FakeOrderRepository(orders: [order]),
      );
      await app.loadAll();
      app.orders.bind('uid-1');
      await settleMicrotasks();
      expect(app.orders.orders, hasLength(1));
      addTearDown(app.dispose);

      await tester.pumpWidget(
        app.wrap(
          Scaffold(
            body: HomeView(
              onGoToCarta: (_) {},
              onGoToSedes: () {},
              onGoToPromotions: () {},
              onGoToProduct: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -900),
      );
      await tester.pump();

      expect(find.text('TUS COMBOS RECIENTES'), findsOneWidget);
      expect(find.text('COMBO 1'), findsWidgets);
    });

    testWidgets('los subtítulos de la ficha usan el ámbar', (tester) async {
      usePhoneViewport(tester);
      final app = TestApp();
      await app.loadAll();
      addTearDown(app.dispose);
      final product = app.catalog.menu.byId('pizza-totos')!;

      await tester.pumpWidget(
        app.wrap(Scaffold(body: ProductDetailView(product: product))),
      );
      await tester.pump();

      final label = tester.widget<Text>(find.text('INGREDIENTES'));
      expect(label.style?.color, ProductFamily.flameAccent);
      expect(find.text('CALORÍAS'), findsOneWidget);
      expect(find.text('1120 kcal'), findsWidgets);
    });

    testWidgets('la ficha muestra «No declarado» sin calorías', (tester) async {
      usePhoneViewport(tester);
      final app = TestApp();
      await app.loadAll();
      addTearDown(app.dispose);
      final product = app.catalog.menu.byId('coca-600')!;

      await tester.pumpWidget(
        app.wrap(Scaffold(body: ProductDetailView(product: product))),
      );
      await tester.pump();

      expect(find.text('CALORÍAS'), findsOneWidget);
      expect(find.text('No declarado'), findsWidgets);
    });
  });

  group('Carta', () {
    testWidgets('la lista es perezosa con 44 productos', (tester) async {
      usePhoneViewport(tester);
      final app = TestApp(
        catalogRepository: FakeCatalogRepository(menu: _bigMenu(44)),
      );
      await app.loadAll();
      addTearDown(app.dispose);

      await tester.pumpWidget(
        app.wrap(Scaffold(body: CartaView(onGoToProduct: (_) {}))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(ProductRowCard).evaluate().length, lessThan(44));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 600 dp la lista queda centrada y acotada', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 900);
      addTearDown(tester.view.reset);
      final app = TestApp(
        catalogRepository: FakeCatalogRepository(menu: _bigMenu(6)),
      );
      await app.loadAll();
      addTearDown(app.dispose);

      await tester.pumpWidget(
        app.wrap(Scaffold(body: CartaView(onGoToProduct: (_) {}))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final card = find.byType(ProductRowCard).first;
      final size = tester.getSize(card);
      final left = tester.getTopLeft(card).dx;
      expect(size.width, lessThanOrEqualTo(520));
      expect(left, closeTo(600 - left - size.width, 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('no desborda a 320 dp ni con texto al 130 %', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 900);
      addTearDown(tester.view.reset);
      final app = TestApp(
        catalogRepository: FakeCatalogRepository(menu: _bigMenu(6)),
      );
      await app.loadAll();
      addTearDown(app.dispose);

      await tester.pumpWidget(
        app.wrap(Scaffold(body: CartaView(onGoToProduct: (_) {}))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(411, 900);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);

      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = const Size(360, 900);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
    });

    testWidgets('la introducción queda en una sola frase', (tester) async {
      usePhoneViewport(tester);
      final app = TestApp(
        catalogRepository: FakeCatalogRepository(menu: _bigMenu(3)),
      );
      await app.loadAll();
      addTearDown(app.dispose);

      await tester.pumpWidget(
        app.wrap(Scaffold(body: CartaView(onGoToProduct: (_) {}))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.text('Elige tu favorita y la preparamos al momento.'),
        findsOneWidget,
      );
      expect(find.textContaining('Pizzas de masa madre'), findsNothing);
    });
  });

  group('Hero', () {
    Future<void> pumpHome(WidgetTester tester, double height) async {
      usePhoneViewport(tester, height: height);
      final app = TestApp();
      await app.loadAll();
      addTearDown(app.dispose);
      await tester.pumpWidget(
        app.wrap(
          Scaffold(
            body: HomeView(
              onGoToCarta: (_) {},
              onGoToSedes: () {},
              onGoToPromotions: () {},
              onGoToProduct: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('a 900 dp mide 460 y no tiene subtítulo', (tester) async {
      await pumpHome(tester, 900);
      final hero = tester.widget<HeroBanner>(find.byType(HeroBanner));
      expect(hero.height, 460);
      expect(hero.subtitle, isNull);
    });

    testWidgets('a 568 dp se limita al 62 %', (tester) async {
      await pumpHome(tester, 568);
      final hero = tester.widget<HeroBanner>(find.byType(HeroBanner));
      expect(hero.height, closeTo(568 * 0.62, 0.01));
    });

    testWidgets('en una pantalla muy baja no baja de 320 dp', (tester) async {
      await pumpHome(tester, 480);
      final hero = tester.widget<HeroBanner>(find.byType(HeroBanner));
      expect(hero.height, 320);
    });
  });

  group('DriveImage', () {
    Future<CachedNetworkImage> pumpImage(
      WidgetTester tester,
      Widget image, {
      double dpr = 3,
    }) async {
      tester.view.devicePixelRatio = dpr;
      tester.view.physicalSize = Size(360 * dpr, 900 * dpr);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(Center(child: image)));
      await tester.pump();
      return tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
    }

    testWidgets('la tarjeta pide el ancho del recorte', (tester) async {
      final image = await pumpImage(
        tester,
        const SizedBox(
          width: 126,
          height: 128,
          child: DriveImage(media: MediaRef(driveId: _driveId)),
        ),
      );

      expect(image.imageUrl, contains('sz=w768'));
      expect(image.memCacheWidth, 768);
    });

    testWidgets('una tarjeta alta pide más ancho', (tester) async {
      final image = await pumpImage(
        tester,
        const SizedBox(
          width: 126,
          height: 177,
          child: DriveImage(media: MediaRef(driveId: _driveId)),
        ),
      );

      expect(image.imageUrl, contains('sz=w1088'));
    });

    testWidgets('el detalle a sangre conserva el ancho de pantalla', (
      tester,
    ) async {
      final image = await pumpImage(
        tester,
        const SizedBox(
          width: 360,
          height: 345,
          child: DriveImage(
            media: MediaRef(driveId: _driveId),
            requestWidth: 360,
          ),
        ),
      );

      expect(image.imageUrl, contains('sz=w1080'));
    });

    testWidgets('la galería usa su propio bucket', (tester) async {
      final image = await pumpImage(
        tester,
        const SizedBox(
          width: 140,
          height: 120,
          child: DriveImage(media: MediaRef(driveId: _driveId)),
        ),
      );

      expect(image.imageUrl, contains('sz=w768'));
    });
  });
}

