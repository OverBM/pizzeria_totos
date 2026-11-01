import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/app/app_shell.dart';
import 'package:pizzeria_totos/core/app_info.dart';
import 'package:pizzeria_totos/widgets/widgets.dart';
import 'package:pizzeria_totos/models/category.dart';
import 'package:pizzeria_totos/models/menu_data.dart';
import 'package:pizzeria_totos/models/product.dart';
import 'package:pizzeria_totos/models/variant.dart';
import 'package:pizzeria_totos/repositories/repository_exception.dart';
import 'package:pizzeria_totos/views/auth/login_view.dart';
import 'package:pizzeria_totos/views/carta/carta_view.dart';
import 'package:pizzeria_totos/views/carta/product_detail_view.dart';
import 'package:pizzeria_totos/views/home/home_view.dart';
import 'package:pizzeria_totos/views/profile/profile_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/harness.dart';

/// Repositorio de perfiles que rechaza la eliminación de direcciones.
class _FailingProfileRepository extends FakeProfileRepository {
  @override
  Future<void> removeAddress({
    required String uid,
    required String addressId,
  }) async {
    throw const RepositoryException('No se pudo eliminar la dirección.');
  }
}

MenuData _menu({
  List<MenuCategory> categories = const [
    MenuCategory(id: 'pizzas', name: 'PIZZAS', order: 1),
  ],
  List<Product> products = const [],
}) => MenuData(categories: categories, products: products);

