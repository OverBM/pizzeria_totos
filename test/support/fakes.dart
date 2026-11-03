import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:pizzeria_totos/models/account.dart';
import 'package:pizzeria_totos/models/branch.dart';
import 'package:pizzeria_totos/models/cart_item.dart';
import 'package:pizzeria_totos/models/category.dart';
import 'package:pizzeria_totos/models/claim.dart';
import 'package:pizzeria_totos/models/coupon.dart';
import 'package:pizzeria_totos/models/delivery_config.dart';
import 'package:pizzeria_totos/models/delivery_plan.dart';
import 'package:pizzeria_totos/models/delivery_quote.dart';
import 'package:pizzeria_totos/models/ingredient.dart';
import 'package:pizzeria_totos/models/menu_data.dart';
import 'package:pizzeria_totos/models/nutrition.dart';
import 'package:pizzeria_totos/models/order.dart';
import 'package:pizzeria_totos/models/payment_method.dart';
import 'package:pizzeria_totos/models/pizza_config.dart';
import 'package:pizzeria_totos/models/product.dart';
import 'package:pizzeria_totos/models/promotion.dart';
import 'package:pizzeria_totos/models/settings.dart';
import 'package:pizzeria_totos/models/subscription.dart';
import 'package:pizzeria_totos/models/variant.dart';
import 'package:pizzeria_totos/repositories/alias_repository.dart';
import 'package:pizzeria_totos/repositories/auth_repository.dart';
import 'package:pizzeria_totos/repositories/branch_repository.dart';
import 'package:pizzeria_totos/repositories/catalog_repository.dart';
import 'package:pizzeria_totos/repositories/claim_repository.dart';
import 'package:pizzeria_totos/repositories/coupon_repository.dart';
import 'package:pizzeria_totos/repositories/order_repository.dart';
import 'package:pizzeria_totos/repositories/pizza_repository.dart';
import 'package:pizzeria_totos/repositories/profile_repository.dart';
import 'package:pizzeria_totos/repositories/promotion_repository.dart';
import 'package:pizzeria_totos/repositories/repository_exception.dart';
import 'package:pizzeria_totos/repositories/settings_repository.dart';
import 'package:pizzeria_totos/repositories/subscription_repository.dart';
import 'package:pizzeria_totos/services/location/location_service.dart';
import 'package:pizzeria_totos/services/maps/maps_service.dart';

/// Ubicación controlada para pruebas.
class FakeLocationService implements LocationService {
  FakeLocationService({LocationResult? result})
    : result =
          result ?? LocationResult.success(const LatLng(-12.0651, -75.2049));

  LocationResult result;
  bool settingsOpened = false;

  @override
  Future<LocationResult> current({
    Duration timeout = const Duration(seconds: 10),
  }) async => result;

  @override
  Future<bool> openSettings() async {
    settingsOpened = true;
    return true;
  }
}

/// Mapas controlados para pruebas: ruta fija y búsqueda vacía.
class FakeMapsService implements MapsService {
  FakeMapsService({MapRoute? route, List<PlaceResult>? searchResults})
    : routeResult =
          route ??
          MapRoute(
            distanceMeters: 3200,
            durationSeconds: 720,
            points: const [
              LatLng(-12.0651, -75.2049),
              LatLng(-12.0600, -75.2000),
            ],
          ),
      searchResults = searchResults ?? const [];

  MapRoute routeResult;
  final List<PlaceResult> searchResults;

  @override
  String get attribution => '© OpenStreetMap contributors';

  @override
  String get tileUrlTemplate =>
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  Future<List<PlaceResult>> search(String query, {int limit = 5}) async =>
      searchResults.take(limit).toList();

  @override
  Future<PlaceResult?> reverse(LatLng point) async =>
      PlaceResult(label: 'Punto de prueba', point: point);

  @override
  Future<MapRoute> route(LatLng from, LatLng to) async => routeResult;
}

