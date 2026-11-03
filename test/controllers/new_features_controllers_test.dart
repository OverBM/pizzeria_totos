import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/controllers/coupon_controller.dart';
import 'package:pizzeria_totos/controllers/custom_pizza_controller.dart';
import 'package:pizzeria_totos/controllers/subscription_controller.dart';
import 'package:pizzeria_totos/models/coupon.dart';
import 'package:pizzeria_totos/models/subscription.dart';

import '../support/fakes.dart';

void main() {
  test('CouponController aplica y rechaza por compra mínima', () async {
    final repository = FakeCouponRepository(
      coupons: {
        'TOTOS10': Coupon(
          id: 'TOTOS10',
          code: 'TOTOS10',
          type: CouponType.percentage,
          value: 10,
          maxUses: 10,
          uses: 0,
          minimumSubtotalSoles: 40,
          expiresAt: DateTime(2027, 12, 31),
        ),
      },
    );
    final controller = CouponController(repository: repository);
    expect(await controller.apply(code: 'TOTOS10', baseSoles: 30), isFalse);
    expect(controller.message, contains('faltan'));
    expect(await controller.apply(code: 'totos10', baseSoles: 50), isFalse);
    expect(controller.message, 'Cupón no válido.');
    expect(await controller.apply(code: 'TOTOS10', baseSoles: 50), isTrue);
    expect(controller.discountFor(50), 5);
    controller.clear();
    expect(controller.hasCoupon, isFalse);
  });

  test('CustomPizzaController carga, limita y calcula', () async {
    final controller = CustomPizzaController(repository: FakePizzaRepository());
    await controller.load();
    expect(controller.isReady, isTrue);
    expect(controller.selection, isNotNull);
    expect(controller.preparationMinutes, greaterThan(0));
    controller.selectSize(controller.config.sizes.first);
    controller.toggleIngredient(controller.ingredients.first);
    expect(controller.selectedIngredientIds, contains('pepperoni'));
  });

  test('SubscriptionController activa La Previa y cubre envío', () async {
    final repository = FakeSubscriptionRepository();
    final controller = SubscriptionController(repository: repository);
    controller.bind('u1');
    controller.watch();
    await Future<void>.delayed(Duration.zero);
    expect(controller.currentPlanName, 'El Antojo');
    final ok = await controller.activate(samplePlans.first);
    await Future<void>.delayed(Duration.zero);
    expect(ok, isTrue);
    expect(controller.isActive, isTrue);
    expect(controller.currentPlanName, 'La Previa');
    expect(
      controller.coversShipping(
        subtotalAfterPromotions: 40,
        minimumOrderSoles: 20,
        isDelivery: true,
      ),
      isTrue,
    );

    final firstEnd = controller.subscription!.endAt;
    await controller.activate(samplePlans.first);
    await Future<void>.delayed(Duration.zero);
    expect(controller.subscription!.endAt.isAfter(firstEnd), isTrue);

    await controller.registerShipment();
    await controller.cancel();
    await Future<void>.delayed(Duration.zero);
    expect(controller.subscription!.status, SubscriptionStatus.cancelled);
    expect(controller.paidSubscription, isNotNull);
  });
}
