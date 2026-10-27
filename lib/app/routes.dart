import 'package:flutter/material.dart';

import '../core/motion/motion_widgets.dart';
import '../models/claim.dart';
import '../models/product.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/carta/product_detail_view.dart';
import '../views/cart/orders_view.dart';
import '../views/claims/claim_detail_view.dart';
import '../views/profile/profile_view.dart';
import '../views/promotions/promotions_view.dart';

/// Rutas de la app, todas con la transición breve del sistema de movimiento.
///
/// Las pestañas viven en el `IndexedStack` del shell; estas rutas son las
/// pantallas que se abren por encima (detalle, cuenta, perfil y listas).
class AppRoutes {
  const AppRoutes._();

  static Route<T> login<T>({String? message}) =>
      MotionRoute<T>(builder: (_) => LoginView(message: message));

  static Route<T> register<T>() =>
      MotionRoute<T>(builder: (_) => const RegisterView());

  static Route<T> profile<T>() =>
      MotionRoute<T>(builder: (_) => const ProfileView());

  static Route<T> orders<T>() =>
      MotionRoute<T>(builder: (_) => const OrdersView());

  static Route<T> product<T>(Product product, {String? variantLabel}) =>
      MotionRoute<T>(
        builder: (_) => ProductDetailView(
          product: product,
          initialVariantLabel: variantLabel,
        ),
      );

  static Route<T> claim<T>(Claim claim) =>
      MotionRoute<T>(builder: (_) => ClaimDetailView(claim: claim));

  static Route<T> promotions<T>({
    required void Function(Product product, {String? variantLabel})
    onOpenProduct,
  }) => MotionRoute<T>(
    builder: (_) => PromotionsView(onOpenProduct: onOpenProduct),
  );
}