/// Implementaciones en memoria de todos los contratos.
///
/// La app de producción solo tiene repositorios Firestore; estos fakes viven
/// exclusivamente en `test/support/`.

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({MenuData? menu, this.error})
    : menu = menu ?? sampleMenu;

  MenuData menu;
  Object? error;
  final StreamController<MenuData> _updates =
      StreamController<MenuData>.broadcast();

  @override
  Future<MenuData> fetchMenu() async {
    if (error != null) throw error!;
    return menu;
  }

  @override
  Stream<MenuData> watchMenu() async* {
    yield menu;
    yield* _updates.stream;
  }

  void emit(MenuData next) {
    menu = next;
    _updates.add(next);
  }

  void dispose() => _updates.close();
}

class FakeBranchRepository implements BranchRepository {
  FakeBranchRepository({List<Branch>? branches, this.error})
    : branches = branches ?? sampleBranches;

  List<Branch> branches;
  Object? error;
  final StreamController<List<Branch>> _updates =
      StreamController<List<Branch>>.broadcast();

  @override
  Future<List<Branch>> fetchBranches() async {
    if (error != null) throw error!;
    return branches;
  }

  @override
  Stream<List<Branch>> watchBranches() async* {
    yield branches;
    yield* _updates.stream;
  }

  void emit(List<Branch> next) {
    branches = next;
    _updates.add(next);
  }

  void dispose() => _updates.close();
}

class FakePromotionRepository implements PromotionRepository {
  FakePromotionRepository({List<Promotion>? promotions, this.error})
    : promotions = promotions ?? samplePromotions;

  List<Promotion> promotions;
  Object? error;
  final StreamController<List<Promotion>> _updates =
      StreamController<List<Promotion>>.broadcast();

  @override
  Future<List<Promotion>> fetchPromotions() async {
    if (error != null) throw error!;
    return promotions;
  }

  @override
  Stream<List<Promotion>> watchPromotions() async* {
    yield promotions;
    yield* _updates.stream;
  }

  void emit(List<Promotion> next) {
    promotions = next;
    _updates.add(next);
  }

  void dispose() => _updates.close();
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({AppSettings? settings, this.error})
    : settings = settings ?? sampleSettings;

  AppSettings settings;
  Object? error;

  @override
  Future<AppSettings> fetchSettings() async {
    if (error != null) throw error!;
    return settings;
  }

