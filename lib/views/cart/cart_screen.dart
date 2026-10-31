import 'package:flutter/material.dart';

import '../../core/theme/brand.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TotoTopBar(
        showWordmark: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TU PEDIDO',
                style: Brand.display(22, h: 1),
              ),
            ),
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
    );
  }
}
