import '../models/ingredient.dart';
import '../models/pizza_config.dart';

/// Contrato de datos de pizza personalizada.
abstract interface class PizzaRepository {
  Future<List<Ingredient>> fetchIngredients();

  Stream<List<Ingredient>> watchIngredients();

  Future<PizzaConfig> fetchConfig();

  Stream<PizzaConfig> watchConfig();
}
