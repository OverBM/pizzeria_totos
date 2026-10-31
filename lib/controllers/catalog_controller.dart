import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/format/money.dart';
import '../core/load_state.dart';
import '../models/catalog_filters.dart';
import '../models/menu_data.dart';
import '../models/product.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/repository_exception.dart';
import 'promotion_controller.dart';

/// Categorías y productos de la carta (Firestore como única fuente).
class CatalogController extends ChangeNotifier {
  CatalogController({
    required CatalogRepository repository,
    PromotionController? promotions,
  }) : _repository = repository,
       _promotions = promotions;

  final CatalogRepository _repository;
  final PromotionController? _promotions;
  StreamSubscription<MenuData>? _subscription;

  LoadState _state = LoadState.idle;
  MenuData _menu = MenuData.empty;
  String? _error;
  static const String featuredCategoryId = 'mas-pedidas';
  static const String allCategoryId = 'todos';

  String _selectedCategoryId = featuredCategoryId;
  CatalogFilters _filters = const CatalogFilters();

  LoadState get state => _state;
  MenuData get menu => _menu;
  String? get error => _error;
  String get selectedCategoryId => _selectedCategoryId;
  CatalogFilters get filters => _filters;
  String get searchQuery => _filters.query;
  bool get hasActiveFilters => _filters.isActive;

  bool get isEmpty => _menu.isEmpty;

  /// ¿Hay productos disponibles para mostrar?
  ///
  /// Se basa en los productos, no en `MenuData.isEmpty`: un catálogo con
  /// categorías pero sin productos no debe quedar reducido a los chips.
  bool get hasProducts => _menu.products.any((p) => p.available);

  /// Productos disponibles, en el orden de la carta.
  List<Product> get listedProducts =>
      _menu.products.where((p) => p.available).toList();

  /// Destacados disponibles (vacío si ninguno lo está).
  List<Product> get featured => _menu.products
      .where((p) => p.featured && p.available)
      .toList();

  /// Favoritas del Inicio: destacados o, si no hay, los primeros productos.
  ///
  /// Garantiza que el Inicio muestre productos aunque el negocio no marque
  /// ningún destacado en Firestore.
  List<Product> get homeHighlights {
    final highlighted = featured;
    if (highlighted.isNotEmpty) return highlighted;
    return listedProducts.take(6).toList();
  }

  /// Hasta 6 productos del catálogo que no repiten las favoritas.
  List<Product> get homePreview {
    final seen = homeHighlights.map((p) => p.id).toSet();
    return listedProducts
        .where((p) => !seen.contains(p.id))
        .take(6)
        .toList();
  }

  List<Product> get visibleProducts {
    return _basePool.where((product) => matchesFilters(product)).toList();
  }

  /// ¿El producto cumple la búsqueda y los filtros activos?
  ///
  /// [price] permite evaluar el precio promocional en la pantalla de Promos.
  bool matchesFilters(Product product, {double? price}) {
    final query = _normalize(_filters.query.trim());
    if (query.isNotEmpty) {
      final haystack = _normalize([
        product.name,
        product.description,
        ...product.ingredients,
        ...product.tags,
      ].join(' '));
      if (!haystack.contains(query)) return false;
    }

    if (!_filters.calorieBand.matches(product.calories)) return false;

    if (_filters.excludedAllergens.isNotEmpty) {
      for (final allergen in _filters.excludedAllergens) {
        if (allergen.toLowerCase() == 'gluten') {
          if (!product.isGlutenFree) return false;
        } else if (product.allergens.any(
          (item) => item.toLowerCase() == allergen.toLowerCase(),
        )) {
          return false;
        }
      }
    }

    final effectivePrice = price ?? _effectiveMinPrice(product);
    if (effectivePrice < _filters.minPrice ||
        effectivePrice > _filters.maxPrice) {
      return false;
    }
    if (_filters.hasPriceThreshold) {
      final threshold = _filters.priceThreshold!;
      if (_filters.priceComparison == PriceComparison.below &&
          effectivePrice >= threshold) {
        return false;
      }
      if (_filters.priceComparison == PriceComparison.above &&
          effectivePrice <= threshold) {
        return false;
      }
    }
    return true;
  }

