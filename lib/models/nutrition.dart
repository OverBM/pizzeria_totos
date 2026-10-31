import 'model_utils.dart';

/// Información nutricional declarada para una porción de producto.
///
/// En Firestore vive en `productos/{id}.nutricion` y mantiene compatibilidad
/// con los campos planos `calorias` y `porcion` del esquema anterior.
class NutritionInfo {
  const NutritionInfo({
    required this.portion,
    required this.portionGrams,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.saturatedFatG,
    required this.sugarsG,
    required this.fiberG,
    required this.sodiumMg,
    this.glutenFree = false,
    this.alcoholG = 0,
  });

  /// Etiqueta legible de la porción, por ejemplo `1 pizza entera (550 g)`.
  final String portion;
  final int portionGrams;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double saturatedFatG;
  final double sugarsG;
  final double fiberG;
  final int sodiumMg;

  /// Bandera explícita: no se infiere por la ausencia de alérgenos.
  final bool glutenFree;
  final double alcoholG;

  factory NutritionInfo.fromMap(Map<String, dynamic> json) => NutritionInfo(
    portion: ModelUtils.asString(json['porcion'] ?? json['portion']),
    portionGrams: ModelUtils.asInt(
      json['porcionGramos'] ?? json['portionGrams'],
    ),
    calories: ModelUtils.asInt(json['calorias'] ?? json['calories']),
    proteinG: ModelUtils.asDouble(json['proteinasG'] ?? json['proteinG']),
    carbsG: ModelUtils.asDouble(
      json['carbohidratosG'] ?? json['carbsG'],
    ),
    fatG: ModelUtils.asDouble(json['grasasG'] ?? json['fatG']),
    saturatedFatG: ModelUtils.asDouble(
      json['grasasSaturadasG'] ?? json['saturatedFatG'],
    ),
    sugarsG: ModelUtils.asDouble(json['azucaresG'] ?? json['sugarsG']),
    fiberG: ModelUtils.asDouble(json['fibraG'] ?? json['fiberG']),
    sodiumMg: ModelUtils.asInt(json['sodioMg'] ?? json['sodiumMg']),
    glutenFree: ModelUtils.asBool(
      json['sinGluten'] ?? json['glutenFree'],
    ),
    alcoholG: ModelUtils.asDouble(json['alcoholG']),
  );

  Map<String, dynamic> toMap() => {
    'porcion': portion,
    'porcionGramos': portionGrams,
    'calorias': calories,
    'proteinasG': proteinG,
    'carbohidratosG': carbsG,
    'grasasG': fatG,
    'grasasSaturadasG': saturatedFatG,
    'azucaresG': sugarsG,
    'fibraG': fiberG,
    'sodioMg': sodiumMg,
    'sinGluten': glutenFree,
    if (alcoholG > 0) 'alcoholG': alcoholG,
  };
}
