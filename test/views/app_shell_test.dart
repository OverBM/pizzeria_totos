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

    await tester.pumpWidget(app.wrap(const AppShell()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(logicalWidth(tester), 360);

    for (final label in ['Inicio', 'Carta', 'Pedido', 'Sedes', 'Reclamos']) {
      expect(
        find.text(label),
        findsOneWidget,
        reason: 'falta el destino $label',
      );
    }

    int tabIndex() =>
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index ?? -1;

    expect(tabIndex(), 0);
    await tester.tap(find.text('Carta'));
    await tester.pumpAndSettle();
    expect(tabIndex(), 1);

    await tester.tap(find.text('Pedido'));
    await tester.pumpAndSettle();
    expect(tabIndex(), 2);
    expect(find.text('TU PEDIDO ESTÁ VACÍO'), findsOneWidget);

    await tester.tap(find.text('Sedes'));
    await tester.pumpAndSettle();
    expect(tabIndex(), 3);
    expect(find.text('HUANCAYO'), findsWidgets);

    await tester.tap(find.text('Reclamos'));
    await tester.pumpAndSettle();
    expect(tabIndex(), 4);
    // Sin sesión, el destino invita a entrar antes de mostrar el formulario.
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    expect(tabIndex(), 0);
    expect(find.text("BIENVENIDO A TOTO'S"), findsOneWidget);

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
