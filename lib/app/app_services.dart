import '../controllers/alias_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/branch_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/catalog_controller.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/claim_controller.dart';
import '../controllers/coupon_controller.dart';
import '../controllers/custom_pizza_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/promotion_controller.dart';
import '../controllers/subscription_controller.dart';
import '../core/storage/cart_storage.dart';
import '../repositories/alias_repository.dart';
import '../repositories/branch_repository.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/claim_repository.dart';
import '../repositories/coupon_repository.dart';
import '../repositories/firebase/firebase_auth_repository.dart';
import '../repositories/firebase/firestore_alias_repository.dart';
import '../repositories/firebase/firestore_branch_repository.dart';
import '../repositories/firebase/firestore_catalog_repository.dart';
import '../repositories/firebase/firestore_claim_repository.dart';
import '../repositories/firebase/firestore_coupon_repository.dart';
import '../repositories/firebase/firestore_order_repository.dart';
import '../repositories/firebase/firestore_pizza_repository.dart';
import '../repositories/firebase/firestore_profile_repository.dart';
import '../repositories/firebase/firestore_promotion_repository.dart';
import '../repositories/firebase/firestore_settings_repository.dart';
import '../repositories/firebase/firestore_subscription_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/pizza_repository.dart';
import '../repositories/promotion_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/subscription_repository.dart';
import '../services/connectivity_service.dart';
import '../services/location/location_service.dart';
import '../services/settings_service.dart';

/// Repositorios y controladores construidos sobre Firestore.
///
/// No existe una variante local de producción: los tests inyectan fakes a
/// través de sus propios constructores.
class AppServices {
  AppServices({
    required this.settingsRepository,
    required this.catalogRepository,
    required this.branchRepository,
    required this.promotionRepository,
    required this.orderRepository,
    required this.claimRepository,
    required this.aliasRepository,
    required this.pizzaRepository,
    required this.couponRepository,
    required this.subscriptionRepository,
    required this.settings,
    required this.connectivity,
    required this.auth,
    required this.alias,
    required this.catalog,
    required this.branches,
    required this.promotions,
    required this.customPizza,
    required this.coupons,
    required this.subscriptions,
    required this.cart,
    required this.orders,
    required this.claims,
    required this.checkout,
    this.locationService = const GeolocatorLocationService(),
  });

  factory AppServices.create() {
    final SettingsRepository settingsRepository = FirestoreSettingsRepository();
    final CatalogRepository catalogRepository = FirestoreCatalogRepository();
    final BranchRepository branchRepository = FirestoreBranchRepository();
    final PromotionRepository promotionRepository =
        FirestorePromotionRepository();
    final OrderRepository orderRepository = FirestoreOrderRepository();
    final ClaimRepository claimRepository = FirestoreClaimRepository();
    final AliasRepository aliasRepository = FirestoreAliasRepository();
    final PizzaRepository pizzaRepository = FirestorePizzaRepository();
    final CouponRepository couponRepository = FirestoreCouponRepository();
    final SubscriptionRepository subscriptionRepository =
        FirestoreSubscriptionRepository();

    final settings = SettingsService(repository: settingsRepository);
    final connectivity = ConnectivityService();
    final auth = AuthController(
      repository: FirebaseAuthRepository(),
      profiles: FirestoreProfileRepository(),
    );
    final alias = AliasController(repository: aliasRepository);
    final promotions = PromotionController(repository: promotionRepository);
    final branches = BranchController(repository: branchRepository);
    final catalog = CatalogController(
      repository: catalogRepository,
      promotions: promotions,
    );
    final customPizza = CustomPizzaController(repository: pizzaRepository);
    final coupons = CouponController(repository: couponRepository);
    final subscriptions = SubscriptionController(
      repository: subscriptionRepository,
    );
    final cart = CartController(
      storage: const CartStorage(),
      promotions: promotions,
    );
    final orders = OrderController(repository: orderRepository);
    final claims = ClaimController(
      repository: claimRepository,
      settings: settings,
    );
    final checkout = CheckoutController(
      orders: orderRepository,
      cart: cart,
      auth: auth,
      branches: branches,
      settings: settings,
      coupons: coupons,
      subscriptions: subscriptions,
    );

    final services = AppServices(
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
    );
    auth.addListener(services._syncUser);
    branches.addListener(services._syncCheckout);
    return services;
  }

  final SettingsRepository settingsRepository;
  final CatalogRepository catalogRepository;
  final BranchRepository branchRepository;
  final PromotionRepository promotionRepository;
  final OrderRepository orderRepository;
  final ClaimRepository claimRepository;
  final AliasRepository aliasRepository;
  final PizzaRepository pizzaRepository;
  final CouponRepository couponRepository;
  final SubscriptionRepository subscriptionRepository;

  final SettingsService settings;
  final ConnectivityService connectivity;
  final AuthController auth;
  final AliasController alias;
  final CatalogController catalog;
  final BranchController branches;
  final PromotionController promotions;
  final CustomPizzaController customPizza;
  final CouponController coupons;
  final SubscriptionController subscriptions;
  final CartController cart;
  final OrderController orders;
  final ClaimController claims;
  final CheckoutController checkout;
  final LocationService locationService;

  String _lastUid = '';

  /// Carga inicial: configuración, carrito y contenido; luego abre los streams.
  Future<void> start() async {
    connectivity.start();
    await Future.wait([
      settings.load(),
      cart.load(),
      catalog.load(),
      branches.load(),
      promotions.load(),
      customPizza.load(),
    ]);
    checkout.initDefaults();
    catalog.watch();
    branches.watch();
    promotions.watch();
    customPizza.watch();
    subscriptions.watch();
    auth.start();
  }

  void _syncUser() {
    final uid = auth.uid;
    if (uid == _lastUid) return;
    _lastUid = uid;
    orders.bind(uid);
    claims.bind(uid);
    subscriptions.bind(uid);
    checkout.initDefaults();
  }

  void _syncCheckout() {
    checkout.initDefaults();
  }

  void dispose() {
    connectivity.dispose();
    auth
      ..removeListener(_syncUser)
      ..dispose();
    alias.dispose();
    branches
      ..removeListener(_syncCheckout)
      ..dispose();
    catalog.dispose();
    promotions.dispose();
    customPizza.dispose();
    coupons.dispose();
    subscriptions.dispose();
    cart.dispose();
    orders.dispose();
    claims.dispose();
    checkout.dispose();
  }
}