  @override
  Stream<AppSettings> watchSettings() => Stream<AppSettings>.value(settings);
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.account, this.error});

  Account? account;
  Object? error;
  final StreamController<Account?> _states =
      StreamController<Account?>.broadcast();

  Account _signedAccount({
    required String name,
    required String email,
    String uid = 'uid-1',
  }) => Account(uid: uid, name: name, email: email);

  @override
  Account? get currentAccount => account;

  @override
  Stream<Account?> authStateChanges() async* {
    yield account;
    yield* _states.stream;
  }

  @override
  Future<Account> signIn({
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    if (password.length < 6) {
      throw const RepositoryException('Correo o contraseña incorrectos.');
    }
    final next = _signedAccount(name: email.split('@').first, email: email);
    account = next;
    _states.add(next);
    return next;
  }

  @override
  Future<Account> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    final next = _signedAccount(name: name, email: email);
    account = next;
    _states.add(next);
    return next;
  }

  @override
  Future<void> signOut() async {
    account = null;
    _states.add(null);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (error != null) throw error!;
  }

  @override
  Future<void> deleteAccount() async {
    account = null;
    _states.add(null);
  }

  void emit(Account? next) {
    account = next;
    _states.add(next);
  }

  void dispose() => _states.close();
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({Map<String, Account>? profiles})
    : profiles = profiles ?? <String, Account>{};

  final Map<String, Account> profiles;
  final StreamController<Account> _updates =
      StreamController<Account>.broadcast();

  @override
  Stream<Account?> watchProfile(String uid) async* {
    yield profiles[uid];
    await for (final account in _updates.stream) {
      if (account.uid == uid) yield account;
    }
  }

  @override
  Future<Account?> fetchProfile(String uid) async => profiles[uid];

  @override
  Future<void> ensureProfile({
    required String uid,
    required String name,
    required String email,
    String alias = '',
  }) async {
    if (profiles.containsKey(uid)) return;
    final now = DateTime.now();
    _save(
      Account(
        uid: uid,
        name: name,
        email: email,
        alias: alias,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? alias,
    String? phone,
    List<Address>? addresses,
  }) async {
    final current = profiles[uid];
    if (current == null) {
      throw const RepositoryException('No se encontró el perfil.');
    }
    _save(
      current.copyWith(
        name: name,
        alias: alias,
        phone: phone,
        addresses: addresses,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Address> addAddress({
    required String uid,
    required Address address,
  }) async {
    final current = profiles[uid];
    if (current == null) {
      throw const RepositoryException('No se encontró el perfil.');
    }
    _save(current.withAddress(address));
    return address;
  }

  @override
  Future<void> removeAddress({
    required String uid,
    required String addressId,
  }) async {
    final current = profiles[uid];
    if (current == null) return;
    _save(current.withoutAddress(addressId));
  }

  void _save(Account account) {
    profiles[account.uid] = account;
    _updates.add(account);
  }

  void dispose() => _updates.close();
}

class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository({List<Order>? orders, this.error})
    : orders = orders ?? <Order>[];

  final List<Order> orders;
  Object? error;
  final StreamController<List<Order>> _updates =
      StreamController<List<Order>>.broadcast();

  List<Order> _forUid(String uid) =>
      orders.where((order) => order.uid == uid).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<Order>> watchOrders(String uid) async* {
    yield _forUid(uid);
    await for (final _ in _updates.stream) {
      yield _forUid(uid);
    }
  }

  @override
  Future<List<Order>> fetchOrders(String uid) async {
    if (error != null) throw error!;
    return _forUid(uid);
  }

  @override
  Future<String> createOrder(
    Order order, {
    String? couponCode,
    String? couponUid,
    bool registerShipment = false,
  }) async {
    if (error != null) throw error!;
    final id = 'order-${orders.length + 1}';
    orders.add(Order.fromMap({...order.toMap(), 'id': id}, id: id));
    _updates.add(orders);
    return id;
  }

  @override
  Future<void> markWhatsappSent(String orderId) async {
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index < 0) return;
    final current = orders[index];
    orders[index] = Order.fromMap({
      ...current.toMap(),
      'enviadoWhatsapp': true,
    }, id: current.id);
    _updates.add(orders);
  }

  void dispose() => _updates.close();
}

class FakeClaimRepository implements ClaimRepository {
  FakeClaimRepository({List<Claim>? claims, this.error})
    : claims = claims ?? <Claim>[];

  final List<Claim> claims;
  Object? error;
  final StreamController<List<Claim>> _updates =
      StreamController<List<Claim>>.broadcast();

  List<Claim> _forUid(String uid) =>
      claims.where((claim) => claim.uid == uid).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<Claim>> watchClaims(String uid) async* {
    yield _forUid(uid);
    await for (final _ in _updates.stream) {
      yield _forUid(uid);
    }
  }

  @override
  Future<List<Claim>> fetchClaims(String uid) async {
    if (error != null) throw error!;
    return _forUid(uid);
  }

  @override
  Future<String> createClaim(Claim claim) async {
    if (error != null) throw error!;
    final id = 'claim-${claims.length + 1}';
    claims.add(Claim.fromMap({...claim.toMap(), 'id': id}, id: id));
    _updates.add(claims);
    return id;
  }

  void dispose() => _updates.close();
}

// ── Datos de ejemplo ────────────────────────────────────────────────────────

final MenuData sampleMenu = MenuData(
  categories: const [
    MenuCategoryFixture.featured,
    MenuCategoryFixture.pizzas,
    MenuCategoryFixture.bebidas,
  ],
  products: const [
    Product(
      id: 'pizza-totos',
      categoryId: 'pizzas',
      name: "PIZZA TOTO'S",
      description: 'La de la casa.',
      featured: true,
      ingredients: ['Masa madre', 'Mozzarella'],
      allergens: ['Gluten'],
      calories: 1120,
      nutrition: NutritionInfo(
        portion: '1 pizza entera (550 g)',
        portionGrams: 550,
        calories: 1120,
        proteinG: 50.4,
        carbsG: 134.4,
        fatG: 42.3,
        saturatedFatG: 16.9,
        sugarsG: 6.7,
        fiberG: 11,
        sodiumMg: 3025,
      ),
      variants: [
        Variant(label: 'entera', priceSoles: 43.90, slices: 8),
        Variant(label: 'media', priceSoles: 22.90, slices: 4),
      ],
    ),
    Product(
      id: 'coca-600',
      categoryId: 'bebidas',
      name: 'COCA COLA 600 ML',
      description: 'Bien fría.',
      calories: 250,
      nutrition: NutritionInfo(
        portion: '600 ml',
        portionGrams: 600,
        calories: 250,
        proteinG: 0,
        carbsG: 62.5,
        fatG: 0,
        saturatedFatG: 0,
        sugarsG: 62.5,
        fiberG: 0,
        sodiumMg: 48,
        glutenFree: true,
      ),
      variants: [Variant(label: 'única', priceSoles: 4.90)],
    ),
  ],
);

abstract final class MenuCategoryFixture {
  static const MenuCategory featured = MenuCategory(
    id: 'mas-pedidas',
    name: 'LAS MÁS PEDIDAS',
    order: 0,
  );
  static const MenuCategory pizzas = MenuCategory(
    id: 'pizzas',
    name: 'PIZZAS',
    order: 1,
  );
  static const MenuCategory bebidas = MenuCategory(
    id: 'bebidas',
    name: 'BEBIDAS',
    order: 2,
  );
}

const BranchHours sampleHours = BranchHours(
  open: '12:45',
  close: '21:30',
  days: [1, 2, 3, 4, 5, 6, 7],
);

final List<Branch> sampleBranches = [
  Branch(
    id: 'huancayo',
    name: 'HUANCAYO',
    address: 'Prolongación San Carlos 123',
    district: 'Huancayo',
    lat: -12.0651,
    lng: -75.2049,
    delivers: true,
    deliveryFeeSoles: 3.00,
    hours: sampleHours,
    phone: '51900000000',
    whatsapp: '51900000000',
    sortOrder: 1,
  ),
  Branch(
    id: 'el-tambo',
    name: 'EL TAMBO',
    address: 'Av. 13 de Noviembre 510',
    district: 'El Tambo',
    lat: -12.0520,
    lng: -75.2180,
    delivers: true,
    deliveryFeeSoles: 3.00,
    hours: sampleHours,
    sortOrder: 2,
  ),
  Branch(
    id: 'chilca',
    name: 'CHILCA',
    address: 'Calle Real 421',
    district: 'Chilca',
    lat: -12.0830,
    lng: -75.2010,
    delivers: false,
    hours: sampleHours,
    sortOrder: 3,
  ),
  Branch(
    id: 'pio-pata',
    name: 'PÍO PATA',
    address: 'Jr. Bolognesi 1390',
    district: 'Pío Pata',
    lat: -12.0560,
    lng: -75.1960,
    delivers: true,
    deliveryFeeSoles: 3.00,
    hours: sampleHours,
    sortOrder: 4,
  ),
];

final List<Promotion> samplePromotions = [
  const Promotion(
    id: 'promo-totos',
    title: "PIZZA TOTO'S",
    subtitle: 'La de la casa, más barata',
    productId: 'pizza-totos',
    variantLabel: 'entera',
    priceSoles: 34.90,
    banner: true,
  ),
];

final AppSettings sampleSettings = AppSettings(
  whatsapp: '51900000000',
  phone: '51900000000',
  phoneDisplay: '900 000 000',
  paymentMethods: PaymentMethod.fallback,
  claimReasons: ClaimReason.fallback,
  delivery: DeliveryConfig.fallback,
);

final Address sampleAddress = Address(
  id: 'addr-casa',
  label: 'Casa',
  line: 'Av. Giráldez 123, Huancayo',
  reference: 'Portón negro',
  createdAt: DateTime(2026, 1, 1),
);

Account sampleAccount({
  String uid = 'uid-1',
  String name = 'Ana Torres',
  String email = 'ana@example.com',
  String phone = '999 111 222',
  List<Address>? addresses,
}) => Account(
  uid: uid,
  name: name,
  email: email,
  phone: phone,
  addresses: addresses ?? [sampleAddress],
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 2),
);

