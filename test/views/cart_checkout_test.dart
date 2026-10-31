import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/models/account.dart';
import 'package:pizzeria_totos/models/order.dart';
import 'package:pizzeria_totos/views/cart/cart_view.dart';
import 'package:pizzeria_totos/widgets/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/harness.dart';

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

  testWidgets('sin sesión pide iniciar sesión antes de confirmar', (
    tester,
  ) async {
    usePhoneViewport(tester, height: 2400);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();
    final product = app.catalog.menu.byId('pizza-totos')!;
    app.cart.add(product, product.variants.first);

    await tester.pumpWidget(app.wrap(Scaffold(body: _cartView())));
    await tester.pumpAndSettle();

    expect(
      find.text('Inicia sesión para confirmar tu pedido con tus datos.'),
      findsOneWidget,
    );
    expect(find.text('INICIA SESIÓN PARA PEDIR'), findsOneWidget);
    expect(
      find.text('Inicia sesión para confirmar tu pedido.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('el checkout usa el perfil y no pide datos personales', (
    tester,
  ) async {
    usePhoneViewport(tester, height: 2400);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();
    await app.signIn(account: sampleAccount(phone: '999 111 222'));

    final product = app.catalog.menu.byId('pizza-totos')!;
    app.cart.add(product, product.variants.first);
    app.checkout.initDefaults();
    await tester.pump();

    await tester.pumpWidget(app.wrap(Scaffold(body: _cartView())));
    await tester.pumpAndSettle();

    // 6.9: ningún campo editable de nombre, teléfono o dirección.
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Nombre'), findsNothing);
    expect(find.text('Teléfono'), findsNothing);
    expect(find.text('Dirección'), findsNothing);
    expect(find.text('Referencia'), findsNothing);

    // Los datos llegan del documento `users/{uid}`.
    expect(find.text('ANA TORRES'), findsOneWidget);
    expect(find.text('999 111 222'), findsOneWidget);
    expect(find.text('Av. Giráldez 123, Huancayo'), findsWidgets);

    // Y el pedido puede confirmarse sin volver a escribirlos.
    expect(find.text('CONFIRMAR PEDIDO'), findsOneWidget);
    expect(find.text('Completa tu teléfono en el perfil'), findsNothing);
    expect(
      find.text('Agrega una dirección de entrega en tu perfil.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin teléfono ni dirección explica qué falta y ofrece el atajo', (
    tester,
  ) async {
    usePhoneViewport(tester, height: 2400);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();
    await app.signIn(
      account: const Account(uid: 'uid-1', name: 'Ana', email: 'a@b.c'),
    );

    final product = app.catalog.menu.byId('pizza-totos')!;
    app.cart.add(product, product.variants.first);
    app.checkout.initDefaults();
    await tester.pump();

    await tester.pumpWidget(app.wrap(Scaffold(body: _cartView())));
    await tester.pumpAndSettle();

    expect(
      find.text('Completa tu teléfono en el perfil para coordinar la entrega.'),
      findsOneWidget,
    );
    expect(
      find.text('Agrega una dirección de entrega en tu perfil.'),
      findsOneWidget,
    );
    expect(find.text('COMPLETAR PERFIL'), findsOneWidget);
    expect(find.text('AGREGAR DIRECCIÓN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmar registra el pedido y muestra el código', (
    tester,
  ) async {
    usePhoneViewport(tester, height: 2400);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();
    await app.signIn(account: sampleAccount(phone: '999 111 222'));

    final product = app.catalog.menu.byId('pizza-totos')!;
    app.cart.add(product, product.variants.first);
    app.checkout.initDefaults();
    await tester.pump();

    await tester.pumpWidget(app.wrap(Scaffold(body: _cartView())));
    await tester.pumpAndSettle();

    expect(find.byType(RemoveLineButton), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Descuento'), findsOneWidget);

    await tester.tap(find.text('CONFIRMAR PEDIDO'));
    await tester.pumpAndSettle();

    final order = app.orderRepository.orders.single;
    expect(order.uid, 'uid-1');
    expect(order.status.name, 'pendiente_confirmacion');
    expect(order.customerName, 'Ana Torres');
    expect(order.phone, '999 111 222');
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

    await tester.pumpWidget(app.wrap(Scaffold(body: _cartView())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CHILCA'));
    await tester.pumpAndSettle();

    expect(app.checkout.type, OrderType.pickup);
    expect(app.checkout.shippingSoles, 0);
    expect(tester.takeException(), isNull);
  });
}
