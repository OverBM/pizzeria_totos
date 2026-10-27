import 'category.dart';
import 'product.dart';

/// Carta completa: categorías ordenadas y productos.
class MenuData {
  const MenuData({required this.categories, required this.products});

  static const MenuData empty = MenuData(categories: [], products: []);

  final List<MenuCategory> categories;
  final List<Product> products;

  bool get isEmpty => categories.isEmpty && products.isEmpty;

  List<Product> productsOf(String categoryId) =>
      products.where((p) => p.categoryId == categoryId).toList();

  List<Product> get featured => products.where((p) => p.featured).toList();

  List<MenuCategory> get activeCategories => categories
      .where((c) => c.active && !c.isFeatured)
      .toList();

  Product? byId(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  MenuCategory? categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}
