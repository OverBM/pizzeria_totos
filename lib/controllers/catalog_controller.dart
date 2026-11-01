import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/format/money.dart';
import '../core/load_state.dart';
import '../models/catalog_filters.dart';
import '../models/masa.dart';
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

  String _selectedCategoryId = allCategoryId;
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
  List<Product> get featured =>
      _menu.products.where((p) => p.featured && p.available).toList();

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
    return listedProducts.where((p) => !seen.contains(p.id)).take(6).toList();
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
      final haystack = _normalize(
        [
          product.name,
          product.description,
          ...product.ingredients,
          ...product.tags,
        ].join(' '),
      );
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

    final selectedMasa = _filters.masa;
    if (selectedMasa != null && !product.masas.contains(selectedMasa)) {
      return false;
    }
    if (_filters.formato != null && !_hasTag(product, _filters.formato!)) {
      return false;
    }
    if (_filters.tipo != null && !_hasTag(product, _filters.tipo!)) {
      return false;
    }

    final effectivePrice = price ?? _displayedPrice(product);
    final minPrice = _filters.minPrice;
    final maxPrice = _filters.maxPrice;
    if (minPrice != null && effectivePrice < minPrice) return false;
    if (maxPrice != null && effectivePrice > maxPrice) return false;
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

  /// Precio que se muestra en la tarjeta: la variante por defecto con la
  /// promoción vigente. El filtro usa este mismo precio.
  double _displayedPrice(Product product) {
    final variant = product.defaultVariantOrNull;
    if (variant == null) return product.minPriceSoles;
    final promotions = _promotions;
    if (promotions == null) return variant.priceSoles;
    return promotions.priceFor(product, variant).finalSoles;
  }

  /// Límites del rango de precio a partir de los productos visibles.
  ({double min, double max}) get priceBounds {
    final prices = listedProducts
        .map(_displayedPrice)
        .where((price) => price > 0)
        .toList();
    if (prices.isEmpty) return (min: 0, max: 100);
    var maximum = 0.0;
    for (final price in prices) {
      if (price > maximum) maximum = price;
    }
    final rounded = (maximum / 10).ceil() * 10;
    return (min: 0, max: rounded < 20 ? 20 : rounded.toDouble());
  }

  bool _hasTag(Product product, String label) {
    final target = _normalize(label);
    return product.tags.any((tag) => _normalize(tag) == target);
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

  /// Masas realmente disponibles en el catálogo.
  List<MasaType> get masaOptions {
    final values = <MasaType>{};
    for (final product in _menu.products) {
      values.addAll(product.masas);
    }
    final list = values.toList()..sort((a, b) => a.index.compareTo(b.index));
    return list;
  }

  /// Formatos derivados de las etiquetas reales.
  List<String> get formatoOptions {
    const known = ['Individual', 'Para compartir', 'Familiar'];
    return known
        .where((label) => _menu.products.any((p) => _hasTag(p, label)))
        .toList();
  }

  /// Tipos derivados de las etiquetas reales.
  List<String> get tipoOptions {
    const known = [
      'Clásica',
      'Vegetariana',
      'Picante',
      'Dulce',
      'Casa',
      'Crujiente',
      'Fresca',
      'Helada',
      'Postre',
      'Con alcohol',
    ];
    return known
        .where((label) => _menu.products.any((p) => _hasTag(p, label)))
        .toList();
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

  void setPriceRange(double? minPrice, double? maxPrice) {
    final min = (minPrice == null || minPrice <= 0)
        ? null
        : Money.round(minPrice);
    final max = (maxPrice == null || maxPrice <= 0)
        ? null
        : Money.round(maxPrice);
    _filters = _filters.copyWith(
      minPrice: min,
      maxPrice: max,
      clearMinPrice: min == null,
      clearMaxPrice: max == null,
    );
    notifyListeners();
  }

  void clearPriceRange() {
    if (!_filters.hasPriceFilter) return;
    _filters = _filters.copyWith(clearMinPrice: true, clearMaxPrice: true);
    notifyListeners();
  }

  void setMasa(MasaType? masa) {
    _filters = _filters.copyWith(masa: masa, clearMasa: masa == null);
    notifyListeners();
  }

  void setFormato(String? formato) {
    _filters = _filters.copyWith(
      formato: formato,
      clearFormato: formato == null,
    );
    notifyListeners();
  }

  void setTipo(String? tipo) {
    _filters = _filters.copyWith(tipo: tipo, clearTipo: tipo == null);
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
    if (!exists) _selectedCategoryId = allCategoryId;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