void main() {
  setUpAll(loadBrandFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    useDeterministicCursor();
  });

  Future<TestApp> ready({
    MenuData? menu,
    FakeProfileRepository? profileRepository,
    bool online = true,
  }) async {
    final app = TestApp(
      online: online,
      catalogRepository: menu == null ? null : FakeCatalogRepository(menu: menu),
      profileRepository: profileRepository,
    );
    await app.loadAll();
    return app;
  }

  Widget home({
    DateTime Function()? now,
    void Function(String?)? onGoToCarta,
  }) => HomeView(
    onGoToCarta: onGoToCarta ?? (_) {},
    onGoToSedes: () {},
    onGoToPromotions: () {},
    onGoToProduct: (_) {},
    now: now,
  );

  testWidgets('el Inicio muestra productos aunque no haya destacados', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final app = await ready(
      menu: _menu(
        products: const [
          Product(
            id: 'p1',
            categoryId: 'pizzas',
            name: 'PIZZA MARGHERITA',
            description: 'Tomate y albahaca.',
            variants: [Variant(label: 'entera', priceSoles: 30)],
          ),
        ],
      ),
    );
    addTearDown(app.dispose);

    await tester.pumpWidget(app.wrap(Scaffold(body: home())));
    await tester.pumpAndSettle();

    expect(find.byType(FeaturedCard), findsOneWidget);
    expect(find.text('PIZZA MARGHERITA'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('categorías sin productos muestran estado explícito', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final app = await ready(menu: _menu());
    addTearDown(app.dispose);

    await tester.pumpWidget(app.wrap(Scaffold(body: home())));
    await tester.pumpAndSettle();
    expect(find.text('NO HAY PRODUCTOS DISPONIBLES'), findsOneWidget);

    await tester.pumpWidget(
      app.wrap(Scaffold(body: CartaView(onGoToProduct: (_) {}))),
    );
    await tester.pumpAndSettle();
    expect(find.text('NO HAY PRODUCTOS DISPONIBLES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la Carta muestra un solo «Las más pedidas»', (tester) async {
    usePhoneViewport(tester);
    // El catálogo de ejemplo incluye el documento real `mas-pedidas`.
    final app = await ready();
    addTearDown(app.dispose);

    await tester.pumpWidget(
      app.wrap(Scaffold(body: CartaView(onGoToProduct: (_) {}))),
    );
    await tester.pumpAndSettle();

    expect(find.text('LAS MÁS PEDIDAS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('una categoría vacía muestra su estado', (tester) async {
    usePhoneViewport(tester);
    final app = await ready(
      menu: _menu(
        categories: const [
          MenuCategory(id: 'pizzas', name: 'PIZZAS', order: 1),
          MenuCategory(id: 'bebidas', name: 'BEBIDAS', order: 2),
        ],
        products: const [
          Product(
            id: 'p1',
            categoryId: 'pizzas',
            name: 'PIZZA MARGHERITA',
            description: 'Tomate y albahaca.',
            variants: [Variant(label: 'entera', priceSoles: 30)],
          ),
        ],
      ),
    );
    addTearDown(app.dispose);

    await tester.pumpWidget(
      app.wrap(Scaffold(body: CartaView(onGoToProduct: (_) {}))),
    );
    await tester.pumpAndSettle();

    app.catalog.selectCategory('bebidas');
    await tester.pumpAndSettle();

    expect(find.text('NO HAY PRODUCTOS EN ESTA CATEGORÍA'), findsOneWidget);
    expect(find.text('VER TODOS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un producto sin variantes no rompe la Carta', (tester) async {
    usePhoneViewport(tester);
    final app = await ready(
      menu: _menu(
        products: const [
          Product(
            id: 'sin-variantes',
            categoryId: 'pizzas',
            name: 'SIN VARIANTES',
            description: 'Documento incompleto.',
            variants: [],
          ),
          Product(
            id: 'agotado',
            categoryId: 'pizzas',
            name: 'AGOTADO',
            description: 'No disponible.',
            available: false,
            variants: [Variant(label: 'única', priceSoles: 10)],
          ),
        ],
      ),
    );
    addTearDown(app.dispose);

    await tester.pumpWidget(
      app.wrap(Scaffold(body: CartaView(onGoToProduct: (_) {}))),
    );
    await tester.pumpAndSettle();

    expect(find.text('SIN VARIANTES'), findsWidgets);
    expect(find.text('No disponible'), findsOneWidget);
    // Un producto agotado no se ofrece en la lista.
    expect(find.text('AGOTADO'), findsNothing);
    // Sin variante no hay precio inventado ni acción de agregar.
    expect(find.byIcon(Icons.add_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el detalle de un producto sin variantes no se rompe', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final app = await ready();
    addTearDown(app.dispose);

    const product = Product(
      id: 'sin-variantes',
      categoryId: 'pizzas',
      name: 'SIN VARIANTES',
      description: 'Documento incompleto.',
      variants: [],
    );

    await tester.pumpWidget(
      app.wrap(const Scaffold(body: ProductDetailView(product: product))),
    );
    await tester.pumpAndSettle();

    expect(find.text('NO DISPONIBLE'), findsOneWidget);
    final button = tester.widget<PillButton>(
      find.widgetWithText(PillButton, 'AGREGAR'),
    );
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el perfil sin sesión redirige al login', (tester) async {
    usePhoneViewport(tester, height: 1400);
    final app = await ready();
    addTearDown(app.dispose);

    await tester.pumpWidget(app.wrap(const ProfileView()));
    await tester.pumpAndSettle();

    expect(find.text('INICIAR SESIÓN'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el perfil muestra ${AppInfo.label} con sesión y sin número de build', (
    tester,
  ) async {
    usePhoneViewport(tester, height: 2400);
    final app = await ready();
    addTearDown(app.dispose);
    await app.signIn();

    await tester.pumpWidget(app.wrap(const ProfileView()));
    await tester.pumpAndSettle();

    expect(find.text(AppInfo.label), findsOneWidget);
    expect(find.textContaining('build'), findsNothing);
    expect(find.textContaining('${AppInfo.label}+'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la barra superior no repite la versión', (tester) async {
    usePhoneViewport(tester, height: 1600);
    final app = await ready();
    addTearDown(app.dispose);

    await tester.pumpWidget(app.wrap(const AppShell()));
    await tester.pumpAndSettle();

    expect(find.byType(TotoTopBar), findsOneWidget);
    expect(find.text(AppInfo.label), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la recuperación no cierra con un correo inválido', (
    tester,
  ) async {
    usePhoneViewport(tester, height: 1200);
    final app = await ready();
    addTearDown(app.dispose);

    await tester.pumpWidget(app.wrap(const Scaffold(body: LoginView())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OLVIDÉ MI CONTRASEÑA'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    final field = find.descendant(
      of: dialog,
      matching: find.byType(TextFormField),
    );

    await tester.enterText(field, 'ana@');
    await tester.tap(find.descendant(of: dialog, matching: find.text('ENVIAR')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('El correo no tiene un formato válido.'), findsOneWidget);

    await tester.enterText(field, 'ana@ejemplo.com');
    await tester.tap(find.descendant(of: dialog, matching: find.text('ENVIAR')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la sede del Inicio se muestra cerrada fuera de horario', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final app = await ready();
    addTearDown(app.dispose);

    await tester.pumpWidget(
      app.wrap(
        Scaffold(
          // 03:00 en Lima: fuera de 12:45–21:30.
          body: home(now: () => DateTime(2026, 10, 15, 3)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('CERRADA'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('CERRADA'), findsOneWidget);
    expect(find.text('ABIERTA'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el perfil cambia los campos al cambiar de cuenta', (
    tester,
  ) async {
    usePhoneViewport(tester, height: 2400);
    final app = await ready();
    addTearDown(app.dispose);
    await app.signIn();

    await tester.pumpWidget(app.wrap(const ProfileView()));
    await tester.pumpAndSettle();
    expect(find.text('Ana Torres'), findsWidgets);

    await app.signIn(
      account: sampleAccount(
        uid: 'uid-2',
        name: 'Beto Ruiz',
        email: 'beto@example.com',
        phone: '988 777 666',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beto Ruiz'), findsWidgets);
    expect(find.text('Ana Torres'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('eliminar una dirección fallida avisa y conserva la dirección', (
    tester,
  ) async {
    usePhoneViewport(tester, height: 2400);
    final app = await ready(profileRepository: _FailingProfileRepository());
    addTearDown(app.dispose);
    await app.signIn();

    await tester.pumpWidget(app.wrap(const ProfileView()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Acciones de Casa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);

    await tester.tap(
      find.descendant(of: dialog, matching: find.text('ELIMINAR')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo eliminar'), findsOneWidget);
    expect(find.text('CASA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
