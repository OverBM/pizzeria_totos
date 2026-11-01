import 'dart:async';

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

  int _activeCount(CatalogFilters filters) => [
    filters.excludedAllergens.length,
    if (filters.calorieBand != CalorieBand.all) 1,
    if (filters.hasPriceFilter) 1,
    if (filters.masa != null) 1,
    if (filters.formato != null) 1,
    if (filters.tipo != null) 1,
  ].fold<int>(0, (sum, value) => sum + value);

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    _syncQuery(catalog.searchQuery);
    final active = _activeCount(catalog.filters);

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
    final filters = catalog.filters;
    final chips = <Widget>[];
    for (final allergen in filters.excludedAllergens) {
      chips.add(
        FilterPill(
          label: 'Sin $allergen',
          selected: true,
          onTap: () => catalog.toggleAllergen(allergen),
        ),
      );
    }
    if (filters.masa != null) {
      chips.add(
        FilterPill(
          label: filters.masa!.label,
          selected: true,
          onTap: () => catalog.setMasa(null),
        ),
      );
    }
    if (filters.formato != null) {
      chips.add(
        FilterPill(
          label: filters.formato!,
          selected: true,
          onTap: () => catalog.setFormato(null),
        ),
      );
    }
    if (filters.tipo != null) {
      chips.add(
        FilterPill(
          label: filters.tipo!,
          selected: true,
          onTap: () => catalog.setTipo(null),
        ),
      );
    }
    if (filters.calorieBand != CalorieBand.all) {
      chips.add(
        FilterPill(
          label: filters.calorieBand.label,
          selected: true,
          onTap: () => catalog.setCalorieBand(CalorieBand.all),
        ),
      );
    }
    if (filters.hasPriceFilter) {
      chips.add(
        FilterPill(
          label: _priceLabel(filters),
          selected: true,
          onTap: catalog.clearPriceRange,
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

  static String _priceLabel(CatalogFilters filters) {
    final min = filters.minPrice;
    final max = filters.maxPrice;
    if (min != null && max != null) {
      return '${Money.format(min)} – ${Money.format(max)}';
    }
    if (min != null) return 'Desde ${Money.format(min)}';
    return 'Hasta ${Money.format(max!)}';
  }

  Future<void> _openFilters(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
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
  late final TextEditingController _minPrice;
  late final TextEditingController _maxPrice;
  Timer? _debounce;
  String? _rangeError;

  @override
  void initState() {
    super.initState();
    final filters = context.read<CatalogController>().filters;
    _minPrice = TextEditingController(text: _input(filters.minPrice));
    _maxPrice = TextEditingController(text: _input(filters.maxPrice));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _minPrice.dispose();
    _maxPrice.dispose();
    super.dispose();
  }

  static String _input(double? value) =>
      value == null ? '' : value.toStringAsFixed(2);

  double? _parse(String raw) {
    final text = raw.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  void _applyRange() {
    final catalog = context.read<CatalogController>();
    final rawMin = _minPrice.text.trim();
    final rawMax = _maxPrice.text.trim();
    final min = _parse(rawMin);
    final max = _parse(rawMax);
    String? error;
    if (rawMin.isNotEmpty && (min == null || min <= 0)) {
      error = 'Ingresa un monto mayor a S/ 0.00';
    } else if (rawMax.isNotEmpty && (max == null || max <= 0)) {
      error = 'Ingresa un monto mayor a S/ 0.00';
    } else if (min != null && max != null && min > max) {
      error = 'El mínimo no puede ser mayor que el máximo';
    }
    if (error != null) {
      setState(() => _rangeError = error);
      return;
    }
    setState(() => _rangeError = null);
    catalog.setPriceRange(min, max);
  }

  void _onPriceChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _applyRange);
  }

  void _setBand(double? min, double? max) {
    _debounce?.cancel();
    final filters = context.read<CatalogController>().filters;
    if (_bandSelected(filters, min, max)) {
      _minPrice.clear();
      _maxPrice.clear();
      _applyRange();
      return;
    }
    _minPrice.text = _input(min);
    _maxPrice.text = _input(max);
    _applyRange();
  }

  void _clearAll() {
    _debounce?.cancel();
    _minPrice.clear();
    _maxPrice.clear();
    context.read<CatalogController>().clearFilters();
    setState(() => _rangeError = null);
  }

  bool _bandSelected(CatalogFilters filters, double? min, double? max) {
    final currentMin = filters.minPrice;
    final currentMax = filters.maxPrice;
    if (min == null && max == null) {
      return currentMin == null && currentMax == null;
    }
    if (min == null) {
      return currentMin == null && Money.equals(currentMax ?? 0, max!);
    }
    if (max == null) {
      return currentMax == null && Money.equals(currentMin ?? 0, min);
    }
    return Money.equals(currentMin ?? 0, min) &&
        Money.equals(currentMax ?? 0, max);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final colors = context.colors;
    final filters = catalog.filters;
    final active = [
      filters.excludedAllergens.length,
      if (filters.calorieBand != CalorieBand.all) 1,
      if (filters.hasPriceFilter) 1,
      if (filters.masa != null) 1,
      if (filters.formato != null) 1,
      if (filters.tipo != null) 1,
    ].fold<int>(0, (sum, value) => sum + value);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    'FILTROS ($active)',
                    style: Brand.display(22, h: 1, color: colors.textPrimary),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearAll,
                    child: const Text('LIMPIAR'),
                  ),
                ],
              ),
              const SizedBox(height: Brand.s16),
              if (catalog.masaOptions.isNotEmpty) ...[
                const _FilterSection(title: 'MASA'),
                Wrap(
                  spacing: Brand.s8,
                  runSpacing: Brand.s8,
                  children: [
                    for (final masa in catalog.masaOptions)
                      FilterPill(
                        label: masa.label,
                        selected: filters.masa == masa,
                        onTap: () =>
                            catalog.setMasa(filters.masa == masa ? null : masa),
                      ),
                  ],
                ),
                const SizedBox(height: Brand.s16),
              ],
              if (catalog.formatoOptions.isNotEmpty) ...[
                const _FilterSection(title: 'FORMATO'),
                Wrap(
                  spacing: Brand.s8,
                  runSpacing: Brand.s8,
                  children: [
                    for (final formato in catalog.formatoOptions)
                      FilterPill(
                        label: formato,
                        selected: filters.formato == formato,
                        onTap: () => catalog.setFormato(
                          filters.formato == formato ? null : formato,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Brand.s16),
              ],
              const _FilterSection(title: 'PRECIO'),
              Wrap(
                spacing: Brand.s8,
                runSpacing: Brand.s8,
                children: [
                  FilterPill(
                    label: 'Hasta 25',
                    selected: _bandSelected(filters, null, 25),
                    onTap: () => _setBand(null, 25),
                  ),
                  FilterPill(
                    label: '25–45',
                    selected: _bandSelected(filters, 25, 45),
                    onTap: () => _setBand(25, 45),
                  ),
                  FilterPill(
                    label: '45–70',
                    selected: _bandSelected(filters, 45, 70),
                    onTap: () => _setBand(45, 70),
                  ),
                  FilterPill(
                    label: '70+',
                    selected: _bandSelected(filters, 70, null),
                    onTap: () => _setBand(70, null),
                  ),
                ],
              ),
              const SizedBox(height: Brand.s8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPrice,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      textInputAction: TextInputAction.next,
                      onChanged: _onPriceChanged,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        labelText: 'Desde',
                        prefixText: 'S/ ',
                        hintText: 'Sin mínimo',
                      ),
                    ),
                  ),
                  const SizedBox(width: Brand.s8),
                  Expanded(
                    child: TextField(
                      controller: _maxPrice,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      textInputAction: TextInputAction.done,
                      onChanged: _onPriceChanged,
                      onSubmitted: (_) => _applyRange(),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        labelText: 'Hasta',
                        prefixText: 'S/ ',
                        hintText: 'Sin límite',
                      ),
                    ),
                  ),
                ],
              ),
              if (_rangeError != null) ...[
                const SizedBox(height: Brand.s4),
                Text(
                  _rangeError!,
                  style: context.text.caption.copyWith(color: colors.action),
                ),
              ],
              if (filters.hasPriceFilter)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      _minPrice.clear();
                      _maxPrice.clear();
                      _applyRange();
                    },
                    child: const Text('QUITAR PRECIO'),
                  ),
                ),
              const SizedBox(height: Brand.s16),
              if (catalog.tipoOptions.isNotEmpty) ...[
                const _FilterSection(title: 'TIPO'),
                Wrap(
                  spacing: Brand.s8,
                  runSpacing: Brand.s8,
                  children: [
                    for (final tipo in catalog.tipoOptions)
                      FilterPill(
                        label: tipo,
                        selected: filters.tipo == tipo,
                        onTap: () =>
                            catalog.setTipo(filters.tipo == tipo ? null : tipo),
                      ),
                  ],
                ),
                const SizedBox(height: Brand.s16),
              ],
              if (catalog.allergenOptions.isNotEmpty) ...[
                const _FilterSection(title: 'SIN ALÉRGENOS'),
                Wrap(
                  spacing: Brand.s8,
                  runSpacing: Brand.s8,
                  children: [
                    for (final allergen in catalog.allergenOptions)
                      FilterPill(
                        label: 'Sin $allergen',
                        selected: filters.excludedAllergens.contains(allergen),
                        onTap: () => catalog.toggleAllergen(allergen),
                      ),
                  ],
                ),
                const SizedBox(height: Brand.s16),
              ],
              const _FilterSection(title: 'CALORÍAS POR PORCIÓN'),
              Wrap(
                spacing: Brand.s8,
                runSpacing: Brand.s8,
                children: [
                  for (final band in CalorieBand.values)
                    FilterPill(
                      label: band.label,
                      selected: filters.calorieBand == band,
                      onTap: () => catalog.setCalorieBand(band),
                    ),
                ],
              ),
              const SizedBox(height: Brand.s24),
              PillButton(
                label: 'VER ${catalog.visibleCount} PRODUCTOS',
                expanded: true,
                showArrow: true,
                onPressed: () {
                  _debounce?.cancel();
                  _applyRange();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Brand.s8),
      child: Text(
        title,
        style: Brand.ui(
          10,
          weight: FontWeight.w700,
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}
