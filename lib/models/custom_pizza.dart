import '../core/format/money.dart';
import 'ingredient.dart';
import 'model_utils.dart';
import 'pizza_config.dart';

/// Selección completa de una pizza personalizada.
///
/// Guarda snapshots para que un cambio de precios en Firestore no altere una
/// línea que ya está en el carrito.
class CustomPizzaSelection {
  const CustomPizzaSelection({
    required this.size,
    required this.dough,
    required this.sauce,
    required this.cheese,
    required this.ingredients,
    required this.baseCents,
    required this.doughCents,
    required this.sauceCents,
    required this.cheeseCents,
    required this.ingredientsCents,
    required this.totalCents,
    required this.preparationMinutes,
  });

  final PizzaSize size;
  final PizzaOption dough;
  final PizzaOption sauce;
  final PizzaOption cheese;
  final List<Ingredient> ingredients;
  final int baseCents;
  final int doughCents;
  final int sauceCents;
  final int cheeseCents;
  final int ingredientsCents;
  final int totalCents;

  /// Tiempo de un lote de esta pizza, sin recuperación entre lotes.
  final int preparationMinutes;

  double get unitPriceSoles => Money.fromCents(totalCents);
  double get basePriceSoles => Money.fromCents(baseCents);
  double get toppingsSoles => Money.fromCents(ingredientsCents);
  double get ovenWeight => size.ovenWeight;

  String get label => '${size.name} · ${dough.name}';

  String get signature =>
      '${size.id}|${dough.id}|${sauce.id}|${cheese.id}|'
      '${ingredients.map((i) => i.id).join(',')}';

  List<String> get detailLines => [
    'Masa: ${dough.name}',
    'Salsa: ${sauce.name}',
    'Queso: ${cheese.name}',
    if (ingredients.isNotEmpty)
      'Ingredientes: ${ingredients.map((i) => i.name).join(', ')}',
  ];

  /// Calcula una selección con la configuración y los ingredientes dados.
  factory CustomPizzaSelection.calculate({
    required PizzaConfig config,
    required PizzaSize size,
    required PizzaOption dough,
    required PizzaOption sauce,
    required PizzaOption cheese,
    required List<Ingredient> ingredients,
  }) {
    final baseCents = Money.toCents(size.basePriceSoles);
    final doughCents = Money.toCents(
      size.basePriceSoles * dough.adjustmentPercent / 100 +
          dough.adjustmentSoles,
    );
    final sauceCents = Money.toCents(
      sauce.adjustmentSoles * size.ingredientMultiplier,
    );
    final cheeseCents = Money.toCents(
      cheese.adjustmentSoles * size.ingredientMultiplier,
    );
    final ingredientCents = ingredients.fold<int>(
      0,
      (total, ingredient) =>
          total +
          Money.toCents(
            ingredient.priceSoles * size.ingredientMultiplier,
          ),
    );
    final total = (baseCents +
            doughCents +
            sauceCents +
            cheeseCents +
            ingredientCents)
        .clamp(0, 1 << 31)
        .toInt();
    final minutes =
        config.minutesBase +
        size.extraMinutes +
        dough.extraMinutes +
        ingredients.length * config.minutesPerIngredient;

    return CustomPizzaSelection(
      size: size,
      dough: dough,
      sauce: sauce,
      cheese: cheese,
      ingredients: List.unmodifiable(ingredients),
      baseCents: baseCents,
      doughCents: doughCents,
      sauceCents: sauceCents,
      cheeseCents: cheeseCents,
      ingredientsCents: ingredientCents,
      totalCents: total,
      preparationMinutes: minutes,
    );
  }

  factory CustomPizzaSelection.fromMap(Map<String, dynamic> json) {
    final size = PizzaSize.fromMap(
      ModelUtils.asMap(json['tamano'] ?? json['size']),
    );
    final dough = PizzaOption.fromMap(
      ModelUtils.asMap(json['masa'] ?? json['dough']),
    );
    final sauce = PizzaOption.fromMap(
      ModelUtils.asMap(json['salsa'] ?? json['sauce']),
    );
    final cheese = PizzaOption.fromMap(
      ModelUtils.asMap(json['queso'] ?? json['cheese']),
    );
    final ingredients = ModelUtils.asMapList(
      json['ingredientes'] ?? json['ingredients'],
    ).map(Ingredient.fromMap).toList();

    return CustomPizzaSelection(
      size: size,
      dough: dough,
      sauce: sauce,
      cheese: cheese,
      ingredients: List.unmodifiable(ingredients),
      baseCents: ModelUtils.asInt(
        json['baseCents'],
        fallback: Money.toCents(size.basePriceSoles),
      ),
      doughCents: ModelUtils.asInt(json['doughCents']),
      sauceCents: ModelUtils.asInt(json['sauceCents']),
      cheeseCents: ModelUtils.asInt(json['cheeseCents']),
      ingredientsCents: ModelUtils.asInt(json['ingredientsCents']),
      totalCents: ModelUtils.asInt(
        json['totalCents'],
        fallback: Money.toCents(
          ModelUtils.asMoney(json, 'precioUnitario', centsKey: 'unitPriceCents'),
        ),
      ),
      preparationMinutes: ModelUtils.asInt(
        json['preparationMinutes'] ?? json['minutosPreparacion'],
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'tamano': size.toMap(),
    'masa': dough.toMap(),
    'salsa': sauce.toMap(),
    'queso': cheese.toMap(),
    'ingredientes': ingredients.map((i) => i.toMap()).toList(),
    'baseCents': baseCents,
    'doughCents': doughCents,
    'sauceCents': sauceCents,
    'cheeseCents': cheeseCents,
    'ingredientsCents': ingredientsCents,
    'totalCents': totalCents,
    'preparationMinutes': preparationMinutes,
  };
}
