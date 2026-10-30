import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/views/branches/branches_view.dart';
import 'package:pizzeria_totos/views/carta/carta_view.dart';
import 'package:pizzeria_totos/views/carta/product_detail_view.dart';
import 'package:pizzeria_totos/views/cart/orders_view.dart';
import 'package:pizzeria_totos/views/claims/claims_view.dart';
import 'package:pizzeria_totos/widgets/widgets.dart';
import 'package:pizzeria_totos/views/home/home_view.dart';
import 'package:pizzeria_totos/views/profile/profile_view.dart';
import 'package:pizzeria_totos/views/promotions/promotions_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/harness.dart';

void main() {
  setUpAll(loadBrandFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    useDeterministicCursor();
  });

  Future<TestApp> ready({bool online = true}) async {
    final app = TestApp(online: online);
    await app.loadAll();
    return app;
  }

  testWidgets('inicio editorial a 360 dp', (tester) async {
    usePhoneViewport(tester);
    final app = await ready();
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
    await tester.pumpAndSettle();

    final hero = tester.widget<HeroBanner>(find.byType(HeroBanner));
    expect(hero.title, 'PIZZA');
    expect(hero.titleTail, '(Y PASTAS)');

    // El inicio es un scroll editorial: se recorre completo sin desbordar.
    expect(find.byType(CustomScrollView), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('carta con filtros y productos', (tester) async {
    usePhoneViewport(tester);
    final app = await ready();
    addTearDown(app.dispose);

    await tester.pumpWidget(
      app.wrap(Scaffold(body: CartaView(onGoToProduct: (_) {}))),
    );
    await tester.pumpAndSettle();

    expect(find.text("PIZZA TOTO'S"), findsWidgets);

    app.catalog.selectCategory('bebidas');
    await tester.pumpAndSettle();
    expect(find.text('COCA COLA 600 ML'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detalle de producto con variantes y CTA', (tester) async {
    usePhoneViewport(tester);
    final app = await ready();
    addTearDown(app.dispose);
    final product = app.catalog.menu.byId('pizza-totos')!;

    await tester.pumpWidget(
      app.wrap(Scaffold(body: ProductDetailView(product: product))),
    );
    await tester.pumpAndSettle();

    expect(find.text('INGREDIENTES'), findsOneWidget);
    expect(find.text('CALORÍAS'), findsOneWidget);
    expect(find.text('AGREGAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sedes de Huancayo con horario y delivery', (tester) async {
    usePhoneViewport(tester);
    final app = await ready();
    addTearDown(app.dispose);

    await tester.pumpWidget(app.wrap(const Scaffold(body: BranchesView())));
    await tester.pumpAndSettle();

    expect(find.text('HUANCAYO'), findsWidgets);
    expect(find.text('EL TAMBO'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('promociones con precio promocional', (tester) async {
    usePhoneViewport(tester);
    final app = await ready();
    addTearDown(app.dispose);

    await tester.pumpWidget(
      app.wrap(
        Scaffold(body: PromotionsView(onOpenProduct: (_, {variantLabel}) {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('PIZZA TOTO'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('promociones vacías muestran estado explícito', (tester) async {
    usePhoneViewport(tester);
    final app = TestApp(
      promotionRepository: FakePromotionRepository(promotions: const []),
    );
    await app.loadAll();
    addTearDown(app.dispose);

    await tester.pumpWidget(
      app.wrap(
        Scaffold(body: PromotionsView(onOpenProduct: (_, {variantLabel}) {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SIN PROMOCIONES POR AHORA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reclamos: historial vacío y formulario', (tester) async {
    usePhoneViewport(tester, height: 1800);
    final app = await ready();
    addTearDown(app.dispose);
    await app.signIn();

    await tester.pumpWidget(
      app.wrap(
        Scaffold(
          body: ClaimsView(onOpenAuth: () {}, onOpenClaim: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cuéntanos qué pasó'), findsOneWidget);
    expect(find.text('HISTORIAL'), findsOneWidget);
    expect(find.text('Motivo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reclamos sin sesión no permiten enviar', (tester) async {
    usePhoneViewport(tester);
    final app = await ready();
    addTearDown(app.dispose);

    await tester.pumpWidget(
      app.wrap(
        Scaffold(
          body: ClaimsView(onOpenAuth: () {}, onOpenClaim: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cuéntanos qué pasó'), findsNothing);
    expect(find.textContaining('Inicia sesión'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('perfil muestra campos del documento users/{uid}', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final app = await ready();
    addTearDown(app.dispose);
    await app.signIn();

    await tester.pumpWidget(app.wrap(const ProfileView()));
    await tester.pumpAndSettle();

    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Teléfono / WhatsApp'), findsOneWidget);
    expect(find.text('TUS DIRECCIONES'), findsOneWidget);
    expect(find.text('AGREGAR'), findsOneWidget);
    expect(find.text('CASA'), findsOneWidget);
    // Sin conmutador de tema ni acceso a un panel de administración.
    expect(find.byIcon(Icons.brightness_6_rounded), findsNothing);
    expect(find.textContaining('Rol'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('perfil offline avisa que usa datos guardados', (tester) async {
    usePhoneViewport(tester);
    final app = await ready(online: false);
    addTearDown(app.dispose);
    await app.signIn();

    await tester.pumpWidget(app.wrap(const ProfileView()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sin conexión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('historial de pedidos vacío tras iniciar sesión', (tester) async {
    usePhoneViewport(tester);
    final app = await ready();
    addTearDown(app.dispose);
    await app.signIn();
    app.orders.bind('uid-1');

    await tester.pumpWidget(app.wrap(const OrdersView()));
    // Sin `pumpAndSettle`: el esqueleto de carga late sin parar.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('AÚN NO TIENES PEDIDOS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('historial muestra solo los pedidos del uid', (tester) async {
    usePhoneViewport(tester);
    final app = TestApp(
      orderRepository: FakeOrderRepository(
        orders: [
          sampleOrder(uid: 'uid-1'),
          sampleOrder(uid: 'uid-2', code: 'TOT-20261015-9999'),
        ],
      ),
    );
    await app.loadAll();
    addTearDown(app.dispose);
    await app.signIn();
    app.orders.bind('uid-1');

    await tester.pumpWidget(app.wrap(const OrdersView()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('TOT-20261015-1234'), findsOneWidget);
    expect(find.textContaining('TOT-20261015-9999'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
