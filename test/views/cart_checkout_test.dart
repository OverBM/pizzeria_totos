import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/models/account.dart';
import 'package:pizzeria_totos/models/category.dart';
import 'package:pizzeria_totos/models/delivery_quote.dart';
import 'package:pizzeria_totos/models/menu_data.dart';
import 'package:pizzeria_totos/models/order.dart';
import 'package:pizzeria_totos/models/product.dart';
import 'package:pizzeria_totos/models/product_option.dart';
import 'package:pizzeria_totos/models/variant.dart';
import 'package:pizzeria_totos/views/cart/cart_screen.dart';
import 'package:pizzeria_totos/views/cart/cart_view.dart';
import 'package:pizzeria_totos/views/carta/combo_configurator_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/harness.dart';

const _comboMenu = MenuData(
  categories: [
    MenuCategory(id: 'combos', name: 'COMBOS', order: 1),
    MenuCategory(id: 'bebidas', name: 'BEBIDAS', order: 2),
  ],
  products: [
    Product(
      id: 'combo-1',
      categoryId: 'combos',
      name: 'COMBO 1',
      description: 'Pizza mediana y gaseosa.',
      componentes: [
        ProductComponent(
          nombre: 'Pizza mediana',
          cantidad: 1,
          opciones: ['Americana', 'Peperoni'],
        ),
        ProductComponent(
          nombre: 'Gaseosa 600 ml',
          cantidad: 1,
          opciones: ['Coca-Cola', 'Inca Kola'],
        ),
      ],
      extras: [ProductExtra(nombre: 'Extra queso', precioSoles: 4)],
      variants: [Variant(label: 'única', priceSoles: 20.9)],
    ),
    Product(
      id: 'coca-600',
      categoryId: 'bebidas',
      name: 'COCA COLA 600 ML',
      description: 'Bien fría.',
      variants: [Variant(label: 'única', priceSoles: 5)],
    ),
  ],
);

Widget _cartView({
  VoidCallback? onGoToCarta,
  VoidCallback? onOpenAuth,
  VoidCallback? onOpenProfile,
  VoidCallback? onOpenOrders,
}) => CartView(
  onGoToCarta: onGoToCarta ?? () {},
  onOpenAuth: onOpenAuth ?? () {},
  onOpenProfile: onOpenProfile ?? () {},
  onOpenOrders: onOpenOrders ?? () {},
);

Widget _cartScreen(TestApp app) => app.wrap(
  CartScreen(
    onGoToCarta: () {},
    onOpenAuth: () {},
    onOpenProfile: () {},
    onOpenOrders: () {},
  ),
);