Order sampleOrder({
  String uid = 'uid-1',
  String code = 'TOT-20261015-1234',
  String status = 'pendiente_confirmacion',
}) => Order(
  id: 'order-1',
  code: code,
  uid: uid,
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
      originalUnitPriceSoles: 43.90,
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
  status: OrderStatus.fromName(status),
  address: 'Av. Giráldez 123, Huancayo',
  savingsSoles: 9.00,
);

Claim sampleClaim({String uid = 'uid-1'}) => Claim(
  id: 'claim-1',
  code: 'REC-20261016-4821',
  uid: uid,
  categoryId: 'demora',
  categoryLabel: 'Demora en la entrega',
  message: 'Mi pedido llegó tarde.',
  createdAt: DateTime(2026, 10, 16, 20),
  updatedAt: DateTime(2026, 10, 16, 20),
);

/// Producto con la lista de ingredientes más larga de la carta.
const Product sampleFourCheese = Product(
  id: 'pizza-4quesos',
  categoryId: 'pizzas',
  name: 'PIZZA 4 QUESOS',
  description: 'Mezcla de quesos.',
  ingredients: [
    'Masa madre',
    'Salsa de tomate',
    'Mozzarella',
    'Queso parmesano',
    'Queso azul',
    'Queso edam',
  ],
  calories: 1120,
  variants: [Variant(label: 'entera', priceSoles: 38)],
);

