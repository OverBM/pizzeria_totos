import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/catalog_controller.dart';
import '../../core/format/money.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../models/catalog_filters.dart';
import '../../widgets/widgets.dart';

/// Buscador y filtros compartidos por Carta y Promos.
class CatalogFilterControls extends StatefulWidget {
  const CatalogFilterControls({
    super.key,
    this.horizontalPadding = Brand.s16,
    this.topPadding = Brand.s16,
  });

  final double horizontalPadding;
  final double topPadding;

  @override
  State<CatalogFilterControls> createState() => _CatalogFilterControlsState();
}

class _CatalogFilterControlsState extends State<CatalogFilterControls> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _search.text = context.read<CatalogController>().searchQuery;
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _syncQuery(String query) {
    if (_focus.hasFocus || _search.text == query) return;
    _search.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    _syncQuery(catalog.searchQuery);
    final active = [
      if (catalog.filters.excludedAllergens.isNotEmpty)
        catalog.filters.excludedAllergens.length,
      if (catalog.filters.calorieBand != CalorieBand.all) 1,
      if (catalog.filters.hasPriceFilter) 1,
      if (catalog.filters.hasPriceThreshold) 1,
    ].fold<int>(0, (sum, value) => sum + value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            widget.horizontalPadding,
            widget.topPadding,
            widget.horizontalPadding,
            0,
          ),
          child: Row(
            children: [
              Badge.count(
                count: active,
                isLabelVisible: active > 0,
                backgroundColor: context.colors.action,
                child: IconButton(
                  onPressed: () => _openFilters(context),
                  tooltip: 'Filtros de la carta',
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
              const SizedBox(width: Brand.s4),
              Expanded(
                child: TextField(
                  controller: _search,
                  focusNode: _focus,
                  textInputAction: TextInputAction.search,
                  onChanged: catalog.setQuery,
                  decoration: InputDecoration(
                    hintText: 'Buscar en toda la carta',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: catalog.searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _search.clear();
                              catalog.setQuery('');
                            },
                            tooltip: 'Limpiar búsqueda',
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (catalog.hasActiveFilters) _activeFilters(context, catalog),
      ],
    );
  }

  Widget _activeFilters(BuildContext context, CatalogController catalog) {
    final chips = <Widget>[];
    for (final allergen in catalog.filters.excludedAllergens) {
      chips.add(
        FilterPill(
          label: 'Sin $allergen',
          selected: true,
          onTap: () => catalog.toggleAllergen(allergen),
        ),
      );
    }
    if (catalog.filters.calorieBand != CalorieBand.all) {
      chips.add(
        FilterPill(
          label: catalog.filters.calorieBand.label,
          selected: true,
          onTap: () => catalog.setCalorieBand(CalorieBand.all),
        ),
      );
    }
    if (catalog.filters.hasPriceFilter) {
      chips.add(
        FilterPill(
          label:
              '${Money.format(catalog.filters.minPrice)} – '
              '${Money.format(catalog.filters.maxPrice)}',
          selected: true,
          onTap: () => catalog.setPriceRange(0, 100),
        ),
      );
    }
    if (catalog.filters.hasPriceThreshold) {
      chips.add(
        FilterPill(
          label:
              '${catalog.filters.priceComparison.label} '
              '${Money.format(catalog.filters.priceThreshold!)}',
          selected: true,
          onTap: catalog.clearPriceThreshold,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        widget.horizontalPadding,
        Brand.s8,
        widget.horizontalPadding,
        0,
      ),
      child: Wrap(
        spacing: Brand.s8,
        runSpacing: Brand.s8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...chips,
          TextButton(
            onPressed: catalog.clearFilters,
            child: const Text('LIMPIAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilters(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) => const _FiltersSheet(),
    );
  }
}

/// Hoja de filtros compartida por Carta y Promos.
class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet();

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late RangeValues _range;
  late final TextEditingController _specificPrice;
  PriceComparison _comparison = PriceComparison.none;

  @override
  void initState() {
    super.initState();
    final filters = context.read<CatalogController>().filters;
    _range = RangeValues(filters.minPrice, filters.maxPrice);
    _comparison = filters.priceComparison;
    _specificPrice = TextEditingController(
      text: filters.priceThreshold == null
          ? ''
          : filters.priceThreshold!.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _specificPrice.dispose();
    super.dispose();
  }

  void _applyThreshold() {
    final catalog = context.read<CatalogController>();
    final raw = _specificPrice.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value <= 0) {
      catalog.clearPriceThreshold();
      return;
    }
    catalog.setPriceThreshold(
      value,
      _comparison == PriceComparison.none
          ? PriceComparison.below
          : _comparison,
    );
    if (_comparison == PriceComparison.none) {
      setState(() => _comparison = PriceComparison.below);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final colors = context.colors;
    final allergens = catalog.allergenOptions;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Brand.s16,
            Brand.s16,
            Brand.s16,
            Brand.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'FILTROS',
                    style: Brand.display(22, h: 1, color: colors.textPrimary),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      catalog.clearFilters();
                      _specificPrice.clear();
                      setState(() {
                        _range = const RangeValues(0, 100);
                        _comparison = PriceComparison.none;
                      });
                    },
                    child: const Text('LIMPIAR TODO'),
                  ),
                ],
              ),
              const SizedBox(height: Brand.s16),
              if (allergens.isNotEmpty) ...[
                Text(
                  'SIN ALÉRGENOS',
                  style: Brand.ui(
                    10,
                    weight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: Brand.s8),
                Wrap(
                  spacing: Brand.s8,
                  runSpacing: Brand.s8,
                  children: [
                    for (final allergen in allergens)
                      FilterPill(
                        label: 'Sin $allergen',
                        selected: catalog.filters.excludedAllergens.contains(
                          allergen,
                        ),
                        onTap: () => catalog.toggleAllergen(allergen),
                      ),
                  ],
                ),
                const SizedBox(height: Brand.s16),
              ],
              Text(
                'CALORÍAS',
                style: Brand.ui(
                  10,
                  weight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: Brand.s8),
              Wrap(
                spacing: Brand.s8,
                runSpacing: Brand.s8,
                children: [
                  for (final band in CalorieBand.values)
                    FilterPill(
                      label: band.label,
                      selected: catalog.filters.calorieBand == band,
                      onTap: () => catalog.setCalorieBand(band),
                    ),
                ],
              ),
              const SizedBox(height: Brand.s16),
              Text(
                'PRECIO',
                style: Brand.ui(
                  10,
                  weight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              RangeSlider(
                values: _range,
                min: 0,
                max: 100,
                divisions: 100,
                labels: RangeLabels(
                  Money.format(_range.start),
                  Money.format(_range.end),
                ),
                onChanged: (values) => setState(() => _range = values),
                onChangeEnd: (values) =>
                    catalog.setPriceRange(values.start, values.end),
              ),
              Row(
                children: [
                  Text(Money.format(_range.start), style: context.text.caption),
                  const Spacer(),
                  Text(Money.format(_range.end), style: context.text.caption),
                ],
              ),
              const SizedBox(height: Brand.s16),
              Text(
                'PRECIO ESPECÍFICO',
                style: Brand.ui(
                  10,
                  weight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: Brand.s8),
              TextField(
                controller: _specificPrice,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Precio específico',
                  prefixText: 'S/ ',
                  hintText: '35.00',
                ),
                onSubmitted: (_) => _applyThreshold(),
              ),
              const SizedBox(height: Brand.s8),
              Row(
                children: [
                  Expanded(
                    child: FilterPill(
                      label: 'MENOR A',
                      selected: _comparison == PriceComparison.below,
                      onTap: () => setState(
                        () => _comparison = PriceComparison.below,
                      ),
                    ),
                  ),
                  const SizedBox(width: Brand.s8),
                  Expanded(
                    child: FilterPill(
                      label: 'MAYOR A',
                      selected: _comparison == PriceComparison.above,
                      onTap: () => setState(
                        () => _comparison = PriceComparison.above,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Brand.s8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _applyThreshold,
                      child: const Text('APLICAR PRECIO'),
                    ),
                  ),
                  if (catalog.filters.hasPriceThreshold) ...[
                    const SizedBox(width: Brand.s8),
                    TextButton(
                      onPressed: () {
                        catalog.clearPriceThreshold();
                        _specificPrice.clear();
                        setState(() => _comparison = PriceComparison.none);
                      },
                      child: const Text('QUITAR'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: Brand.s24),
              PillButton(
                label: 'VER ${catalog.visibleCount} PRODUCTOS',
                expanded: true,
                showArrow: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
