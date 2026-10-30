import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/core/data/product_summary.dart';
import 'package:pizzeria_totos/models/product.dart';
import 'package:pizzeria_totos/models/variant.dart';

Product _product({
  List<String> ingredients = const [],
  String? portion,
  int? calories,
  String name = 'PIZZA',
}) {
  return Product(
    id: 'p',
    categoryId: 'pizzas',
    name: name,
    description: 'd',
    ingredients: ingredients,
    portion: portion,
    calories: calories,
    variants: const [Variant(label: 'única', priceSoles: 10)],
  );
}

void main() {
  group('ProductSummary', () {
    test('omite las bases y conserva la lista literal completa', () {
      final summary = ProductSummary.of(
        _product(
          ingredients: const [
            'Masa madre',
            'Salsa de la casa',
            'Mozzarella',
            'Pepperoni',
            'Orégano',
          ],
          calories: 1120,
        ),
      );

      expect(summary.visibleIngredients, 'Mozzarella · Pepperoni · Orégano');
      expect(
        summary.fullIngredients,
        'Masa madre · Salsa de la casa · Mozzarella · Pepperoni · Orégano',
      );
      expect(summary.caloriesLabel, '1120 kcal');
    });

    test('compara las bases sin distinguir mayúsculas ni espacios', () {
      final summary = ProductSummary.of(
        _product(
          ingredients: const ['  masa MADRE ', 'Salsa de Tomate', 'Queso'],
        ),
      );

      expect(summary.visibleIngredients, 'Queso');
    });

    test('añade la porción cuando queda menos de dos ingredientes', () {
      final summary = ProductSummary.of(
        _product(
          ingredients: const ['Gaseosa Inca Kola'],
          portion: '600 ml',
        ),
      );

      expect(summary.visibleIngredients, 'Gaseosa Inca Kola · 600 ml');
    });

    test('con solo bases muestra la lista literal', () {
      final summary = ProductSummary.of(
        _product(ingredients: const ['Masa madre', 'Salsa de tomate']),
      );

      expect(summary.visibleIngredients, 'Masa madre · Salsa de tomate');
    });

    test('sin ingredientes ni porción la línea queda vacía', () {
      final summary = ProductSummary.of(_product());

      expect(summary.visibleIngredients, isEmpty);
      expect(summary.caloriesLabel, isNull);
    });

    test('calorias nulas o no positivas no generan etiqueta', () {
      expect(ProductSummary.of(_product(calories: 0)).caloriesLabel, isNull);
      expect(ProductSummary.of(_product()).caloriesLabel, isNull);
    });

    test('la etiqueta accesible incluye nombre, lista completa y familia', () {
      final summary = ProductSummary.of(
        _product(
          ingredients: const ['Masa madre', 'Mozzarella', 'Pepperoni'],
          calories: 1050,
          name: 'PIZZA PEPERONI',
        ),
      );

      final label = summary.semanticsLabel(
        name: 'PIZZA PEPERONI',
        familyLabel: 'Pizza',
      );
      expect(label, contains('PIZZA PEPERONI'));
      expect(label, contains('Masa madre · Mozzarella · Pepperoni'));
      expect(label, contains('Pizza'));
      expect(label, isNot(contains('kcal')));
      expect(summary.caloriesLabel, '1050 kcal');
    });
  });
}
