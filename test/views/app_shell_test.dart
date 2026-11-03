import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/app/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/harness.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('monta los cinco destinos a 360 dp sin desbordes', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();
    await app.signIn();

    await tester.pumpWidget(app.wrap(const AppShell()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(logicalWidth(tester), 360);

    for (final label in ['Inicio', 'Carta', 'Promos', 'Sedes', 'Soporte']) {
      expect(
        find.text(label),
        findsOneWidget,
        reason: 'falta el destino $label',
      );
    }

    int tabIndex() {
      final pager = tester.widget<PageView>(
        find.byKey(const ValueKey('shell-pager')),
      );
      return (pager.controller?.page ?? 0).round();
    }

    expect(tabIndex(), 0);
    await tester.tap(find.text('Carta'));
    await tester.pumpAndSettle();
    expect(tabIndex(), 1);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Promos'));
    await tester.pumpAndSettle();
    expect(tabIndex(), 2);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Sedes'));
    await tester.pumpAndSettle();
    expect(tabIndex(), 3);
    expect(find.text('HUANCAYO'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Soporte'));
    await tester.pumpAndSettle();
    expect(tabIndex(), 4);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(tabIndex(), 0);
    expect(find.text("BIENVENIDO A TOTO'S"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin sesión no muestra Soporte ni Planes en la barra inferior', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();

    await tester.pumpWidget(app.wrap(const AppShell()));
    await tester.pumpAndSettle();

    for (final label in ['Inicio', 'Carta', 'Promos', 'Sedes']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Soporte'), findsNothing);
    expect(find.text('Planes'), findsNothing);
    expect(find.text('Pedido'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desliza entre las pestañas de navegación', (tester) async {
    usePhoneViewport(tester);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();
    await app.signIn();

    await tester.pumpWidget(app.wrap(const AppShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carta'));
    await tester.pumpAndSettle();

    int tabIndex() {
      final pager = tester.widget<PageView>(
        find.byKey(const ValueKey('shell-pager')),
      );
      return (pager.controller?.page ?? 0).round();
    }

    expect(tabIndex(), 1);

    await tester.fling(
      find.byKey(const ValueKey('shell-pager')),
      const Offset(-320, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(tabIndex(), 2);

    await tester.fling(
      find.byKey(const ValueKey('shell-pager')),
      const Offset(320, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(tabIndex(), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('las rutas sobre el shell conservan los providers', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();
    await app.signIn();

    await tester.pumpWidget(app.wrap(const AppShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();

    // Sin `AppScope` por encima del Navigator esto lanzaba
    // `ProviderNotFoundException` al abrir el perfil.
    expect(tester.takeException(), isNull);
    expect(find.text('Nombre'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text("BIENVENIDO A TOTO'S"), findsOneWidget);
  });

  testWidgets('no queda dashboard, rol admin ni conmutador de tema', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();

    await tester.pumpWidget(app.wrap(const AppShell()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Dashboard'), findsNothing);
    expect(find.textContaining('dashboard'), findsNothing);
    expect(find.textContaining('Admin'), findsNothing);
    expect(find.textContaining('admin', findRichText: true), findsNothing);
    expect(find.byIcon(Icons.brightness_6_rounded), findsNothing);
    expect(find.byIcon(Icons.light_mode_outlined), findsNothing);
    expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);
    expect(find.textContaining('Modo claro'), findsNothing);
  });

  testWidgets('el aviso offline aparece y desaparece sin romper el flujo', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final app = TestApp(online: false);
    addTearDown(app.dispose);
    await app.loadAll();

    await tester.pumpWidget(app.wrap(const AppShell()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sin conexión'), findsWidgets);

    app.connectivity.setOnline(true);
    await tester.pumpAndSettle();
    expect(find.textContaining('Sin conexión'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('las sedes listadas son solo las de Huancayo', (tester) async {
    usePhoneViewport(tester);
    final app = TestApp();
    addTearDown(app.dispose);
    await app.loadAll();

    await tester.pumpWidget(app.wrap(const AppShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sedes'));
    await tester.pumpAndSettle();

    expect(find.textContaining('CHUPACA'), findsNothing);
    expect(find.textContaining('JAUJA'), findsNothing);
    expect(find.textContaining('Chupaca'), findsNothing);
    expect(find.textContaining('Jauja'), findsNothing);
  });
}
