import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../services/maps/maps_service.dart';

/// Hoja de búsqueda de direcciones con OpenStreetMap (Nominatim).
///
/// Devuelve un [PlaceResult] al tocar un resultado; se usa en el perfil para
/// completar la dirección de entrega sin escribirla a mano.
class AddressSearchSheet extends StatefulWidget {
  const AddressSearchSheet({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<AddressSearchSheet> createState() => _AddressSearchSheetState();
}

class _AddressSearchSheetState extends State<AddressSearchSheet> {
  late final TextEditingController _query = TextEditingController(
    text: widget.initialQuery ?? '',
  );
  Timer? _debounce;
  int _seq = 0;
  bool _loading = false;
  List<PlaceResult> _results = const [];

  static const int _minChars = 4;

  @override
  void initState() {
    super.initState();
    if (_query.text.trim().length >= _minChars) {
      _debounce = Timer(
        const Duration(milliseconds: 250),
        () => _search(_query.text.trim()),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    setState(() {
      if (query.length < _minChars) {
        _results = const [];
        _loading = false;
      }
    });
    if (query.length < _minChars) return;
    _debounce = Timer(
      const Duration(milliseconds: 650),
      () => _search(query),
    );
  }

  Future<void> _search(String query) async {
    final seq = ++_seq;
    setState(() => _loading = true);
    final results = await mapsService.search(query, limit: 5);
    if (!mounted || seq != _seq) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final query = _query.text.trim();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(Brand.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BUSCAR DIRECCIÓN',
                style: Brand.display(22, h: 1, color: colors.textPrimary),
              ),
              const SizedBox(height: Brand.s8),
              Text(
                'Escribe una calle, un distrito o un lugar de Huancayo.',
                style: context.text.bodySm.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: Brand.s12),
              TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: (value) {
                  final text = value.trim();
                  if (text.length >= _minChars) _search(text);
                },
                decoration: InputDecoration(
                  labelText: 'Dirección o lugar',
                  hintText: 'Av. Giráldez 123, El Tambo…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: Brand.s8),
              if (query.length < _minChars && !_loading)
                Text(
                  'Escribe al menos $_minChars letras.',
                  style: context.text.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              else if (!_loading && _results.isEmpty)
                Text(
                  'Sin resultados en Huancayo. Prueba con otro nombre.',
                  style: context.text.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              else
                for (final place in _results)
                  _AddressRow(
                    place: place,
                    onTap: () => Navigator.of(context).pop(place),
                  ),
              const SizedBox(height: Brand.s8),
              Text(
                'Resultados de ${mapsService.attribution}',
                style: Brand.ui(9, color: colors.textDisabled),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.place, required this.onTap});

  final PlaceResult place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Brand.s8),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, color: colors.action),
            const SizedBox(width: Brand.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySm,
                  ),
                  if (place.detail != null)
                    Text(
                      place.detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
