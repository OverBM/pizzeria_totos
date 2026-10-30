import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'theme_context.dart';

/// Familia visual de un producto de la carta.
///
/// Agrupa las nueve categorías reales en seis familias con un icono y un
/// acento propios. El color se aplica solo al icono: el texto conserva los
/// neutros del tema.
enum ProductFamily {
  pizza('Pizza', 'assets/icons/family_pizza.svg', Color(0xFFE2703A)),
  pasta('Pasta', 'assets/icons/family_pasta.svg', Color(0xFFE0A656)),
  dulce('Dulce', 'assets/icons/family_dulce.svg', Color(0xFFE88CA0)),
  combo('Combo', 'assets/icons/family_combo.svg', Color(0xFFB98AD1)),
  guarnicion('Guarnición', 'assets/icons/family_guarnicion.svg', Color(0xFFA9BE6E)),
  bebida('Bebida', 'assets/icons/family_bebida.svg', Color(0xFF77C0CF));

  const ProductFamily(this.label, this.asset, this.accent);

  /// Nombre para lectores de pantalla.
  final String label;

  /// SVG monocromo que se tiñe con [accent].
  final String asset;

  /// Acento con al menos 3:1 de contraste sobre la tarjeta `#741B1E`.
  final Color accent;

  /// Ámbar de la llama de kcal.
  static const Color flameAccent = Color(0xFFE0A656);

  /// Familia de una categoría de Firestore, o `null` si no se reconoce.
  static ProductFamily? forCategoryId(String? categoryId) {
    switch (categoryId) {
      case 'pizzas':
      case 'medias':
      case 'familiares':
        return ProductFamily.pizza;
      case 'pastas':
      case 'lasanas':
        return ProductFamily.pasta;
      case 'dulces':
        return ProductFamily.dulce;
      case 'combos':
        return ProductFamily.combo;
      case 'guarniciones':
        return ProductFamily.guarnicion;
      case 'bebidas':
        return ProductFamily.bebida;
      default:
        return null;
    }
  }
}

/// Icono de familia de un producto. Si la categoría no se reconoce, cae en un
/// icono genérico para que el negocio pueda crear categorías sin recompilar.
class ProductFamilyIcon extends StatelessWidget {
  const ProductFamilyIcon({
    super.key,
    required this.categoryId,
    this.size = 16,
  });

  final String? categoryId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final family = ProductFamily.forCategoryId(categoryId);
    if (family == null) {
      return Icon(
        Icons.restaurant_menu_rounded,
        size: size,
        color: context.colors.textSecondary,
      );
    }
    return SvgPicture.asset(
      family.asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(family.accent, BlendMode.srcIn),
      placeholderBuilder: (context) => Icon(
        Icons.restaurant_menu_rounded,
        size: size,
        color: family.accent,
      ),
    );
  }
}
