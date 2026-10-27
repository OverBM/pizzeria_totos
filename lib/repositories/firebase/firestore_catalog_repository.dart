import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/category.dart';
import '../../models/menu_data.dart';
import '../../models/product.dart';
import '../../services/firestore_mapper.dart';
import '../catalog_repository.dart';
import '../repository_exception.dart';

/// Catálogo y categorías desde Firestore.
class FirestoreCatalogRepository implements CatalogRepository {
  FirestoreCatalogRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('productos');

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categorias');

  @override
  Future<MenuData> fetchMenu() async {
    try {
      final results = await Future.wait([_products.get(), _categories.get()]);
      return _build(
        FirestoreMapper.fromQuery(results[0]),
        FirestoreMapper.fromQuery(results[1]),
      );
    } catch (error) {
      throw RepositoryException(
        'No se pudo cargar la carta. Revisa tu conexión e inténtalo de nuevo.',
        code: error.toString(),
      );
    }
  }

  @override
  Stream<MenuData> watchMenu() {
    final controller = StreamController<MenuData>();
    List<Map<String, dynamic>>? products;
    List<Map<String, dynamic>>? categories;

    void emit() {
      if (products == null || categories == null) return;
      controller.add(_build(products!, categories!));
    }

    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[
      _products.snapshots().listen((snapshot) {
        products = FirestoreMapper.fromQuery(snapshot);
        emit();
      }, onError: controller.addError),
      _categories.snapshots().listen((snapshot) {
        categories = FirestoreMapper.fromQuery(snapshot);
        emit();
      }, onError: controller.addError),
    ];

    controller.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
    };
    return controller.stream;
  }

  MenuData _build(
    List<Map<String, dynamic>> productMaps,
    List<Map<String, dynamic>> categoryMaps,
  ) {
    final products = productMaps
        .map(Product.fromMap)
        .where((p) => p.id.isNotEmpty)
        .toList();
    final categories =
        categoryMaps
            .map(MenuCategory.fromMap)
            .where((c) => c.id.isNotEmpty)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return MenuData(categories: categories, products: products);
  }
}
