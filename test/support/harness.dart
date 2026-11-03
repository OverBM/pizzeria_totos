import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/app/app_services.dart';
import 'package:pizzeria_totos/app/providers.dart';
import 'package:pizzeria_totos/controllers/alias_controller.dart';
import 'package:pizzeria_totos/controllers/auth_controller.dart';
import 'package:pizzeria_totos/controllers/branch_controller.dart';
import 'package:pizzeria_totos/controllers/cart_controller.dart';
import 'package:pizzeria_totos/controllers/catalog_controller.dart';
import 'package:pizzeria_totos/controllers/checkout_controller.dart';
import 'package:pizzeria_totos/controllers/claim_controller.dart';
import 'package:pizzeria_totos/controllers/coupon_controller.dart';
import 'package:pizzeria_totos/controllers/custom_pizza_controller.dart';
import 'package:pizzeria_totos/controllers/order_controller.dart';
import 'package:pizzeria_totos/controllers/promotion_controller.dart';
import 'package:pizzeria_totos/controllers/subscription_controller.dart';
import 'package:pizzeria_totos/core/storage/cart_storage.dart';
import 'package:pizzeria_totos/core/theme/toto_theme.dart';
import 'package:pizzeria_totos/models/account.dart';
import 'package:pizzeria_totos/services/connectivity_service.dart';
import 'package:pizzeria_totos/services/settings_service.dart';

import 'fakes.dart';

export 'fakes.dart';

/// App de prueba: arma `AppServices` con repositorios fake en memoria.
///
/// La app de producciÃ³n solo conoce implementaciones Firestore; este harness
/// vive exclusivamente en `test/support/` y nunca se empaqueta en el APK.
class TestApp {
  TestApp({
    bool online = true,
    FakeCatalogRepository? catalogRepository,
    FakeBranchRepository? branchRepository,
    FakePromotionRepository? promotionRepository,
    FakeSettingsRepository? settingsRepository,
    FakeOrderRepository? orderRepository,
    FakeClaimRepository? claimRepository,
    FakeProfileRepository? profileRepository,
    FakeAuthRepository? authRepository,
    FakeAliasRepository? aliasRepository,
    FakePizzaRepository? pizzaRepository,
    FakeCouponRepository? couponRepository,
    FakeSubscriptionRepository? subscriptionRepository,
    FakeLocationService? locationService,
    FakeMapsService? mapsService,
  }) : authRepository = authRepository ?? FakeAuthRepository(),
       aliasRepository = aliasRepository ?? FakeAliasRepository(),
       pizzaRepository = pizzaRepository ?? FakePizzaRepository(),
       couponRepository = couponRepository ?? FakeCouponRepository(),
       subscriptionRepository =
           subscriptionRepository ?? FakeSubscriptionRepository(),
       locationService = locationService ?? FakeLocationService(),
       mapsService = mapsService ?? FakeMapsService(),
       profileRepository = profileRepository ?? FakeProfileRepository(),
       catalogRepository = catalogRepository ?? FakeCatalogRepository(),
       branchRepository = branchRepository ?? FakeBranchRepository(),
       promotionRepository = promotionRepository ?? FakePromotionRepository(),
       settingsRepository = settingsRepository ?? FakeSettingsRepository(),
       orderRepository = orderRepository ?? FakeOrderRepository(),
       claimRepository = claimRepository ?? FakeClaimRepository(),
       connectivity = ConnectivityService.manual(online: online);

  final FakeAuthRepository authRepository;
  final FakeProfileRepository profileRepository;
  final FakeCatalogRepository catalogRepository;
  final FakeBranchRepository branchRepository;
  final FakePromotionRepository promotionRepository;
  final FakeSettingsRepository settingsRepository;
  final FakeOrderRepository orderRepository;
  final FakeClaimRepository claimRepository;
  final FakeAliasRepository aliasRepository;
  final FakePizzaRepository pizzaRepository;
  final FakeCouponRepository couponRepository;
  final FakeSubscriptionRepository subscriptionRepository;
  final FakeLocationService locationService;
  final FakeMapsService mapsService;
  final ConnectivityService connectivity;

