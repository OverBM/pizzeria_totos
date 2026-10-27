import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/promotion.dart';
import '../../services/firestore_mapper.dart';
import '../promotion_repository.dart';
import '../repository_exception.dart';

/// Promociones desde Firestore (`promociones`).
///
/// La promoción puede no declarar imagen propia: en ese caso la vista usa la
/// foto del producto promocionado (ver `PromoBanner`), y la semilla además deja
/// la referencia escrita para que se vea en la consola.
class FirestorePromotionRepository implements PromotionRepository {
  FirestorePromotionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _promotions =>
      _firestore.collection('promociones');

  @override
  Future<List<Promotion>> fetchPromotions() async {
    try {
      final snapshot = await _promotions.get();
      return _build(FirestoreMapper.fromQuery(snapshot));
    } catch (error) {
      throw RepositoryException(
        'No se pudieron cargar las promociones.',
        code: error.toString(),
      );
    }
  }

  @override
  Stream<List<Promotion>> watchPromotions() => _promotions.snapshots().map(
    (snapshot) => _build(FirestoreMapper.fromQuery(snapshot)),
  );

  List<Promotion> _build(List<Map<String, dynamic>> maps) => maps
      .map(Promotion.fromMap)
      .where((p) => p.id.isNotEmpty && p.active)
      .toList();
}
