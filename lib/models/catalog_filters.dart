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

/// Comparación opcional contra un precio específico.
enum PriceComparison {
  none,
  below,
  above;

  String get label => switch (this) {
    PriceComparison.none => 'Sin comparación',
    PriceComparison.below => 'Menor a',
    PriceComparison.above => 'Mayor a',
  };
}

/// Estado inmutable de búsqueda y filtros de la carta.
class CatalogFilters {
  const CatalogFilters({
    this.query = '',
    this.excludedAllergens = const {},
    this.calorieBand = CalorieBand.all,
    this.minPrice = 0,
    this.maxPrice = 100,
    this.priceThreshold,
    this.priceComparison = PriceComparison.none,
  });

  final String query;

  /// Alérgenos que el usuario quiere excluir.
  final Set<String> excludedAllergens;
  final CalorieBand calorieBand;
  final double minPrice;
  final double maxPrice;

  /// Precio exacto introducido por el usuario para comparar.
  final double? priceThreshold;
  final PriceComparison priceComparison;

  bool get hasPriceFilter => minPrice > 0 || maxPrice < 100;
  bool get hasPriceThreshold =>
      priceThreshold != null && priceComparison != PriceComparison.none;
  bool get isActive =>
      query.trim().isNotEmpty ||
      excludedAllergens.isNotEmpty ||
      calorieBand != CalorieBand.all ||
      hasPriceFilter ||
      hasPriceThreshold;

  CatalogFilters copyWith({
    String? query,
    Set<String>? excludedAllergens,
    CalorieBand? calorieBand,
    double? minPrice,
    double? maxPrice,
    double? priceThreshold,
    PriceComparison? priceComparison,
    bool clearPriceThreshold = false,
  }) => CatalogFilters(
    query: query ?? this.query,
    excludedAllergens: excludedAllergens ?? this.excludedAllergens,
    calorieBand: calorieBand ?? this.calorieBand,
    minPrice: minPrice ?? this.minPrice,
    maxPrice: maxPrice ?? this.maxPrice,
    priceThreshold: clearPriceThreshold
        ? null
        : priceThreshold ?? this.priceThreshold,
    priceComparison: clearPriceThreshold
        ? PriceComparison.none
        : priceComparison ?? this.priceComparison,
  );
}
