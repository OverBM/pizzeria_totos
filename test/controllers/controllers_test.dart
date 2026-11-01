import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/controllers/auth_controller.dart';
import 'package:pizzeria_totos/controllers/branch_controller.dart';
import 'package:pizzeria_totos/controllers/cart_controller.dart';
import 'package:pizzeria_totos/controllers/catalog_controller.dart';
import 'package:pizzeria_totos/controllers/checkout_controller.dart';
import 'package:pizzeria_totos/controllers/claim_controller.dart';
import 'package:pizzeria_totos/controllers/order_controller.dart';
import 'package:pizzeria_totos/controllers/promotion_controller.dart';
import 'package:pizzeria_totos/core/load_state.dart';
import 'package:pizzeria_totos/core/storage/cart_storage.dart';
import 'package:pizzeria_totos/models/account.dart';
import 'package:pizzeria_totos/models/catalog_filters.dart';
import 'package:pizzeria_totos/models/category.dart';
import 'package:pizzeria_totos/models/delivery_quote.dart';
import 'package:pizzeria_totos/models/masa.dart';
import 'package:pizzeria_totos/models/menu_data.dart';
import 'package:pizzeria_totos/models/order.dart';
import 'package:pizzeria_totos/models/product.dart';
import 'package:pizzeria_totos/models/product_option.dart';
import 'package:pizzeria_totos/models/promotion.dart';
import 'package:pizzeria_totos/models/variant.dart';
import 'package:pizzeria_totos/repositories/repository_exception.dart';
import 'package:pizzeria_totos/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CatalogController', () {
    test('pasa por loading y ready, y expone la carta', () async {
      final controller = CatalogController(repository: FakeCatalogRepository());
      expect(controller.state, LoadState.idle);

      final states = <LoadState>[];
      controller.addListener(() => states.add(controller.state));

      await controller.load();
      expect(states.first, LoadState.loading);
      expect(controller.state, LoadState.ready);
      expect(controller.hasProducts, isTrue);
      expect(controller.isEmpty, isFalse);
      expect(controller.featured.single.id, 'pizza-totos');
      controller.dispose();
    });

    test('queda en error con mensaje legible', () async {
      final controller = CatalogController(
        repository: FakeCatalogRepository(
          error: const RepositoryException('Firestore no responde.'),
        ),
      );
      await controller.load();
      expect(controller.state, LoadState.error);
      expect(controller.error, 'Firestore no responde.');
      expect(controller.hasProducts, isFalse);

      final generic = CatalogController(
        repository: FakeCatalogRepository(error: StateError('boom')),
      );
      await generic.load();
      expect(generic.error, 'No se pudo cargar la carta.');
      controller.dispose();
      generic.dispose();
    });

    test('cambia de categoría y filtra productos', () async {
      final controller = CatalogController(repository: FakeCatalogRepository());
      await controller.load();
      expect(
        controller.selectedCategoryId,
        CatalogController.allCategoryId,
      );
      expect(controller.selectedCategoryName, 'TODOS');

      controller.selectCategory('bebidas');
      expect(controller.selectedCategoryName, 'BEBIDAS');
      expect(controller.visibleProducts.single.id, 'coca-600');
      expect(controller.visibleCount, 1);

      controller.selectCategory(CatalogController.allCategoryId);
      expect(controller.selectedCategoryName, 'TODOS');
      expect(controller.visibleProducts.length, 2);

      controller.selectCategory('inexistente');
      expect(controller.visibleProducts, isEmpty);
      controller.dispose();
    });

    test('la búsqueda es global y los filtros se combinan', () async {
      final controller = CatalogController(repository: FakeCatalogRepository());
      await controller.load();

      controller.selectCategory('pizzas');
      controller.setQuery('coca');
      expect(controller.visibleProducts.single.id, 'coca-600');

      controller.clearFilters();
      controller.setQuery('');
      controller.selectCategory(CatalogController.featuredCategoryId);
      controller.toggleAllergen('Gluten');
      expect(controller.visibleProducts.single.id, 'coca-600');

      controller.clearFilters();
      controller.setCalorieBand(CalorieBand.upTo500);
      expect(controller.visibleProducts.single.id, 'coca-600');

      controller.clearFilters();
      controller.setPriceRange(0, 10);
      expect(controller.visibleProducts.single.id, 'coca-600');

      controller.clearFilters();
      controller.setPriceRange(null, 10);
      expect(controller.visibleProducts.single.id, 'coca-600');

      controller.setPriceRange(10, null);
      expect(controller.visibleProducts.single.id, 'pizza-totos');

      controller.clearPriceRange();
      expect(controller.visibleProducts.length, 1);
      controller.dispose();
    });

    test('filtra por el precio mostrado y por masa, formato y tipo', () async {
      const menu = MenuData(
        categories: [
          MenuCategory(id: 'pizzas', name: 'PIZZAS', order: 1),
          MenuCategory(id: 'bebidas', name: 'BEBIDAS', order: 2),
        ],
        products: [
          Product(
            id: 'pizza-americana',
            categoryId: 'pizzas',
            name: 'PIZZA AMERICANA',
            description: '',
            tags: ['clásica'],
            masas: [MasaType.normal, MasaType.masaMadre],
            variants: [
              Variant(label: 'entera', priceSoles: 27.9),
              Variant(label: 'media', priceSoles: 14.9),
            ],
          ),
          Product(
            id: 'pizza-dulce',
            categoryId: 'pizzas',
            name: 'PIZZA DULCE',
            description: '',
            tags: ['familiar', 'dulce'],
            masas: [MasaType.dulce],
            variants: [Variant(label: 'única', priceSoles: 30)],
          ),
          Product(
            id: 'coca-600',
            categoryId: 'bebidas',
            name: 'COCA COLA',
            description: '',
            variants: [Variant(label: 'única', priceSoles: 5)],
          ),
        ],
      );
      final controller = CatalogController(
        repository: FakeCatalogRepository(menu: menu),
      );
      await controller.load();

      expect(controller.selectedCategoryId, CatalogController.allCategoryId);
      expect(controller.priceBounds.max, 30);

      controller.setPriceRange(null, 15);
      expect(controller.visibleProducts.single.id, 'coca-600');

      controller.setPriceRange(25, null);
      expect(
        controller.visibleProducts.map((p) => p.id),
        containsAll(['pizza-americana', 'pizza-dulce']),
      );
      expect(controller.visibleProducts.any((p) => p.id == 'coca-600'), isFalse);

      controller.clearFilters();
      controller.setMasa(MasaType.masaMadre);
      expect(controller.visibleProducts.single.id, 'pizza-americana');

      controller.clearFilters();
      controller.setMasa(MasaType.dulce);
      expect(controller.visibleProducts.single.id, 'pizza-dulce');

      controller.clearFilters();
      controller.setFormato('Familiar');
      expect(controller.visibleProducts.single.id, 'pizza-dulce');

      controller.clearFilters();
      controller.setTipo('Clásica');
      expect(controller.visibleProducts.single.id, 'pizza-americana');
      controller.dispose();
    });

    test('normaliza tildes y mayúsculas en la búsqueda', () async {
      final controller = CatalogController(repository: FakeCatalogRepository());
      await controller.load();
      controller.setQuery('PIZZA');
      expect(controller.visibleProducts.single.id, 'pizza-totos');
      controller.setQuery('MOZZARELLA');
      expect(controller.visibleProducts.single.id, 'pizza-totos');
      controller.setQuery('sin-resultados');
      expect(controller.visibleProducts, isEmpty);
      controller.dispose();
    });

    test('el stream del negocio refresca la carta sin recargar', () async {
      final repository = FakeCatalogRepository();
      final controller = CatalogController(repository: repository);
      await controller.load();
      controller.watch();
      await Future<void>.delayed(Duration.zero);

      repository.emit(MenuData.empty);
      await Future<void>.delayed(Duration.zero);
      expect(controller.isEmpty, isTrue);
      expect(controller.state, LoadState.ready);

      controller.dispose();
      repository.dispose();
    });
  });

  group('BranchController', () {
    test('carga las cuatro sedes y resuelve la predeterminada', () async {
      final controller = BranchController(repository: FakeBranchRepository());
      await controller.load();
      expect(controller.state, LoadState.ready);
      expect(controller.branches.length, 4);
      expect(controller.defaultBranch?.id, 'huancayo');
      expect(controller.byId('chilca')?.delivers, isFalse);
      expect(controller.byId('nada'), isNull);
      controller.dispose();
    });

    test('estado vacío y error', () async {
      final empty = BranchController(
        repository: FakeBranchRepository(branches: const []),
      );
      await empty.load();
      expect(empty.isEmpty, isTrue);
      expect(empty.defaultBranch, isNull);

      final failing = BranchController(
        repository: FakeBranchRepository(error: StateError('sin red')),
      );
      await failing.load();
      expect(failing.state, LoadState.error);
      expect(failing.error, 'No se pudieron cargar las sedes.');
      empty.dispose();
      failing.dispose();
    });
  });

  group('PromotionController', () {
    test('lista promociones vigentes y banners', () async {
      final controller = PromotionController(
        repository: FakePromotionRepository(),
      );
      await controller.load();
      expect(controller.state, LoadState.ready);
      expect(controller.active.length, 1);
      expect(controller.banners.length, 1);
      expect(controller.byId('promo-totos')?.priceSoles, 34.90);
      expect(controller.byId('otra'), isNull);

      final promotion = controller.forVariant('pizza-totos', 'entera');
      expect(promotion?.discountedPrice(43.90), 34.90);
      expect(controller.forVariant('coca-600', 'única'), isNull);
      controller.dispose();
    });

    test('una promoción inactiva no entra en la lista activa', () async {
      final controller = PromotionController(
        repository: FakePromotionRepository(
          promotions: const [
            Promotion(
              id: 'vieja',
              title: 'Vieja',
              productId: 'pizza-totos',
              active: false,
            ),
          ],
        ),
      );
      await controller.load();
      expect(controller.promotions.length, 1);
      expect(controller.active, isEmpty);
      expect(controller.banners, isEmpty);
      controller.dispose();
    });
  });

  group('AuthController', () {
    test('inicia sesión y completa el perfil desde Firestore', () async {
      final profiles = FakeProfileRepository();
      final authRepository = FakeAuthRepository();
      final controller = AuthController(
        repository: authRepository,
        profiles: profiles,
      );

      controller.start();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isSignedIn, isFalse);
      expect(controller.state, LoadState.ready);

      final ok = await controller.signIn(
        email: 'ana@example.com',
        password: 'secreto1',
      );
      expect(ok, isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(controller.isSignedIn, isTrue);
      expect(controller.uid, 'uid-1');
      expect(controller.account?.email, 'ana@example.com');
      expect(profiles.profiles.containsKey('uid-1'), isTrue);
      controller.dispose();
      authRepository.dispose();
      profiles.dispose();
    });

    test('error de credenciales no marca sesión', () async {
      final controller = AuthController(
        repository: FakeAuthRepository(),
        profiles: FakeProfileRepository(),
      );
      final ok = await controller.signIn(
        email: 'ana@example.com',
        password: '123',
      );
      expect(ok, isFalse);
      expect(controller.isSignedIn, isFalse);
      expect(controller.error, 'Correo o contraseña incorrectos.');
      expect(controller.isSubmitting, isFalse);
      controller.clearError();
      expect(controller.error, isNull);
      controller.dispose();
    });

    test('registro crea el documento users/{uid}', () async {
      final profiles = FakeProfileRepository();
      final controller = AuthController(
        repository: FakeAuthRepository(),
        profiles: profiles,
      );
      final ok = await controller.signUp(
        name: 'Ana Torres',
        email: 'ana@example.com',
        password: 'secreto1',
      );
      expect(ok, isTrue);
      expect(profiles.profiles['uid-1']?.name, 'Ana Torres');
      controller.dispose();
      profiles.dispose();
    });

    test('actualiza perfil y gestiona direcciones', () async {
      final profiles = FakeProfileRepository();
      final controller = AuthController(
        repository: FakeAuthRepository(),
        profiles: profiles,
      );
      controller.start();
      await Future<void>.delayed(Duration.zero);
      await controller.signUp(
        name: 'Ana',
        email: 'ana@example.com',
        password: 'secreto1',
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.isSignedIn, isTrue);

      expect(await controller.updateProfile(phone: '999 111 222'), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(profiles.profiles['uid-1']?.phone, '999 111 222');
      expect(controller.hasPhone, isTrue);

      expect(
        await controller.addAddress(
          const Address(id: 'a1', label: 'Casa', line: 'Av. Giráldez 123'),
        ),
        isTrue,
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.hasAddress, isTrue);
      expect(await controller.removeAddress('a1'), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(controller.hasAddress, isFalse);
      controller.dispose();
      profiles.dispose();
    });

    test('sin sesión las operaciones de perfil no tocan Firestore', () async {
      final controller = AuthController(
        repository: FakeAuthRepository(),
        profiles: FakeProfileRepository(),
      );
      expect(await controller.updateProfile(phone: '1'), isFalse);
      expect(
        await controller.addAddress(const Address(id: 'a', line: 'L')),
        isFalse,
      );
      expect(await controller.removeAddress('a'), isFalse);
      controller.dispose();
    });
  });

  group('CartController', () {
    late PromotionController promotions;

    setUp(() async {
      promotions = PromotionController(repository: FakePromotionRepository());
      await promotions.load();
    });

    tearDown(() => promotions.dispose());

    Future<CartController> newCart() async {
      final cart = CartController(
        storage: const CartStorage(),
        promotions: promotions,
      );
      await cart.load();
      return cart;
    }

    test('agrega variantes aplicando la promoción vigente', () async {
      final cart = await newCart();
      final product = sampleMenu.byId('pizza-totos')!;

      cart.add(product, product.variants.first);
      expect(cart.isEmpty, isFalse);
      expect(cart.count, 1);
      expect(cart.items.single.unitPriceSoles, 34.90);
      expect(cart.items.single.originalUnitPriceSoles, 43.90);
      expect(cart.subtotalSoles, 43.90);
      expect(cart.discountSoles, 9.00);
      expect(cart.savingsSoles, 9.00);
      expect(cart.totalSoles(shippingSoles: 3.00), 37.90);
      cart.dispose();
    });

    test('suma cantidades, quita líneas y vacía el carrito', () async {
      final cart = await newCart();
      final product = sampleMenu.byId('pizza-totos')!;
      final variant = product.variants.first;

      cart.add(product, variant);
      cart.add(product, variant, quantity: 2);
      expect(
        cart.items.length,
        1,
        reason: 'la misma variante no duplica línea',
      );
      expect(cart.items.single.quantity, 3);
      expect(cart.count, 3);

      final key = cart.items.single.key;
      cart.decrement(key);
      expect(cart.count, 2);
      cart.increment(key);
      expect(cart.count, 3);

      cart.setQuantity(key, 5);
      expect(cart.items.single.quantity, 5);
      cart.setQuantity(key, 0);
      expect(cart.isEmpty, isTrue);

      cart.add(product, variant);
      await Future<void>.delayed(Duration.zero);
      final persisted = await const CartStorage().load();
      expect(persisted.length, 1);

      await cart.clear();
      expect(cart.isEmpty, isTrue);
      expect(await const CartStorage().load(), isEmpty);
      cart.dispose();
    });

    test('agrega masa, extras y componentes y calcula el total', () async {
      final promotions = PromotionController(
        repository: FakePromotionRepository(),
      );
      await promotions.load();
      final cart = CartController(
        storage: const CartStorage(),
        promotions: promotions,
      );
      const product = Product(
        id: 'pizza-americana',
        categoryId: 'pizzas',
        name: 'PIZZA AMERICANA',
        description: '',
        masas: [MasaType.normal, MasaType.masaMadre],
        extras: [ProductExtra(nombre: 'Extra queso', precioSoles: 4)],
        componentes: [
          ProductComponent(
            nombre: 'Pizza mediana',
            cantidad: 1,
            opciones: ['Americana'],
          ),
        ],
        variants: [Variant(label: 'entera', priceSoles: 27.9)],
      );

      cart.add(
        product,
        product.variants.single,
        masa: MasaType.masaMadre,
        extras: product.extras,
        componentes: const [
          SelectedComponent(
            nombre: 'Pizza mediana',
            cantidad: 1,
            opcion: 'Americana',
          ),
        ],
      );

      final item = cart.items.single;
      expect(item.masa, MasaType.masaMadre);
      expect(item.extrasSoles, 4);
      expect(item.unitPriceSoles, 31.9);
      expect(item.key, contains('masa=masaMadre'));
      expect(cart.totalSoles(), 31.9);
      cart.dispose();
      promotions.dispose();
    });

    test('productos sin promoción se guardan con precio de lista', () async {
      final cart = await newCart();
      final product = sampleMenu.byId('coca-600')!;
      cart.add(product, product.variants.first);

      final item = cart.items.single;
      expect(item.unitPriceSoles, 4.90);
      expect(item.isOnPromo, isFalse);
      expect(item.savingsSoles, 0);
      cart.dispose();
    });
  });

  group('CheckoutController', () {
    Future<
      ({
        CheckoutController checkout,
        CartController cart,
        AuthController auth,
        BranchController branches,
        FakeOrderRepository orders,
      })
    >
    build() async {
      final orders = FakeOrderRepository();
      final branches = BranchController(repository: FakeBranchRepository());
      final auth = AuthController(
        repository: FakeAuthRepository(),
        profiles: FakeProfileRepository(),
      );
      final promotions = PromotionController(
        repository: FakePromotionRepository(),
      );
      final settings = SettingsService(repository: FakeSettingsRepository())
        ..apply(sampleSettings);
      final cart = CartController(
        storage: const CartStorage(),
        promotions: promotions,
      );
      await cart.load();
      await branches.load();
      await promotions.load();
      auth.start();
      await Future<void>.delayed(Duration.zero);
      await auth.signUp(
        name: 'Ana Torres',
        email: 'ana@example.com',
        password: 'secreto1',
      );
      await Future<void>.delayed(Duration.zero);

      final checkout = CheckoutController(
        orders: orders,
        cart: cart,
        auth: auth,
        branches: branches,
        settings: settings,
        maps: FakeMapsService(),
        // Dentro del horario de las sedes de ejemplo, para que el test no
        // dependa de la hora real a la que se ejecute.
        now: () => DateTime(2026, 10, 15, 13),
      );
      checkout.initDefaults();
      return (
        checkout: checkout,
        cart: cart,
        auth: auth,
        branches: branches,
        orders: orders,
      );
    }

    test('sin carrito ni sesión avisa cada carencia', () async {
      final env = await build();
      env.auth.signOut();
      await Future<void>.delayed(Duration.zero);

      final issues = env.checkout.validate();
      expect(issues, contains(CheckoutIssue.emptyCart));
      expect(issues, contains(CheckoutIssue.noSession));
      expect(env.checkout.canSubmit, isFalse);
      expect(await env.checkout.submit(), isNull);
      expect(env.checkout.error, CheckoutIssue.emptyCart.message);
      env.checkout.dispose();
    });

    test('con perfil completo confirma el pedido y vacía el carrito', () async {
      final env = await build();
      await env.auth.updateProfile(phone: '999 111 222');
      await env.auth.addAddress(
        const Address(id: 'a1', label: 'Casa', line: 'Av. Giráldez 123'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(env.checkout.account?.phone, '999 111 222');

      final product = sampleMenu.byId('pizza-totos')!;
      env.cart.add(product, product.variants.first);
      env.checkout.initDefaults();
      env.checkout.setDeliveryPoint(
        const DeliveryPoint(
          lat: -12.0651,
          lng: -75.2049,
          label: 'Av. Giráldez 123',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(env.checkout.validate(), isEmpty);
      expect(env.checkout.canSubmit, isTrue);

      final order = await env.checkout.submit();
      expect(order, isNotNull);
      expect(order!.uid, 'uid-1');
      expect(order.status, OrderStatus.pendienteConfirmacion);
      expect(order.totalSoles, 40.90);
      expect(order.shippingSoles, 6.00);
      expect(order.distanciaKm, 3.2);
      expect(order.branchId, 'huancayo');
      expect(order.address, 'Av. Giráldez 123');
      expect(order.customerName, 'Ana Torres');
      expect(order.code, startsWith('TOT-'));
      expect(env.orders.orders.length, 1);
      expect(env.cart.isEmpty, isTrue);
      expect(env.checkout.lastOrder?.id, order.id);

      await env.checkout.markWhatsappSent(order);
      expect(env.orders.orders.single.whatsappSent, isTrue);
      env.checkout.dispose();
    });

    test('delivery exige teléfono y dirección del perfil', () async {
      final env = await build();
      env.cart.add(
        sampleMenu.byId('pizza-totos')!,
        sampleMenu.byId('pizza-totos')!.variants.first,
      );

      final issues = env.checkout.validate();
      expect(issues, contains(CheckoutIssue.noPhone));
      expect(issues, contains(CheckoutIssue.noAddress));
      expect(env.checkout.error, isNull);

      env.checkout.setType(OrderType.pickup);
      expect(env.checkout.shippingSoles, 0);
      expect(
        env.checkout.validate(),
        contains(CheckoutIssue.noPhone),
      );
      env.checkout.setType(OrderType.delivery);
      expect(env.checkout.shippingSoles, 3.00);
      env.checkout.dispose();
    });

    test('una sede sin delivery obliga a recojo', () async {
      final env = await build();
      await env.auth.updateProfile(phone: '999 111 222');
      await Future<void>.delayed(Duration.zero);

      env.checkout.selectBranch('chilca');
      expect(env.checkout.type, OrderType.pickup);
      expect(
        env.checkout.validate(),
        isNot(contains(CheckoutIssue.branchWithoutDelivery)),
      );
      env.checkout.dispose();
    });

    test('una sede cerrada bloquea la confirmación', () async {
      final env = await build();
      await env.auth.updateProfile(phone: '999 111 222');
      await env.auth.addAddress(
        const Address(id: 'a1', label: 'Casa', line: 'Av. Giráldez 123'),
      );
      await Future<void>.delayed(Duration.zero);
      env.cart.add(
        sampleMenu.byId('pizza-totos')!,
        sampleMenu.byId('pizza-totos')!.variants.first,
      );

      // 03:00 en Lima: fuera del horario 12:45–21:30.
      final cerrada = CheckoutController(
        orders: env.orders,
        cart: env.cart,
        auth: env.auth,
        branches: env.branches,
        settings: SettingsService(repository: FakeSettingsRepository())
          ..apply(sampleSettings),
        now: () => DateTime(2026, 10, 15, 3),
      )..initDefaults();

      expect(cerrada.validate(), contains(CheckoutIssue.branchClosed));
      expect(cerrada.canSubmit, isFalse);
      expect(await cerrada.submit(), isNull);
      expect(env.cart.isEmpty, isFalse, reason: 'no debe vaciar el carrito');
      cerrada.dispose();
      env.checkout.dispose();
    });

    test('un fallo de escritura deja el carrito y expone el error', () async {
      final env = await build();
      await env.auth.updateProfile(phone: '999 111 222');
      await env.auth.addAddress(
        const Address(id: 'a1', label: 'Casa', line: 'Av. Giráldez 123'),
      );
      await Future<void>.delayed(Duration.zero);
      env.cart.add(
        sampleMenu.byId('pizza-totos')!,
        sampleMenu.byId('pizza-totos')!.variants.first,
      );
      env.checkout.setDeliveryPoint(
        const DeliveryPoint(
          lat: -12.0651,
          lng: -75.2049,
          label: 'Av. Giráldez 123',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      env.orders.error = const RepositoryException('Sin permisos en orders.');

      expect(await env.checkout.submit(), isNull);
      expect(env.checkout.error, 'Sin permisos en orders.');
      expect(env.cart.isEmpty, isFalse);
      expect(env.checkout.isSubmitting, isFalse);
      env.checkout.dispose();
    });
  });

  group('OrderController', () {
    test('escucha solo los pedidos del uid autenticado', () async {
      final repository = FakeOrderRepository(
        orders: [
          sampleOrder(uid: 'uid-1'),
          sampleOrder(uid: 'uid-2', code: 'TOT-2'),
        ],
      );
      final controller = OrderController(repository: repository);
      controller.bind('uid-1');
      await Future<void>.delayed(Duration.zero);

      expect(controller.state, LoadState.ready);
      expect(controller.orders.single.uid, 'uid-1');

      controller.bind('uid-2');
      await Future<void>.delayed(Duration.zero);
      expect(controller.orders.single.uid, 'uid-2');

      controller.bind('');
      expect(controller.isEmpty, isTrue);
      expect(controller.state, LoadState.idle);
      controller.dispose();
      repository.dispose();
    });

    test('un uid sin pedidos queda vacío y el error se reporta', () async {
      final repository = FakeOrderRepository();
      final controller = OrderController(repository: repository);
      controller.bind('uid-1');
      await Future<void>.delayed(Duration.zero);
      expect(controller.isEmpty, isTrue);
      expect(controller.state, LoadState.ready);

      repository.error = StateError('offline');
      await controller.load();
      expect(controller.state, LoadState.error);
      expect(controller.error, 'No se pudo cargar tu historial.');
      controller.dispose();
      repository.dispose();
    });
  });

  group('ClaimController', () {
    test('envía un reclamo con código REC y estado enviado', () async {
      final repository = FakeClaimRepository();
      final controller = ClaimController(
        repository: repository,
        settings: SettingsService(repository: FakeSettingsRepository()),
      );
      controller.bind('uid-1');
      await Future<void>.delayed(Duration.zero);

      final claim = await controller.submit(
        const ClaimDraft(
          uid: 'uid-1',
          categoryId: 'demora',
          categoryLabel: 'Demora en la entrega',
          message: '  Mi pedido llegó tarde.  ',
        ),
      );
      expect(claim, isNotNull);
      expect(claim!.code, startsWith('REC-'));
      expect(claim.message, 'Mi pedido llegó tarde.');
      expect(claim.categoryId, 'demora');
      expect(repository.claims.length, 1);
      expect(controller.isSubmitting, isFalse);
      controller.dispose();
      repository.dispose();
    });

    test('mensaje vacío no crea documento', () async {
      final repository = FakeClaimRepository();
      final controller = ClaimController(
        repository: repository,
        settings: SettingsService(repository: FakeSettingsRepository()),
      );
      final claim = await controller.submit(
        const ClaimDraft(
          uid: 'uid-1',
          categoryId: 'otro',
          categoryLabel: 'Otro motivo',
          message: '   ',
        ),
      );
      expect(claim, isNull);
      expect(controller.error, 'Cuéntanos qué pasó para poder ayudarte.');
      expect(repository.claims, isEmpty);
      controller.clearError();
      expect(controller.error, isNull);
      controller.dispose();
      repository.dispose();
    });

    test('error de Firestore se expone sin perder el borrador', () async {
      final repository = FakeClaimRepository(
        error: const RepositoryException('No se pudo enviar.'),
      );
      final controller = ClaimController(
        repository: repository,
        settings: SettingsService(repository: FakeSettingsRepository()),
      );
      final claim = await controller.submit(
        const ClaimDraft(
          uid: 'uid-1',
          categoryId: 'otro',
          categoryLabel: 'Otro motivo',
          message: 'Texto',
        ),
      );
      expect(claim, isNull);
      expect(controller.error, 'No se pudo enviar.');
      controller.dispose();
      repository.dispose();
    });

    test('expone los motivos configurados por el negocio', () {
      final controller = ClaimController(
        repository: FakeClaimRepository(),
        settings: SettingsService(repository: FakeSettingsRepository())
          ..apply(sampleSettings),
      );
      expect(controller.reasons.length, 5);
      controller.dispose();
    });
  });
}
