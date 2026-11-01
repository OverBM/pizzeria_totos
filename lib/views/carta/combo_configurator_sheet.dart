import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/cart_controller.dart';
import '../../controllers/promotion_controller.dart';
import '../../core/format/money.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/theme_context.dart';
import '../../models/masa.dart';
import '../../models/product.dart';
import '../../models/product_option.dart';
import '../../models/variant.dart';
import '../../widgets/widgets.dart';

/// Selección devuelta por el configurador de un combo.
class ComboSelection {
  const ComboSelection({required this.componentes, required this.extras});

  final List<SelectedComponent> componentes;
  final List<ProductExtra> extras;
}

/// Agrega un producto al carrito. Si es un combo, abre el configurador.
Future<bool> addProductToCart(
  BuildContext context,
  Product product,
  Variant variant, {
  MasaType? masa,
  List<ProductExtra> extras = const [],
  List<SelectedComponent>? initialComponents,
  int quantity = 1,
  String? replaceKey,
}) async {
  final cart = context.read<CartController>();
  var selectedExtras = extras;
  var selectedComponents = initialComponents ?? const <SelectedComponent>[];

  if (product.hasComponentes) {
    final selection = await showModalBottomSheet<ComboSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) => ComboConfiguratorSheet(
        product: product,
        variant: variant,
        initialExtras: extras,
        initialComponents: initialComponents,
      ),
    );
    if (selection == null) return false;
    selectedExtras = selection.extras;
    selectedComponents = selection.componentes;
  }

  if (replaceKey != null) {
    cart.replaceLine(
      replaceKey,
      product,
      variant,
      quantity: quantity,
      masa: masa,
      extras: selectedExtras,
      componentes: selectedComponents,
    );
  } else {
    cart.add(
      product,
      variant,
      quantity: quantity,
      masa: masa,
      extras: selectedExtras,
      componentes: selectedComponents,
    );
  }

  if (!context.mounted) return true;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${product.name} agregado al pedido'),
        duration: const Duration(seconds: 2),
      ),
    );
  return true;
}

/// Hoja para elegir los componentes y extras de un combo.
class ComboConfiguratorSheet extends StatefulWidget {
  const ComboConfiguratorSheet({
    super.key,
    required this.product,
    required this.variant,
    this.initialExtras = const [],
    this.initialComponents,
  });

  final Product product;
  final Variant variant;
  final List<ProductExtra> initialExtras;
  final List<SelectedComponent>? initialComponents;

  @override
  State<ComboConfiguratorSheet> createState() =>
      _ComboConfiguratorSheetState();
}

class _ComboConfiguratorSheetState extends State<ComboConfiguratorSheet> {
  final Map<String, String?> _selected = {};
  late final Set<ProductExtra> _extras;

  @override
  void initState() {
    super.initState();
    _extras = {...widget.initialExtras};
    for (final component in widget.product.componentes) {
      String? selected;
      final initial = widget.initialComponents;
      if (initial != null) {
        for (final item in initial) {
          if (item.nombre == component.nombre) {
            selected = item.opcion;
            break;
          }
        }
      }
      _selected[component.nombre] =
          selected ?? (component.opciones.isEmpty ? null : component.opciones.first);
    }
  }

  double get _extrasTotal =>
      Money.sum(_extras.map((extra) => extra.precioSoles));

  double _basePrice(BuildContext context) {
    final promotions = context.read<PromotionController>();
    return promotions.priceFor(widget.product, widget.variant).finalSoles;
  }

  void _confirm() {
    final components = <SelectedComponent>[
      for (final component in widget.product.componentes)
        SelectedComponent(
          nombre: component.nombre,
          cantidad: component.cantidad,
          opcion: _selected[component.nombre],
        ),
    ];
    Navigator.of(context).pop(
      ComboSelection(
        componentes: components,
        extras: _extras.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final product = widget.product;
    final total = Money.round(_basePrice(context) + _extrasTotal);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
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
              Text(
                'PERSONALIZA TU ${product.name}',
                style: Brand.display(22, h: 1, color: colors.textPrimary),
              ),
              const SizedBox(height: Brand.s8),
              Text(
                'Elige cada componente. Las opciones no cambian el precio.',
                style: context.text.bodySm.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              for (final component in product.componentes) ...[
                const SizedBox(height: Brand.s20),
                Text(
                  '${component.cantidad}× ${component.nombre}',
                  style: Brand.ui(12, weight: FontWeight.w700),
                ),
                const SizedBox(height: Brand.s8),
                if (component.opciones.isEmpty)
                  Text(
                    'Incluido',
                    style: context.text.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  )
                else
                  Wrap(
                    spacing: Brand.s8,
                    runSpacing: Brand.s8,
                    children: [
                      for (final option in component.opciones)
                        FilterPill(
                          label: option,
                          selected: _selected[component.nombre] == option,
                          onTap: () => setState(
                            () => _selected[component.nombre] = option,
                          ),
                        ),
                    ],
                  ),
              ],
              if (product.extras.isNotEmpty) ...[
                const SizedBox(height: Brand.s20),
                Text(
                  'EXTRAS PARA LA PIZZA',
                  style: Brand.ui(
                    10,
                    weight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: Brand.s4),
                for (final extra in product.extras)
                  CheckboxListTile(
                    value: _extras.contains(extra),
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        _extras.add(extra);
                      } else {
                        _extras.remove(extra);
                      }
                    }),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: colors.action,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(extra.nombre, style: context.text.bodySm),
                    secondary: Text(
                      '+ ${Money.format(extra.precioSoles)}',
                      style: Brand.ui(12, weight: FontWeight.w700),
                    ),
                  ),
              ],
              const SizedBox(height: Brand.s24),
              Row(
                children: [
                  Text(
                    'TOTAL',
                    style: Brand.ui(
                      10,
                      weight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    Money.format(total),
                    style: Brand.ui(
                      20,
                      weight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Brand.s16),
              PillButton(
                label: 'AGREGAR AL PEDIDO',
                expanded: true,
                showArrow: true,
                onPressed: _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
