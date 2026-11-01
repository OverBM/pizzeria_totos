import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/checkout_controller.dart';
import '../../core/theme/brand.dart';
import '../../models/checkout_step.dart';
import '../../widgets/widgets.dart';
import 'cart_view.dart';

/// Carrito como pantalla propia, abierto desde el icono de la barra superior.
class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    required this.onGoToCarta,
    required this.onOpenAuth,
    required this.onOpenProfile,
    required this.onOpenOrders,
  });

  final VoidCallback onGoToCarta;
  final VoidCallback onOpenAuth;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenOrders;

  void _continueToDelivery(BuildContext context) {
    final checkout = context.read<CheckoutController>();
    final issues = checkout.validateStep(CheckoutStep.pedido);
    if (issues.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(issues.first.message)));
      return;
    }
    Navigator.of(context).push(AppRoutes.checkoutDelivery());
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    return Scaffold(
      appBar: TotoTopBar(
        showWordmark: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: CheckoutProgress(step: CheckoutStep.pedido),
          ),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: CartView(
              onGoToCarta: onGoToCarta,
              onOpenAuth: onOpenAuth,
              onOpenProfile: onOpenProfile,
              onOpenOrders: onOpenOrders,
            ),
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.fromLTRB(
                  Brand.s16,
                  Brand.s8,
                  Brand.s16,
                  Brand.s8,
                ),
                child: PillButton(
                  label: 'CONTINUAR CON LA ENTREGA',
                  expanded: true,
                  showArrow: true,
                  onPressed: () => _continueToDelivery(context),
                ),
              ),
            ),
    );
  }
}
