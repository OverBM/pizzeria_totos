import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/catalog_controller.dart';
import '../widgets/widgets.dart';
import '../models/claim.dart';
import '../models/product.dart';
import '../views/branches/branches_view.dart';
import '../views/carta/carta_view.dart';
import '../views/cart/cart_view.dart';
import '../views/claims/claims_view.dart';
import '../views/home/home_view.dart';
import 'routes.dart';

/// Contenedor principal: barra superior, `IndexedStack` y cinco destinos.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int _cartaTab = 1;
  static const int _pedidoTab = 2;
  static const int _sedesTab = 3;

  int _index = 0;

  void _goTo(int index) {
    if (_index == index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  void _openProduct(Product product, {String? variantLabel}) {
    Navigator.of(context)
        .push(AppRoutes.product(product, variantLabel: variantLabel));
  }

  void _openLogin() {
    Navigator.of(context).push(AppRoutes.login());
  }

  void _openProfile() {
    Navigator.of(context).push(AppRoutes.profile());
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: TotoTopBar(
        actions: [
          CartBadge(count: cart.count, onPressed: () => _goTo(_pedidoTab)),
          IconButton(
            onPressed: _openProfile,
            tooltip: auth.isSignedIn ? 'Mi perfil' : 'Iniciar sesión',
            icon: Icon(
              auth.isSignedIn
                  ? Icons.person_rounded
                  : Icons.person_outline_rounded,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(margin: EdgeInsets.fromLTRB(16, 8, 16, 0)),
          Expanded(
            // `HeroMode` desactiva los `Hero` de las pestañas ocultas: el
            // `IndexedStack` las mantiene montadas y, con el mismo producto en
            // Inicio y Carta, la transición a cualquier ruta abortaba con
            // «multiple heroes that share the same tag».
            child: IndexedStack(
              index: _index,
              children: [
                HeroMode(
                  enabled: _index == 0,
                  child: HomeView(
                    onGoToCarta: (categoryId) {
                      if (categoryId != null) {
                        context.read<CatalogController>().selectCategory(
                          categoryId,
                        );
                      }
                      _goTo(_cartaTab);
                    },
                    onGoToSedes: () => _goTo(_sedesTab),
                    onGoToPromotions: () => Navigator.of(
                      context,
                    ).push(AppRoutes.promotions(onOpenProduct: _openProduct)),
                    onGoToProduct: _openProduct,
                  ),
                ),
                HeroMode(
                  enabled: _index == 1,
                  child: CartaView(onGoToProduct: _openProduct),
                ),
                HeroMode(
                  enabled: _index == 2,
                  child: CartView(
                    onGoToCarta: () => _goTo(_cartaTab),
                    onOpenAuth: _openLogin,
                    onOpenProfile: _openProfile,
                    onOpenOrders: () =>
                        Navigator.of(context).push(AppRoutes.orders()),
                  ),
                ),
                HeroMode(enabled: _index == 3, child: const BranchesView()),
                HeroMode(
                  enabled: _index == 4,
                  child: ClaimsView(
                    onOpenAuth: _openLogin,
                    onOpenClaim: (Claim claim) =>
                        Navigator.of(context).push(AppRoutes.claim(claim)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: TotoBottomNav(
        index: _index,
        onSelect: _goTo,
        cartCount: cart.count,
        cartIndex: _pedidoTab,
        items: [
          const TotoNavItem(icon: Icons.home_outlined, label: 'Inicio'),
          const TotoNavItem(
            icon: Icons.restaurant_menu_rounded,
            label: 'Carta',
          ),
          const TotoNavItem(icon: Icons.shopping_bag_outlined, label: 'Pedido'),
          const TotoNavItem(icon: Icons.place_outlined, label: 'Sedes'),
          TotoNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Reclamos',
            iconWidget: ClaimsTabIcon(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