  late final SettingsService settings = SettingsService(
    repository: settingsRepository,
  );
  late final AuthController auth = AuthController(
    repository: authRepository,
    profiles: profileRepository,
  );
  late final AliasController alias = AliasController(
    repository: aliasRepository,
  );
  late final CatalogController catalog = CatalogController(
    repository: catalogRepository,
    promotions: promotions,
  );
  late final BranchController branches = BranchController(
    repository: branchRepository,
  );
  late final PromotionController promotions = PromotionController(
    repository: promotionRepository,
  );
  late final CustomPizzaController customPizza = CustomPizzaController(
    repository: pizzaRepository,
  );
  late final CouponController coupons = CouponController(
    repository: couponRepository,
  );
  late final SubscriptionController subscriptions = SubscriptionController(
    repository: subscriptionRepository,
  );
  late final CartController cart = CartController(
    storage: const CartStorage(),
    promotions: promotions,
  );
  late final OrderController orders = OrderController(
    repository: orderRepository,
  );
  late final ClaimController claims = ClaimController(
    repository: claimRepository,
    settings: settings,
  );
  late final CheckoutController checkout = CheckoutController(
    orders: orderRepository,
    cart: cart,
    auth: auth,
    branches: branches,
    settings: settings,
    coupons: coupons,
    subscriptions: subscriptions,
    maps: mapsService,
    // Instante fijo dentro del horario de las sedes de ejemplo (12:45â€“21:30).
    now: () => DateTime(2026, 10, 15, 13),
  );

  late final AppServices services = AppServices(
    settingsRepository: settingsRepository,
    catalogRepository: catalogRepository,
    branchRepository: branchRepository,
    promotionRepository: promotionRepository,
    orderRepository: orderRepository,
    claimRepository: claimRepository,
    aliasRepository: aliasRepository,
    pizzaRepository: pizzaRepository,
    couponRepository: couponRepository,
    subscriptionRepository: subscriptionRepository,
    settings: settings,
    connectivity: connectivity,
    auth: auth,
    alias: alias,
    catalog: catalog,
    branches: branches,
    promotions: promotions,
    customPizza: customPizza,
    coupons: coupons,
    subscriptions: subscriptions,
    cart: cart,
    orders: orders,
    claims: claims,
    checkout: checkout,
    locationService: locationService,
  );

  bool _started = false;

  /// Carga configuraciÃ³n, carrito, carta, sedes y promociones.
  Future<void> loadAll() async {
    if (_started) return;
    _started = true;
    await services.start();
    await settleMicrotasks();
  }

  /// Inicia sesiÃ³n con [account] y espera a que el perfil llegue al controlador.
  Future<void> signIn({Account? account}) async {
    final target = account ?? sampleAccount();
    profileRepository.profiles[target.uid] = target;
    authRepository.emit(target);
    await settleMicrotasks();
  }

  /// Monta [home] con el tema real y el `AppScope` por encima del Navigator.
  ///
  /// El `AppScope` va en `builder` para que todas las rutas empujadas
  /// encuentren los providers, igual que en `TotosApp`.
  Widget wrap(Widget home) => MaterialApp(
    title: "TOTO'S Pizza",
    debugShowCheckedModeBanner: false,
    theme: totoTheme(),
    darkTheme: totoTheme(),
    themeMode: ThemeMode.dark,
    builder: (context, child) => AppScope(
      services: services,
      child: child ?? const SizedBox.shrink(),
    ),
    home: home,
  );

  void dispose() => services.dispose();
}

/// Fija el viewport en 360 dp de ancho, la medida mÃ³vil de referencia.
void usePhoneViewport(WidgetTester tester, {double height = 900}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(360, height);
  addTearDown(tester.view.reset);
}

/// Ancho lÃ³gico actual del viewport de prueba.
double logicalWidth(WidgetTester tester) =>
    tester.view.physicalSize.width / tester.view.devicePixelRatio;

/// Cursor sin parpadeo: evita que `pumpAndSettle` se cuelgue en campos de texto.
void useDeterministicCursor() {
  EditableText.debugDeterministicCursor = true;
}

/// Deja correr solo microtareas (Streams/`async` sin temporizadores).
///
/// `pumpEventQueue` y `Future.delayed` se bloquean bajo el reloj falso de
/// `testWidgets`; esto no avanza el tiempo y por eso es seguro dentro de un
/// widget test.
Future<void> settleMicrotasks([int turns = 4]) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.microtask(() {});
  }
}

/// Carga las fuentes de marca para que el texto mida como en producciÃ³n.
Future<void> loadBrandFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await load('AlfaSlabOne', ['assets/fonts/AlfaSlabOne-Regular.ttf']);
  await load('Inter', [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
}

