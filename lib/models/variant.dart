import '../core/format/money.dart';
import 'model_utils.dart';

/// Variante de un producto (entera, media, familiar, u única).
///
/// En Firestore se guarda como `{ etiqueta, precio, tamano, rebanadas }`.
class Variant {
  const Variant({
    required this.label,
    required this.priceSoles,
    this.size,
    this.slices,
  });

  /// Etiqueta base: `entera`, `media`, `familiar`, `única`.
  final String label;

  /// Precio en soles (con IGV incluido).
  final double priceSoles;

  /// Tamaño opcional (p. ej. `grande`).
  final String? size;

  /// Número de rebanadas opcional.
  final int? slices;

  factory Variant.fromMap(Map<String, dynamic> json) => Variant(
    label: ModelUtils.asString(
      json['etiqueta'] ?? json['label'],
      fallback: 'única',
    ),
    priceSoles: ModelUtils.asMoney(
      json,
      'precio',
      centsKey: 'priceCents',
    ),
    size: ModelUtils.asStringOrNull(json['tamano'] ?? json['size']),
    slices: ModelUtils.asIntOrNull(json['rebanadas'] ?? json['slices']),
  );

  /// Etiqueta para la UI, con rebanadas cuando aplica.
  String get displayLabel {
    if (slices != null && label != 'única') {
      return '${label.toUpperCase()} · $slices REBANADAS';
    }
    return label.toUpperCase();
  }

  Map<String, dynamic> toMap() => {
    'etiqueta': label,
    'precio': Money.round(priceSoles),
    if (size != null) 'tamano': size,
    if (slices != null) 'rebanadas': slices,
  };
}
