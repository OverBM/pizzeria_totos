import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_services.dart';
import '../controllers/auth_controller.dart';
import '../controllers/branch_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/catalog_controller.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/claim_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/promotion_controller.dart';
import '../services/connectivity_service.dart';
import '../services/location/location_service.dart';
import '../services/settings_service.dart';

/// Expone los servicios y controladores a las vistas.
class AppScope extends StatelessWidget {
  const AppScope({super.key, required this.services, required this.child});

  final AppServices services;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppServices>.value(value: services),
        Provider<SettingsService>.value(value: services.settings),
        Provider<LocationService>.value(value: services.locationService),
        ChangeNotifierProvider<ConnectivityService>.value(
          value: services.connectivity,
        ),
        ChangeNotifierProvider<AuthController>.value(value: services.auth),
        ChangeNotifierProvider<CatalogController>.value(
          value: services.catalog,
        ),
        ChangeNotifierProvider<BranchController>.value(
          value: services.branches,
        ),
        ChangeNotifierProvider<PromotionController>.value(
          value: services.promotions,
        ),
        ChangeNotifierProvider<CartController>.value(value: services.cart),
        ChangeNotifierProvider<OrderController>.value(value: services.orders),
        ChangeNotifierProvider<ClaimController>.value(value: services.claims),
        ChangeNotifierProvider<CheckoutController>.value(
          value: services.checkout,
        ),
      ],
      child: child,
    );
  }
}