const PizzaConfig samplePizzaConfig = PizzaConfig(
  active: true,
  minutesBase: 15,
  minutesPerIngredient: 1,
  defaultOvenCapacity: 4,
  defaultRecoveryMinutes: 0,
  unmeasuredMarginMinutes: 5,
  maxIngredientsGlobal: 7,
  sizes: [
    PizzaSize(
      id: 'personal',
      name: 'Personal',
      diameterCm: 24,
      slices: 4,
      basePriceSoles: 15.9,
      maxIngredients: 3,
      ingredientMultiplier: 1,
      ovenWeight: 0.5,
    ),
    PizzaSize(
      id: 'mediana',
      name: 'Mediana',
      diameterCm: 30,
      slices: 6,
      basePriceSoles: 22.9,
      maxIngredients: 5,
      ingredientMultiplier: 1.4,
      extraMinutes: 2,
      ovenWeight: 1,
    ),
  ],
  doughs: [
    PizzaOption(id: 'normal', name: 'Normal'),
    PizzaOption(
      id: 'masa-madre',
      name: 'Masa madre',
      adjustmentPercent: 12,
      extraMinutes: 3,
    ),
  ],
  sauces: [
    PizzaOption(id: 'tomate', name: 'Tomate'),
    PizzaOption(id: 'bbq', name: 'BBQ', adjustmentSoles: 2),
  ],
  cheeses: [
    PizzaOption(id: 'estandar', name: 'Estándar'),
    PizzaOption(id: 'sin-queso', name: 'Sin queso', adjustmentSoles: -3),
  ],
);

const List<Ingredient> sampleIngredients = [
  Ingredient(
    id: 'pepperoni',
    name: 'Pepperoni',
    category: 'carnes',
    priceSoles: 4,
    sortOrder: 1,
  ),
  Ingredient(
    id: 'champinones',
    name: 'Champiñones',
    category: 'vegetales',
    priceSoles: 2.5,
    sortOrder: 2,
  ),
];

class FakeAliasRepository implements AliasRepository {
  final Map<String, String> aliases = {};

  @override
  Future<String?> emailForAlias(String alias) async =>
      aliases[alias.trim().toLowerCase()];

  @override
  Future<void> claimAlias({
    required String uid,
    required String alias,
    required String email,
  }) async {
    final key = alias.trim().toLowerCase();
    if (aliases.containsKey(key)) {
      throw const RepositoryException('Ese alias ya está en uso. Elige otro.');
    }
    aliases[key] = email;
  }

  @override
  Future<void> releaseAlias({
    required String uid,
    required String alias,
  }) async {
    aliases.remove(alias.trim().toLowerCase());
  }

  @override
  Future<String?> aliasForUid(String uid) async => null;

  @override
  String suggestFromEmail(String email) => email.split('@').first;

  @override
  Future<String> uniqueAlias(String base) async {
    var candidate = base;
    var suffix = 1;
    while (aliases.containsKey(candidate)) {
      candidate = '$base$suffix';
      suffix += 1;
    }
    return candidate;
  }
}

