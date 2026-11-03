import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/core/auth/alias_policy.dart';
import 'package:pizzeria_totos/core/format/money.dart';
import 'package:pizzeria_totos/core/pizza/pizza_timing.dart';
import 'package:pizzeria_totos/core/pricing/order_pricing.dart';
import 'package:pizzeria_totos/models/cart_item.dart';
import 'package:pizzeria_totos/models/coupon.dart';
import 'package:pizzeria_totos/models/custom_pizza.dart';
import 'package:pizzeria_totos/models/ingredient.dart';
import 'package:pizzeria_totos/models/pizza_config.dart';
import 'package:pizzeria_totos/models/subscription.dart';

PizzaConfig _config() => const PizzaConfig(
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

void main() {
  group('Pizza personalizada', () {
    test('calcula precio exacto con multiplicador por tamaño', () {
      final config = _config();
      final selection = CustomPizzaSelection.calculate(
        config: config,
        size: config.sizes[1],
        dough: config.doughs[0],
        sauce: config.sauces[0],
        cheese: config.cheeses[0],
        ingredients: const [
          Ingredient(
            id: 'pepperoni',
            name: 'Pepperoni',
            category: 'carnes',
            priceSoles: 4,
          ),
        ],
      );
      expect(selection.unitPriceSoles, 28.5); // 22.90 + 4.00 × 1.4
      expect(selection.preparationMinutes, 18); // 15 + 2 + 1
      expect(selection.ovenWeight, 1);
    });

    test('sin queso resta y no deja el precio negativo', () {
      final config = _config();
      final selection = CustomPizzaSelection.calculate(
        config: config,
        size: config.sizes[0],
        dough: config.doughs[0],
        sauce: config.sauces[0],
        cheese: config.cheeses[1],
        ingredients: const [],
      );
      expect(selection.unitPriceSoles, 12.9);
    });

    test('la clave incluye la configuración y tolera carrito antiguo', () {
      final config = _config();
      final selection = CustomPizzaSelection.calculate(
        config: config,
        size: config.sizes[0],
        dough: config.doughs[1],
        sauce: config.sauces[1],
        cheese: config.cheeses[0],
        ingredients: const [
          Ingredient(
            id: 'pepperoni',
            name: 'Pepperoni',
            category: 'carnes',
            priceSoles: 4,
          ),
        ],
      );
      final item = CartItem(
        productId: 'pizza-personalizada',
        name: 'Pizza personalizada',
        variantLabel: 'PERSONAL',
        unitPriceSoles: selection.unitPriceSoles,
        quantity: 2,
        customPizza: selection,
        preparationMinutes: selection.preparationMinutes,
      );
      expect(item.isCustomPizza, isTrue);
      expect(item.key, contains('custom='));
      expect(item.toMap()['customPizza'], isA<Map>());
      final old = CartItem.fromMap({
        'productoId': 'pizza-totos',
        'nombre': 'Pizza',
        'etiquetaVariante': 'entera',
        'precioUnitario': 43.9,
        'cantidad': 1,
      });
      expect(old.customPizza, isNull);
    });
  });

  group('Cupones', () {
    final active = Coupon(
      id: 'TEST10',
      code: 'TEST10',
      type: CouponType.percentage,
      value: 10,
      maxUses: 10,
      uses: 0,
      minimumSubtotalSoles: 40,
      expiresAt: DateTime(2027, 12, 31),
    );

    test('valida mínimo después de promociones y descuenta', () {
      expect(
        active.validate(
          baseSoles: 35,
          limaWallClock: DateTime(2026, 10, 15),
        ),
        CouponFailure.minimumNotMet,
      );
      expect(active.discountFor(90), 9);
    });

    test('distingue vencido y agotado', () {
      expect(
        active.validate(
          baseSoles: 50,
          limaWallClock: DateTime(2028, 1, 1),
        ),
        CouponFailure.expired,
      );
      final exhausted = Coupon(
        id: 'X',
        code: 'X',
        type: CouponType.fixedAmount,
        value: 5,
        maxUses: 1,
        uses: 1,
      );
      expect(
        exhausted.validate(
          baseSoles: 50,
          limaWallClock: DateTime(2026, 10, 15),
        ),
        CouponFailure.exhausted,
      );
    });
  });

  group('Pricing', () {
    test('cupón se aplica después de promociones y antes del envío', () {
      final pricing = OrderPricing.calculate(
        subtotalSoles: 100,
        promotionDiscountSoles: 10,
        couponDiscountSoles: 9,
        shippingOriginalSoles: 6,
        shippingCovered: false,
      );
      expect(pricing.totalSoles, 87);
      expect(pricing.shippingChargedSoles, 6);
    });

    test('envío cubierto no reduce el cupón', () {
      final pricing = OrderPricing.calculate(
        subtotalSoles: 100,
        promotionDiscountSoles: 0,
        couponDiscountSoles: 10,
        shippingOriginalSoles: 6,
        shippingCovered: true,
      );
      expect(pricing.totalSoles, 90);
      expect(pricing.shippingChargedSoles, 0);
    });
  });

  group('Alias', () {
    test('bloquea reservados y soeces con variantes', () {
      expect(AliasPolicy.validate('admin'), isNotNull);
      expect(AliasPolicy.validate('p.u.t.a'), isNotNull);
      expect(AliasPolicy.validate('pvt4'), isNotNull);
      expect(AliasPolicy.validate('ana.torres'), isNull);
    });
  });

  group('Suscripción', () {
    test('cancelada mantiene el beneficio hasta vencer', () {
      final start = DateTime(2026, 10, 1);
      final sub = Subscription(
        uid: 'u',
        planId: 'la-previa',
        planName: 'La Previa',
        priceSoles: 14.9,
        startAt: start,
        endAt: start.add(const Duration(days: 30)),
        periodStart: start,
        status: SubscriptionStatus.cancelled,
      );
      expect(sub.isActiveAt(DateTime(2026, 10, 15)), isTrue);
      expect(sub.isActiveAt(DateTime(2026, 11, 15)), isFalse);
      expect(sub.daysRemainingAt(DateTime(2026, 10, 15)), greaterThan(0));
    });

    test('detecta arrepentimiento y aviso de renovación', () {
      final now = DateTime.now();
      final sub = Subscription(
        uid: 'u',
        planId: 'la-previa',
        planName: 'La Previa',
        priceSoles: 14.9,
        startAt: now,
        endAt: now.add(const Duration(days: 30)),
        periodStart: now,
        autoRenew: true,
      );
      expect(sub.canRefundAt(now), isTrue);
      expect(sub.copyWith(shipmentsUsed: 1).canRefundAt(now), isFalse);
      expect(
        sub.copyWith(endAt: now.add(const Duration(hours: 24))).renewalWarningDue,
        isTrue,
      );
      expect(
        sub.copyWith(autoRenew: false).renewalWarningDue,
        isFalse,
      );
    });
  });

  test('Money conserva céntimos para el cálculo de pizza', () {
    expect(Money.toCents(22.9), 2290);
    expect(Money.fromCents(2290), 22.9);
  });

  group('PizzaTiming', () {
    test('usa un lote para 2 medianas', () {
      expect(
        PizzaTiming.preparationMinutes(
          batchMinutes: [18],
          ovenWeight: 2,
          ovenCapacity: 4,
          recoveryMinutes: 0,
          baseMinutes: 20,
          measured: true,
        ),
        20,
      );
    });

    test('calcula dos lotes y recuperación', () {
      expect(
        PizzaTiming.preparationMinutes(
          batchMinutes: [20],
          ovenWeight: 6.5,
          ovenCapacity: 4,
          recoveryMinutes: 3,
          baseMinutes: 20,
          measured: true,
        ),
        43,
      );
    });

    test('suma 5 min cuando no hay medición', () {
      expect(
        PizzaTiming.preparationMinutes(
          batchMinutes: [18],
          ovenWeight: 1,
          ovenCapacity: 4,
          recoveryMinutes: 0,
          baseMinutes: 15,
          measured: false,
        ),
        23,
      );
    });

    test('sin pizzas personalizadas usa la base sin margen', () {
      expect(
        PizzaTiming.preparationMinutes(
          batchMinutes: [],
          ovenWeight: 0,
          ovenCapacity: 4,
          recoveryMinutes: 0,
          baseMinutes: 20,
          measured: false,
        ),
        20,
      );
    });
  });
}
