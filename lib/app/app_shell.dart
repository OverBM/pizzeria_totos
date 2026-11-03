import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/catalog_controller.dart';
import '../core/motion/motion.dart';
import '../core/theme/brand.dart';
import '../core/theme/theme_context.dart';
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
  static const int _supportTab = 4;

  int _index = 0;
  int _lastFeedbackId = 0;
  Timer? _feedbackTimer;

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

  void _openPlans() {
    Navigator.of(context).push(AppRoutes.subscription());
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
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final auth = context.watch<AuthController>();
    if (cart.feedbackId != _lastFeedbackId) {
      _lastFeedbackId = cart.feedbackId;
      final message = cart.feedbackMessage;
      if (message != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          HapticFeedback.lightImpact();
          final messenger = ScaffoldMessenger.of(context);
          final colors = context.colors;
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                backgroundColor: colors.bar,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colors.action.withValues(alpha: 0.9),
                    width: 1.2,
                  ),
                ),
                content: Semantics(
                  liveRegion: true,
                  label: message,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: colors.action.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/add_to_cart.svg',
                          colorFilter: ColorFilter.mode(
                            colors.action,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Brand.ui(
                            12.5,
                            weight: FontWeight.w600,
                            color: colors.onBar,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: _openCart,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.action,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: Brand.ui(10, weight: FontWeight.w700),
                        ),
                        child: const Text('VER'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          // En algunos dispositivos con navegación accesible el SnackBar con
          // acción no expira solo; lo cerramos nosotros para que no se quede
          // tapando la pantalla.
          _feedbackTimer?.cancel();
          _feedbackTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) messenger.hideCurrentSnackBar();
          });
        });
      }
    }
    final visibleOrder = auth.isSignedIn
        ? const [0, _cartaTab, _promosTab, _sedesTab, _supportTab]
        : const [0, _cartaTab, _promosTab, _sedesTab];
    final selected = visibleOrder.contains(_index) ? _index : 0;
    if (!visibleOrder.contains(_index)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _index = 0);
      });
    }

    return Scaffold(
      appBar: TotoTopBar(
        onWordmarkTap: () => _goTo(0),
        actions: [
          if (auth.isSignedIn) ...[
            IconButton(
              onPressed: _openPlans,
              tooltip: 'Planes',
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: SvgPicture.asset(
                'assets/icons/plans/base_plan.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  context.colors.onBar,
                  BlendMode.srcIn,
                ),
              ),
            ),
            IconButton(
              onPressed: _openOrders,
              tooltip: 'Mis pedidos',
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const OrdersIcon(size: 20),
            ),
          ],
          CartBadge(count: cart.count, onPressed: _openCart),
          IconButton(
            onPressed: _openProfile,
            tooltip: auth.isSignedIn ? 'Mi perfil' : 'Iniciar sesión',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
            // `HeroMode` desactiva los `Hero` de las pestañas no visibles:
            // con el mismo producto en Inicio y Carta, una transición a
            // cualquier ruta abortaba con «multiple heroes that share the same
            // tag».
            child: _SwipeTabs(
              index: selected,
              order: visibleOrder,
              onChanged: _goTo,
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
                  enabled: selected == _supportTab,
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
            const TotoNavItem(
              icon: Icons.support_agent_rounded,
              label: 'Soporte',
              pageIndex: 4,
            ),
        ],
      ),
    );
  }
}

/// Pestañas deslizables horizontalmente, con el mismo gesto y animación que
/// un `PageView`, conservando el estado de cada destino.
class _SwipeTabs extends StatefulWidget {
  const _SwipeTabs({
    required this.index,
    required this.order,
    required this.onChanged,
    required this.children,
  });

  final int index;
  final List<int> order;
  final ValueChanged<int> onChanged;
  final List<Widget> children;

  @override
  State<_SwipeTabs> createState() => _SwipeTabsState();
}

class _SwipeTabsState extends State<_SwipeTabs> {
  late final PageController _controller;
  late int _page;
  int? _animatingTo;

  int get _lastPage => widget.order.isEmpty ? 0 : widget.order.length - 1;

  int _pageFor(int stackIndex) {
    final page = widget.order.indexOf(stackIndex);
    return page < 0 ? 0 : page.clamp(0, _lastPage);
  }

  @override
  void initState() {
    super.initState();
    _page = _pageFor(widget.index);
    _controller = PageController(initialPage: _page);
  }

  @override
  void didUpdateWidget(covariant _SwipeTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _pageFor(widget.index);
    final orderChanged = oldWidget.order.length != widget.order.length;
    if (orderChanged) {
      _page = target;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        if ((_controller.page ?? 0).round() != target) {
          _controller.jumpToPage(target);
        }
      });
      return;
    }
    if (target == _page || !_controller.hasClients) return;
    _page = target;
    _animatingTo = target;
    _controller
        .animateToPage(
          target,
          duration: Motion.resolve(context, Motion.base),
          curve: Motion.standard,
        )
        .whenComplete(() {
          if (mounted && _animatingTo == target) _animatingTo = null;
        });
  }

  void _onPageChanged(int page) {
    if (_animatingTo != null || page == _page) return;
    setState(() => _page = page);
    widget.onChanged(widget.order[page]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      key: const ValueKey('shell-pager'),
      controller: _controller,
      onPageChanged: _onPageChanged,
      physics: const ClampingScrollPhysics(),
      children: [
        for (final stackIndex in widget.order)
          _KeepAlivePage(
            key: ValueKey('shell-tab-$stackIndex'),
            child: widget.children[stackIndex],
          ),
      ],
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({super.key, required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
