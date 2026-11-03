import 'model_utils.dart';

/// Tamaño de pizza personalizada.
class PizzaSize {
  const PizzaSize({
    required this.id,
    required this.name,
    required this.diameterCm,
    required this.slices,
    required this.basePriceSoles,
    required this.maxIngredients,
    required this.ingredientMultiplier,
    this.extraMinutes = 0,
    this.ovenWeight = 1,
  });

  final String id;
  final String name;
  final int diameterCm;
  final int slices;
  final double basePriceSoles;
  final int maxIngredients;
  final double ingredientMultiplier;
  final int extraMinutes;
  final double ovenWeight;

  factory PizzaSize.fromMap(Map<String, dynamic> json) => PizzaSize(
    id: ModelUtils.asString(json['id']),
    name: ModelUtils.asString(json['nombre'] ?? json['name']),
    diameterCm: ModelUtils.asInt(json['diametroCm'] ?? json['diameterCm']),
    slices: ModelUtils.asInt(json['porciones'] ?? json['slices']),
    basePriceSoles: ModelUtils.asMoney(
      json,
      'precioBase',
      centsKey: 'basePriceCents',
    ),
    maxIngredients: ModelUtils.asInt(json['maxIngredientes'] ?? json['maxIngredients']),
    ingredientMultiplier: ModelUtils.asDouble(
      json['multiplicadorIngredientes'] ?? json['ingredientMultiplier'],
      fallback: 1,
    ),
    extraMinutes: ModelUtils.asInt(json['minutosExtra'] ?? json['extraMinutes']),
    ovenWeight: ModelUtils.asDouble(json['pesoHorno'] ?? json['ovenWeight'], fallback: 1),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': name,
    'diametroCm': diameterCm,
    'porciones': slices,
    'precioBase': basePriceSoles,
    'maxIngredientes': maxIngredients,
    'multiplicadorIngredientes': ingredientMultiplier,
    'minutosExtra': extraMinutes,
    'pesoHorno': ovenWeight,
  };
}

/// Opción de masa, salsa o queso.
class PizzaOption {
  const PizzaOption({
    required this.id,
    required this.name,
    this.description = '',
    this.adjustmentSoles = 0,
    this.adjustmentPercent = 0,
    this.extraMinutes = 0,
  });

  final String id;
  final String name;
  final String description;
  final double adjustmentSoles;
  final double adjustmentPercent;
  final int extraMinutes;

  factory PizzaOption.fromMap(Map<String, dynamic> json) => PizzaOption(
    id: ModelUtils.asString(json['id']),
    name: ModelUtils.asString(json['nombre'] ?? json['name']),
    description: ModelUtils.asString(json['descripcion'] ?? json['description']),
    adjustmentSoles: ModelUtils.asMoney(
      json,
      'ajuste',
      centsKey: 'adjustmentCents',
    ),
    adjustmentPercent: ModelUtils.asDouble(
      json['ajustePorcentaje'] ?? json['adjustmentPercent'],
    ),
    extraMinutes: ModelUtils.asInt(json['minutosExtra'] ?? json['extraMinutes']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': name,
    'descripcion': description,
    'ajuste': adjustmentSoles,
    'ajustePorcentaje': adjustmentPercent,
    'minutosExtra': extraMinutes,
  };
}

/// Configuración completa de la pizza personalizada.
class PizzaConfig {
  const PizzaConfig({
    required this.active,
    required this.minutesBase,
    required this.minutesPerIngredient,
    required this.defaultOvenCapacity,
    required this.defaultRecoveryMinutes,
    required this.unmeasuredMarginMinutes,
    required this.maxIngredientsGlobal,
    required this.sizes,
    required this.doughs,
    required this.sauces,
    required this.cheeses,
  });

  static const PizzaConfig fallback = PizzaConfig(
    active: false,
    minutesBase: 15,
    minutesPerIngredient: 1,
    defaultOvenCapacity: 4,
    defaultRecoveryMinutes: 0,
    unmeasuredMarginMinutes: 5,
    maxIngredientsGlobal: 7,
    sizes: [],
    doughs: [],
    sauces: [],
    cheeses: [],
  );

  final bool active;
  final int minutesBase;
  final int minutesPerIngredient;
  final int defaultOvenCapacity;
  final int defaultRecoveryMinutes;
  final int unmeasuredMarginMinutes;
  final int maxIngredientsGlobal;
  final List<PizzaSize> sizes;
  final List<PizzaOption> doughs;
  final List<PizzaOption> sauces;
  final List<PizzaOption> cheeses;

  bool get isReady => active && sizes.isNotEmpty && doughs.isNotEmpty;

  PizzaSize? sizeById(String id) {
    for (final size in sizes) {
      if (size.id == id) return size;
    }
    return null;
  }

  PizzaOption? doughById(String id) {
    for (final option in doughs) {
      if (option.id == id) return option;
    }
    return null;
  }

  PizzaOption? sauceById(String id) {
    for (final option in sauces) {
      if (option.id == id) return option;
    }
    return null;
  }

  PizzaOption? cheeseById(String id) {
    for (final option in cheeses) {
      if (option.id == id) return option;
    }
    return null;
  }

  factory PizzaConfig.fromMap(Map<String, dynamic> json) {
    final config = ModelUtils.asMap(json['config'] ?? json);
    return PizzaConfig(
      active: ModelUtils.asBool(config['activa'] ?? config['active'], fallback: true),
      minutesBase: ModelUtils.asInt(
        config['minutosBase'] ?? config['minutesBase'],
        fallback: 15,
      ),
      minutesPerIngredient: ModelUtils.asInt(
        config['minutosPorIngrediente'] ?? config['minutesPerIngredient'],
        fallback: 1,
      ),
      defaultOvenCapacity: ModelUtils.asInt(
        config['capacidadHornoDefecto'] ?? config['defaultOvenCapacity'],
        fallback: 4,
      ),
      defaultRecoveryMinutes: ModelUtils.asInt(
        config['recuperacionMinDefecto'] ?? config['defaultRecoveryMinutes'],
      ),
      unmeasuredMarginMinutes: ModelUtils.asInt(
        config['margenSinMedicionMin'] ?? config['unmeasuredMarginMinutes'],
        fallback: 5,
      ),
      maxIngredientsGlobal: ModelUtils.asInt(
        config['maxIngredientesGlobal'] ?? config['maxIngredientsGlobal'],
        fallback: 7,
      ),
      sizes: ModelUtils.asMapList(json['tamanos'] ?? json['sizes'])
          .map(PizzaSize.fromMap)
          .where((size) => size.id.isNotEmpty)
          .toList(),
      doughs: ModelUtils.asMapList(json['masas'] ?? json['doughs'])
          .map(PizzaOption.fromMap)
          .where((option) => option.id.isNotEmpty)
          .toList(),
      sauces: ModelUtils.asMapList(json['salsas'] ?? json['sauces'])
          .map(PizzaOption.fromMap)
          .where((option) => option.id.isNotEmpty)
          .toList(),
      cheeses: ModelUtils.asMapList(json['quesos'] ?? json['cheeses'])
          .map(PizzaOption.fromMap)
          .where((option) => option.id.isNotEmpty)
          .toList(),
    );
  }
}