  List<Product> get _basePool {
    // La búsqueda es global: ignora la categoría seleccionada.
    if (_filters.query.trim().isNotEmpty) return listedProducts;
    if (_selectedCategoryId == allCategoryId) return listedProducts;
    if (_filters.isActive && _selectedCategoryId == featuredCategoryId) {
      return listedProducts;
    }
    if (_selectedCategoryId == featuredCategoryId) {
      final highlighted = featured;
      return highlighted.isEmpty ? listedProducts : highlighted;
    }
    return listedProducts
        .where((p) => p.categoryId == _selectedCategoryId)
        .toList();
  }

  double _effectiveMinPrice(Product product) {
    final promotions = _promotions;
    if (promotions == null || product.variants.isEmpty) {
      return product.minPriceSoles;
    }
    return product.variants
        .map((variant) => promotions.priceFor(product, variant).finalSoles)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Alérgenos declarados por el catálogo, para construir los filtros.
  List<String> get allergenOptions {
    final values = <String>{};
    for (final product in _menu.products) {
      for (final allergen in product.allergens) {
        final clean = allergen.trim();
        if (clean.isNotEmpty) values.add(clean);
      }
    }
    final list = values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  String get selectedCategoryName {
    if (_selectedCategoryId == allCategoryId) return 'TODOS';
    if (_selectedCategoryId == featuredCategoryId) {
      return 'LAS MÁS PEDIDAS';
    }
    return _menu.categoryById(_selectedCategoryId)?.name ?? 'CARTA';
  }

  int get visibleCount => visibleProducts.length;

  void selectCategory(String categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setQuery(String query) {
    if (_filters.query == query) return;
    _filters = _filters.copyWith(query: query);
    notifyListeners();
  }

  void toggleAllergen(String allergen) {
    final next = {..._filters.excludedAllergens};
    if (!next.remove(allergen)) next.add(allergen);
    _filters = _filters.copyWith(excludedAllergens: next);
    notifyListeners();
  }

  void setCalorieBand(CalorieBand band) {
    if (_filters.calorieBand == band) return;
    _filters = _filters.copyWith(calorieBand: band);
    notifyListeners();
  }

  void setPriceRange(double minPrice, double maxPrice) {
    _filters = _filters.copyWith(
      minPrice: Money.round(minPrice),
      maxPrice: Money.round(maxPrice),
    );
    notifyListeners();
  }

  void setPriceThreshold(double threshold, PriceComparison comparison) {
    _filters = _filters.copyWith(
      priceThreshold: Money.round(threshold),
      priceComparison: comparison,
    );
    notifyListeners();
  }

  void clearPriceThreshold() {
    if (!_filters.hasPriceThreshold) return;
    _filters = _filters.copyWith(clearPriceThreshold: true);
    notifyListeners();
  }

  void clearFilters() {
    if (!_filters.isActive) return;
    _filters = const CatalogFilters();
    notifyListeners();
  }

  static String _normalize(String value) {
    const withAccents = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const withoutAccents = 'aaaaaeeeeiiiiooooouuuunc';
    var result = value.toLowerCase();
    for (var i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(
        withAccents.substring(i, i + 1),
        withoutAccents.substring(i, i + 1),
      );
    }
    return result;
  }

  /// Carga puntual con reintento. También abre el stream en tiempo real.
  Future<void> load() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _menu = await _repository.fetchMenu();
      _state = LoadState.ready;
      _ensureSelection();
    } catch (error) {
      _state = LoadState.error;
      _error = error is RepositoryException
          ? error.message
          : 'No se pudo cargar la carta.';
    }
    notifyListeners();
  }

  /// Escucha cambios publicados por el negocio sin recompilar.
  void watch() {
    _subscription ??= _repository.watchMenu().listen(
      (menu) {
        _menu = menu;
        _state = LoadState.ready;
        _error = null;
        _ensureSelection();
        notifyListeners();
      },
      onError: (Object error) {
        if (_state != LoadState.ready) {
          _state = LoadState.error;
          _error = error is RepositoryException
              ? error.message
              : 'No se pudo actualizar la carta.';
          notifyListeners();
        }
      },
    );
  }

  Product? byId(String id) => _menu.byId(id);

  void _ensureSelection() {
    final exists =
        _selectedCategoryId == featuredCategoryId ||
        _selectedCategoryId == allCategoryId ||
        _menu.activeCategories.any((c) => c.id == _selectedCategoryId);
    if (!exists) _selectedCategoryId = featuredCategoryId;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
