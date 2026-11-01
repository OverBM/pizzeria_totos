import 'masa.dart';

/// Bandas de calorías para la carta.
enum CalorieBand {
  all,
  upTo500,
  from500To900,
  over900;

  String get label => switch (this) {
    CalorieBand.all => 'Todas',
    CalorieBand.upTo500 => 'Hasta 500 kcal',
    CalorieBand.from500To900 => '500–900 kcal',
    CalorieBand.over900 => 'Más de 900 kcal',
  };

  bool matches(int? calories) {
    if (this == CalorieBand.all) return true;
    if (calories == null) return false;
    return switch (this) {
      CalorieBand.upTo500 => calories <= 500,
      CalorieBand.from500To900 => calories > 500 && calories <= 900,
      CalorieBand.over900 => calories > 900,
      CalorieBand.all => true,
    };
  }
}

/// Estado inmutable de búsqueda y filtros de la carta.
class CatalogFilters {
  const CatalogFilters({
    this.query = '',
    this.excludedAllergens = const {},
    this.calorieBand = CalorieBand.all,
    this.minPrice,
    this.maxPrice,
    this.masa,
    this.formato,
    this.tipo,
  });

  final String query;

  /// Alérgenos que el usuario quiere excluir.
  final Set<String> excludedAllergens;
  final CalorieBand calorieBand;

  /// Rango de precio. `null` significa sin límite.
  final double? minPrice;
  final double? maxPrice;

  final MasaType? masa;
  final String? formato;
  final String? tipo;

  bool get hasPriceFilter => minPrice != null || maxPrice != null;

  bool get isActive =>
      query.trim().isNotEmpty ||
      excludedAllergens.isNotEmpty ||
      calorieBand != CalorieBand.all ||
      hasPriceFilter ||
      masa != null ||
      formato != null ||
      tipo != null;

  CatalogFilters copyWith({
    String? query,
    Set<String>? excludedAllergens,
    CalorieBand? calorieBand,
    double? minPrice,
    double? maxPrice,
    MasaType? masa,
    String? formato,
    String? tipo,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMasa = false,
    bool clearFormato = false,
    bool clearTipo = false,
  }) => CatalogFilters(
    query: query ?? this.query,
    excludedAllergens: excludedAllergens ?? this.excludedAllergens,
    calorieBand: calorieBand ?? this.calorieBand,
    minPrice: clearMinPrice ? null : minPrice ?? this.minPrice,
    maxPrice: clearMaxPrice ? null : maxPrice ?? this.maxPrice,
    masa: clearMasa ? null : masa ?? this.masa,
    formato: clearFormato ? null : formato ?? this.formato,
    tipo: clearTipo ? null : tipo ?? this.tipo,
  );
}
