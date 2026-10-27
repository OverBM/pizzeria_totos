import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/load_state.dart';
import '../models/menu_data.dart';
import '../models/product.dart';
import '../repositories/catalog_repository.dart';
import '../repositories/repository_exception.dart';

/// Categorías y productos de la carta (Firestore como única fuente).
class CatalogController extends ChangeNotifier {
  CatalogController({required CatalogRepository repository})
    : _repository = repository;

  final CatalogRepository _repository;
  StreamSubscription<MenuData>? _subscription;

  LoadState _state = LoadState.idle;
  MenuData _menu = MenuData.empty;
  String? _error;
  static const String featuredCategoryId = 'mas-pedidas';

  String _selectedCategoryId = featuredCategoryId;

  LoadState get state => _state;
  MenuData get menu => _menu;
  String? get error => _error;
  String get selectedCategoryId => _selectedCategoryId;

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
    if (_selectedCategoryId == featuredCategoryId) {
      final highlighted = featured;
      return highlighted.isEmpty ? listedProducts : highlighted;
    }
    return listedProducts
        .where((p) => p.categoryId == _selectedCategoryId)
        .toList();
  }

  String get selectedCategoryName {
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
        _menu.activeCategories.any((c) => c.id == _selectedCategoryId);
    if (!exists) _selectedCategoryId = featuredCategoryId;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
