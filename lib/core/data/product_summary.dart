import '../../models/product.dart';

/// Resumen de presentación de un producto para la tarjeta y su `Semantics`.
///
/// La línea visible omite las bases que comparte la familia y usa la porción
/// como respaldo cuando el producto tiene menos de dos ingredientes. La lista
/// literal completa se conserva para el lector de pantalla y el detalle.
class ProductSummary {
  const ProductSummary({
    required this.visibleIngredients,
    required this.fullIngredients,
    this.caloriesLabel,
  });

  /// Línea que se pinta bajo la descripción (puede quedar vacía).
  final String visibleIngredients;

  /// Lista literal completa, incluidas las bases.
  final String fullIngredients;

  /// `«N kcal»`, o `null` si el producto no declara calorías válidas.
  final String? caloriesLabel;

  /// Bases que no diferencian un producto de otro dentro de su familia.
  static const Set<String> _bases = {
    'masa madre',
    'masa dulce',
    'salsa de tomate',
    'salsa de la casa',
  };

  factory ProductSummary.of(Product product) {
    final full = product.ingredients.join(' · ');
    final distinct = product.ingredients
        .where((ingredient) => !_isBase(ingredient))
        .toList();

    // Documento atípico con solo bases: se muestra la lista literal.
    final visible = distinct.isEmpty ? product.ingredients : distinct;
    var line = visible.join(' · ');

    if (visible.length < 2) {
      final portion = product.portion?.trim();
      if (portion != null && portion.isNotEmpty) {
        line = line.isEmpty ? portion : '$line · $portion';
      }
    }

    final calories = product.calories;
    return ProductSummary(
      visibleIngredients: line,
      fullIngredients: full,
      caloriesLabel: calories != null && calories > 0
          ? '$calories kcal'
          : null,
    );
  }

  /// Etiqueta completa para el lector de pantalla.
  String semanticsLabel({required String name, required String familyLabel}) {
    final buffer = StringBuffer(name);
    if (fullIngredients.isNotEmpty) buffer.write('. $fullIngredients');
    buffer.write('. $familyLabel');
    return buffer.toString();
  }

  static bool _isBase(String value) =>
      _bases.contains(value.trim().toLowerCase());
}
