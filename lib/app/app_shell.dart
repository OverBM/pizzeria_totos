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
import '../views/claims/claims_view.dart';
import '../views/home/home_view.dart';
import '../views/promotions/promotions_view.dart';
import 'routes.dart';

/// Contenedor principal: barra superior, `IndexedStack` y cinco destinos.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int _cartaTab = 1;
  static const int _promosTab = 2;
  static const int _sedesTab = 3;
  static const int _claimsTab = 4;

  int _index = 0;

  void _goTo(int index) {
    if (_index == index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  void _moveBy(int delta, int maxIndex) {
    final current = _index.clamp(0, maxIndex);
    _goTo((current + delta).clamp(0, maxIndex));
  }

  void _openProduct(Product product, {String? variantLabel}) {
    Navigator.of(context)
        .push(AppRoutes.product(product, variantLabel: variantLabel));
  }

  void _openLogin() {
    Navigator.of(context).push(AppRoutes.login());
  }

  Future<void> _openProfile() async {
    final auth = context.read<AuthController>();
    if (!auth.isSignedIn) {
      final logged = await Navigator.of(context).push<bool>(AppRoutes.login());
      if (!mounted || logged != true) return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(AppRoutes.profile());
  }

  void _openOrders() {
    Navigator.of(context).push(AppRoutes.orders());
  }

  void _openCart() {
    Navigator.of(context).push(
      AppRoutes.cart(
        onGoToCarta: () {
          Navigator.of(context).pop();
          _goTo(_cartaTab);
        },
        onOpenAuth: _openLogin,
        onOpenProfile: _openProfile,
        onOpenOrders: _openOrders,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final auth = context.watch<AuthController>();
    final maxIndex = auth.isSignedIn ? _claimsTab : _sedesTab;
    final selected = _index > maxIndex ? 0 : _index;
    if (_index > maxIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _index = 0);
      });
    }

    return Scaffold(
      appBar: TotoTopBar(
        onWordmarkTap: () => _goTo(0),
        actions: [
          if (auth.isSignedIn)
            IconButton(
              onPressed: _openOrders,
              tooltip: 'Mis pedidos',
              icon: const OrdersIcon(size: 22),
            ),
          CartBadge(count: cart.count, onPressed: _openCart),
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
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity.abs() < 260) return;
                _moveBy(velocity < 0 ? 1 : -1, maxIndex);
              },
              child: IndexedStack(
                index: selected,
                children: [
                HeroMode(
                  enabled: selected == 0,
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
                    onGoToPromotions: () => _goTo(_promosTab),
                    onGoToProduct: _openProduct,
                  ),
                ),
                HeroMode(
                  enabled: selected == _cartaTab,
                  child: CartaView(onGoToProduct: _openProduct),
                ),
                HeroMode(
                  enabled: selected == _promosTab,
                  child: PromotionsView(
                    embedded: true,
                    onOpenProduct: _openProduct,
                  ),
                ),
                HeroMode(
                  enabled: selected == _sedesTab,
                  child: const BranchesView(),
                ),
                HeroMode(
                  enabled: selected == _claimsTab,
                  child: ClaimsView(
                    onOpenAuth: _openLogin,
                    onOpenClaim: (Claim claim) =>
                        Navigator.of(context).push(AppRoutes.claim(claim)),
                  ),
                ),
              ],
            ),
          ),
        ),
        ],
      ),
      bottomNavigationBar: TotoBottomNav(
        index: selected,
        onSelect: _goTo,
        items: [
          const TotoNavItem(
            icon: Icons.home_outlined,
            label: 'Inicio',
            pageIndex: 0,
          ),
          const TotoNavItem(
            icon: Icons.restaurant_menu_rounded,
            label: 'Carta',
            pageIndex: 1,
          ),
          const TotoNavItem(
            icon: Icons.local_offer_outlined,
            label: 'Promos',
            pageIndex: 2,
          ),
          const TotoNavItem(
            icon: Icons.place_outlined,
            label: 'Sedes',
            pageIndex: 3,
          ),
          if (auth.isSignedIn)
            TotoNavItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Reclamos',
              pageIndex: 4,
              iconWidget: ClaimsTabIcon(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}
