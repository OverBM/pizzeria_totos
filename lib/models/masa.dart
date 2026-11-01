/// Tipos de masa disponibles para las pizzas.
enum MasaType {
  normal('normal', 'Normal', 'Masa clásica, textura suave'),
  masaMadre('masaMadre', 'Masa madre', 'Fermentación lenta, borde dorado'),
  dulce('dulce', 'Dulce', 'Base dulce para postres');

  const MasaType(this.value, this.label, this.description);

  /// Valor que se guarda en Firestore.
  final String value;

  /// Etiqueta visible.
  final String label;

  /// Descripción corta para la ficha del producto.
  final String description;

  static MasaType? fromValue(String? value) {
    final clean = (value ?? '').trim().toLowerCase();
    if (clean.isEmpty) return null;
    for (final type in MasaType.values) {
      if (type.value.toLowerCase() == clean ||
          type.label.toLowerCase() == clean ||
          (clean == 'masa_madre' && type == MasaType.masaMadre)) {
        return type;
      }
    }
    return null;
  }
}
