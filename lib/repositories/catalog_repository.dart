import '../models/menu_data.dart';

/// Contrato del catálogo (categorías y productos).
abstract interface class CatalogRepository {
  /// Lectura puntual del catálogo publicado.
  Future<MenuData> fetchMenu();

  /// Escucha cambios del catálogo en tiempo real.
  Stream<MenuData> watchMenu();
}
