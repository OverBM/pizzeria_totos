import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/load_state.dart';
import '../models/custom_pizza.dart';
import '../models/ingredient.dart';
import '../models/pizza_config.dart';
import '../repositories/pizza_repository.dart';
import '../repositories/repository_exception.dart';

/// Estado del creador de pizza personalizada.
class CustomPizzaController extends ChangeNotifier {
  CustomPizzaController({required PizzaRepository repository})
    : _repository = repository;

  final PizzaRepository _repository;
  StreamSubscription<PizzaConfig>? _configSubscription;
  StreamSubscription<List<Ingredient>>? _ingredientsSubscription;

  PizzaConfig _config = PizzaConfig.fallback;
  List<Ingredient> _ingredients = const [];
  LoadState _state = LoadState.idle;
  String? _error;
  int _quantity = 1;

  PizzaSize? _size;
  PizzaOption? _dough;
  PizzaOption? _sauce;
  PizzaOption? _cheese;
  final Set<String> _selectedIngredientIds = {};

  PizzaConfig get config => _config;
  List<Ingredient> get ingredients => _ingredients;
  LoadState get state => _state;
  String? get error => _error;
  int get quantity => _quantity;
  PizzaSize? get size => _size;
  PizzaOption? get dough => _dough;
  PizzaOption? get sauce => _sauce;
  PizzaOption? get cheese => _cheese;
  Set<String> get selectedIngredientIds => _selectedIngredientIds;

  List<Ingredient> get selectedIngredients => _ingredients
      .where((i) => _selectedIngredientIds.contains(i.id))
      .toList();

  bool get isReady => _config.isReady && _ingredients.any((i) => i.available);

  int get maxIngredients {
    final bySize = _size?.maxIngredients ?? _config.maxIngredientsGlobal;
    return bySize.clamp(0, _config.maxIngredientsGlobal).toInt();
  }

  bool get canAddIngredient =>
      _selectedIngredientIds.length < maxIngredients;

  double get unitPriceSoles => selection?.unitPriceSoles ?? 0;
  int get preparationMinutes => selection?.preparationMinutes ?? 0;

  CustomPizzaSelection? get selection {
    final size = _size;
    final dough = _dough;
    final sauce = _sauce;
    final cheese = _cheese;
    if (size == null || dough == null || sauce == null || cheese == null) {
      return null;
    }
    return CustomPizzaSelection.calculate(
      config: _config,
      size: size,
      dough: dough,
      sauce: sauce,
      cheese: cheese,
      ingredients: selectedIngredients,
    );
  }

  Future<void> load() async {
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.fetchConfig(),
        _repository.fetchIngredients(),
      ]);
      _apply(results[0] as PizzaConfig, results[1] as List<Ingredient>);
      _state = LoadState.ready;
    } catch (error) {
      _state = LoadState.error;
      _error = error is RepositoryException
          ? error.message
          : 'No se pudo cargar la pizza personalizada.';
    }
    notifyListeners();
  }

  void watch() {
    _configSubscription ??= _repository.watchConfig().listen(
      (config) {
        _config = config;
        _ensureDefaults();
        _state = LoadState.ready;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        if (_state != LoadState.ready) {
          _state = LoadState.error;
          _error = error is RepositoryException
              ? error.message
              : 'No se pudo actualizar la configuración.';
          notifyListeners();
        }
      },
    );
    _ingredientsSubscription ??= _repository.watchIngredients().listen(
      (ingredients) {
        _ingredients = ingredients;
        _selectedIngredientIds.removeWhere(
          (id) => !ingredients.any((i) => i.id == id && i.available),
        );
        notifyListeners();
      },
    );
  }

  void _apply(PizzaConfig config, List<Ingredient> ingredients) {
    _config = config;
    _ingredients = ingredients;
    _ensureDefaults();
  }

  void _ensureDefaults() {
    final sizes = _config.sizes;
    if (_size == null || !sizes.any((s) => s.id == _size!.id)) {
      _size = sizes.isEmpty ? null : sizes.first;
    }
    _dough = _optionOrFirst(_dough, _config.doughs);
    _sauce = _optionOrFirst(_sauce, _config.sauces);
    _cheese = _optionOrFirst(_cheese, _config.cheeses);
    if (_selectedIngredientIds.length > maxIngredients) {
      _selectedIngredientIds
        ..clear()
        ..addAll(
          _ingredients
              .where((i) => i.available)
              .take(maxIngredients)
              .map((i) => i.id),
        );
    }
  }

  PizzaOption? _optionOrFirst(PizzaOption? current, List<PizzaOption> options) {
    if (current != null && options.any((o) => o.id == current.id)) {
      return current;
    }
    return options.isEmpty ? null : options.first;
  }

  void selectSize(PizzaSize size) {
    _size = size;
    if (_selectedIngredientIds.length > maxIngredients) {
      final keep = _selectedIngredientIds.take(maxIngredients).toSet();
      _selectedIngredientIds
        ..clear()
        ..addAll(keep);
    }
    notifyListeners();
  }

  void selectDough(PizzaOption option) {
    _dough = option;
    notifyListeners();
  }

  void selectSauce(PizzaOption option) {
    _sauce = option;
    notifyListeners();
  }

  void selectCheese(PizzaOption option) {
    _cheese = option;
    notifyListeners();
  }

  void toggleIngredient(Ingredient ingredient) {
    if (!ingredient.available) return;
    if (_selectedIngredientIds.contains(ingredient.id)) {
      _selectedIngredientIds.remove(ingredient.id);
    } else if (canAddIngredient) {
      _selectedIngredientIds.add(ingredient.id);
    }
    notifyListeners();
  }

  void setQuantity(int value) {
    _quantity = value.clamp(1, 99);
    notifyListeners();
  }

  void hydrate(CustomPizzaSelection selection, {int quantity = 1}) {
    _size = selection.size;
    _dough = selection.dough;
    _sauce = selection.sauce;
    _cheese = selection.cheese;
    _selectedIngredientIds
      ..clear()
      ..addAll(selection.ingredients.map((ingredient) => ingredient.id));
    _quantity = quantity;
    notifyListeners();
  }

  void reset() {
    _quantity = 1;
    _selectedIngredientIds.clear();
    _size = _config.sizes.isEmpty ? null : _config.sizes.first;
    _dough = _config.doughs.isEmpty ? null : _config.doughs.first;
    _sauce = _config.sauces.isEmpty ? null : _config.sauces.first;
    _cheese = _config.cheeses.isEmpty ? null : _config.cheeses.first;
    notifyListeners();
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    _ingredientsSubscription?.cancel();
    super.dispose();
  }
}