class FakePizzaRepository implements PizzaRepository {
  FakePizzaRepository({PizzaConfig? config, List<Ingredient>? ingredients})
    : config = config ?? samplePizzaConfig,
      ingredients = ingredients ?? sampleIngredients;

  PizzaConfig config;
  List<Ingredient> ingredients;

  @override
  Future<List<Ingredient>> fetchIngredients() async => ingredients;

  @override
  Stream<List<Ingredient>> watchIngredients() async* {
    yield ingredients;
  }

  @override
  Future<PizzaConfig> fetchConfig() async => config;

  @override
  Stream<PizzaConfig> watchConfig() async* {
    yield config;
  }
}

class FakeCouponRepository implements CouponRepository {
  FakeCouponRepository({Map<String, Coupon>? coupons})
    : coupons = coupons ?? {};

  final Map<String, Coupon> coupons;
  final Set<String> redeemed = {};
  Object? error;

  @override
  Future<Coupon?> fetchByCode(String code) async {
    if (error != null) throw error!;
    return coupons[code.trim()];
  }

  @override
  Future<bool> wasRedeemed({required String code, required String uid}) async =>
      redeemed.contains('${code.trim()}_$uid');

  @override
  Future<void> redeem({
    required String code,
    required String uid,
    required String orderId,
  }) async {
    redeemed.add('${code.trim()}_$uid');
  }
}

class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository({
    List<DeliveryPlan>? plans,
    PlanBase? planBase,
    Subscription? subscription,
  }) : plans = plans ?? samplePlans,
       planBase = planBase ?? PlanBase.fallback,
       subscription = subscription;

  List<DeliveryPlan> plans;
  PlanBase planBase;
  Subscription? subscription;
  Object? error;
  final StreamController<Subscription?> _subscriptionUpdates =
      StreamController<Subscription?>.broadcast();

  @override
  Stream<List<DeliveryPlan>> watchPlans() async* {
    if (error != null) throw error!;
    yield plans;
  }

  @override
  Stream<PlanBase> watchPlanBase() async* {
    yield planBase;
  }

  @override
  Stream<Subscription?> watchSubscription(String uid) async* {
    yield subscription;
    yield* _subscriptionUpdates.stream;
  }

  @override
  Future<void> activate({
    required String uid,
    required DeliveryPlan plan,
  }) async {
    if (error != null) throw error!;
    final now = DateTime(2026, 10, 15, 13);
    final current = subscription;
    final base = current != null && current.isActiveAt(now)
        ? current.endAt
        : now;
    subscription = Subscription(
      uid: uid,
      planId: plan.id,
      planName: plan.name,
      priceSoles: plan.priceSoles,
      startAt: current?.startAt ?? now,
      endAt: base.add(Duration(days: plan.days)),
      periodStart: current?.periodStart ?? now,
      shipmentsUsed: current?.shipmentsUsed ?? 0,
    );
    _subscriptionUpdates.add(subscription);
  }

  @override
  Future<void> cancel({
    required String uid,
    required String reason,
    required bool immediate,
  }) async {
    final current = subscription;
    if (current == null) return;
    subscription = current.copyWith(
      status: SubscriptionStatus.cancelled,
      cancelledAt: DateTime(2026, 10, 15, 13),
      cancelReason: reason,
      endAt: immediate ? DateTime(2026, 10, 15, 13) : current.endAt,
    );
    _subscriptionUpdates.add(subscription);
  }

  @override
  Future<void> registerShipment(String uid) async {
    final current = subscription;
    if (current == null) return;
    subscription = current.copyWith(shipmentsUsed: current.shipmentsUsed + 1);
    _subscriptionUpdates.add(subscription);
  }
}

const List<DeliveryPlan> samplePlans = [
  DeliveryPlan(
    id: 'la-previa',
    name: 'La Previa',
    description: '30 días',
    priceSoles: 14.9,
    days: 30,
    minimumOrderSoles: 20,
    label: 'PARA PROBAR',
  ),
  DeliveryPlan(
    id: 'la-fija',
    name: 'La Fija',
    description: '90 días',
    priceSoles: 39.9,
    days: 90,
    minimumOrderSoles: 15,
    savingsSoles: 4.8,
    label: 'MEJOR PRECIO',
  ),
];