void main() {
  setUpAll(loadBrandFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    useDeterministicCursor();
  });

  testWidgets('carrito vacío invita a la carta', (tester) async {
    usePhoneViewport(tester, height: 2400);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();

    await tester.pumpWidget(app.wrap(Scaffold(body: _cartView())));
    await tester.pumpAndSettle();

    expect(find.text('TU PEDIDO ESTÁ VACÍO'), findsOneWidget);
    expect(find.text('VER LA CARTA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin sesión muestra el aviso y el paso 1', (tester) async {
    usePhoneViewport(tester, height: 2400);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();
    final product = app.catalog.menu.byId('pizza-totos')!;
    app.cart.add(product, product.variants.first);

    await tester.pumpWidget(_cartScreen(app));
    await tester.pumpAndSettle();

    expect(
      find.text('Inicia sesión para confirmar tu pedido con tus datos.'),
      findsOneWidget,
    );
    expect(find.text('CONTINUAR CON LA ENTREGA'), findsOneWidget);
    expect(find.text('PARA MÍ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el checkout usa el perfil y no pide datos personales', (
    tester,
  ) async {
    usePhoneViewport(tester, height: 3200);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();
    await app.signIn(account: sampleAccount(phone: '999 111 222'));

    final product = app.catalog.menu.byId('pizza-totos')!;
    app.cart.add(product, product.variants.first);
    app.checkout.initDefaults();
    app.checkout.setDeliveryPoint(
      const DeliveryPoint(
        lat: -12.0651,
        lng: -75.2049,
        label: 'Av. Giráldez 123, Huancayo',
      ),
    );
    await settleMicrotasks();

    await tester.pumpWidget(_cartScreen(app));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUAR CON LA ENTREGA'));
    await tester.pumpAndSettle();
    expect(find.text('ENTREGA'), findsWidgets);
    expect(find.text('CONTINUAR AL PAGO'), findsOneWidget);

    await tester.tap(find.text('CONTINUAR AL PAGO'));
    await tester.pumpAndSettle();
    expect(find.text('CONFIRMAR'), findsWidgets);
    expect(find.text('CONFIRMAR PEDIDO'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Nombre'), findsNothing);
    expect(find.text('Teléfono'), findsNothing);
    expect(find.text('Dirección'), findsNothing);
    expect(find.text('Para mí'), findsOneWidget);
    expect(find.text('999 111 222'), findsWidgets);
    expect(find.text('Av. Giráldez 123, Huancayo'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin teléfono ni dirección explica qué falta y ofrece el atajo', (
    tester,
  ) async {
    usePhoneViewport(tester, height: 3200);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();
    await app.signIn(
      account: const Account(uid: 'uid-1', name: 'Ana', email: 'a@b.c'),
    );

    final product = app.catalog.menu.byId('pizza-totos')!;
    app.cart.add(product, product.variants.first);
    app.checkout.initDefaults();
    app.checkout.setType(OrderType.pickup);
    await settleMicrotasks();

    await tester.pumpWidget(_cartScreen(app));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUAR CON LA ENTREGA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUAR AL PAGO'));
    await tester.pumpAndSettle();

    expect(
      find.text('Completa tu teléfono en el perfil para coordinar la entrega.'),
      findsOneWidget,
    );
    expect(find.text('COMPLETAR PERFIL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmar registra el pedido y muestra el código', (
    tester,
  ) async {
    usePhoneViewport(tester, height: 3200);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();
    await app.signIn(account: sampleAccount(phone: '999 111 222'));

    final product = app.catalog.menu.byId('pizza-totos')!;
    app.cart.add(product, product.variants.first);
    app.checkout.initDefaults();
    app.checkout.setDeliveryPoint(
      const DeliveryPoint(
        lat: -12.0651,
        lng: -75.2049,
        label: 'Av. Giráldez 123, Huancayo',
      ),
    );
    await settleMicrotasks();

    await tester.pumpWidget(_cartScreen(app));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUAR CON LA ENTREGA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUAR AL PAGO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONFIRMAR PEDIDO'));
    await tester.pumpAndSettle();

    final order = app.orderRepository.orders.single;
    expect(order.uid, 'uid-1');
    expect(order.status.name, 'pendiente_confirmacion');
    expect(order.customerName, 'Ana Torres');
    expect(order.phone, '999 111 222');
    expect(order.address, 'Av. Giráldez 123, Huancayo');
    expect(order.distanciaKm, 3.2);
    expect(order.tramo, 'Tramo 2 · 2–4 km');
    expect(find.text('PEDIDO REGISTRADO'), findsOneWidget);
    expect(find.text('#${order.code}'), findsOneWidget);
    expect(find.text('CONTINUAR POR WHATSAPP'), findsOneWidget);
    expect(app.cart.isEmpty, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('elegir una sede sin delivery cambia a recojo', (tester) async {
    usePhoneViewport(tester, height: 2400);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();
    await app.signIn(account: sampleAccount(phone: '999 111 222'));

    final product = app.catalog.menu.byId('pizza-totos')!;
    app.cart.add(product, product.variants.first);
    app.checkout.initDefaults();

    await tester.pumpWidget(_cartScreen(app));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUAR CON LA ENTREGA'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CHILCA'));
    await tester.pumpAndSettle();

    expect(app.checkout.type, OrderType.pickup);
    expect(app.checkout.shippingSoles, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('carrito muestra detalle, sugerencias y vaciar', (tester) async {
    usePhoneViewport(tester, height: 3200);
    final app = TestApp(
      catalogRepository: FakeCatalogRepository(menu: _comboMenu),
    );
    addTearDown(app.dispose);
    await app.loadAll();

    final combo = app.catalog.menu.byId('combo-1')!;
    app.cart.add(
      combo,
      combo.variants.first,
      componentes: const [
        SelectedComponent(
          nombre: 'Pizza mediana',
          cantidad: 1,
          opcion: 'Americana',
        ),
      ],
      extras: const [
        ProductExtra(nombre: 'Extra queso', precioSoles: 4),
      ],
    );

    await tester.pumpWidget(app.wrap(Scaffold(body: _cartView())));
    await tester.pumpAndSettle();

    expect(find.text('VER DETALLE DEL PEDIDO'), findsOneWidget);
    await tester.tap(find.text('VER DETALLE DEL PEDIDO'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pizza mediana'), findsWidgets);
    expect(find.textContaining('Extra queso'), findsWidgets);
    expect(find.text('COMPLEMENTA TU PEDIDO'), findsOneWidget);

    await tester.tap(find.text('VACIAR'));
    await tester.pumpAndSettle();
    expect(find.text('VACIAR CARRITO'), findsOneWidget);
    await tester.tap(find.text('VACIAR').last);
    await tester.pumpAndSettle();
    expect(find.text('TU PEDIDO ESTÁ VACÍO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('configurador de combo permite elegir opciones y extras', (
    tester,
  ) async {
    usePhoneViewport(tester, height: 2400);
    final app = TestApp(
      catalogRepository: FakeCatalogRepository(menu: _comboMenu),
    );
    addTearDown(app.dispose);
    await app.loadAll();
    final combo = app.catalog.menu.byId('combo-1')!;

    await tester.pumpWidget(
      app.wrap(
        Scaffold(
          body: ComboConfiguratorSheet(
            product: combo,
            variant: combo.variants.first,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PERSONALIZA TU COMBO 1'), findsOneWidget);
    expect(find.text('AMERICANA'), findsOneWidget);
    await tester.tap(find.text('Extra queso'));
    await tester.pumpAndSettle();
    expect(find.text('S/ 24.90'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
