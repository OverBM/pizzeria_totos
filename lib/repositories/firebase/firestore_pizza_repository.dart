import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/ingredient.dart';
import '../../models/pizza_config.dart';
import '../../services/firestore_mapper.dart';
import '../pizza_repository.dart';
import '../repository_exception.dart';

/// Ingredientes y configuración desde Firestore.
class FirestorePizzaRepository implements PizzaRepository {
  FirestorePizzaRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Ingredient>> fetchIngredients() async {
    try {
      final snapshot = await _firestore.collection('ingredientes').get();
      return _buildIngredients(FirestoreMapper.fromQuery(snapshot));
    } catch (error) {
      throw RepositoryException(
        'No se pudieron cargar los ingredientes.',
        code: error.toString(),
      );
    }
  }

  @override
  Stream<List<Ingredient>> watchIngredients() => _firestore
      .collection('ingredientes')
      .snapshots()
      .map((snapshot) => _buildIngredients(FirestoreMapper.fromQuery(snapshot)));

  @override
  Future<PizzaConfig> fetchConfig() async {
    try {
      final snapshot = await _firestore
          .collection('configuracion')
          .doc('pizzaPersonalizada')
          .get();
      return PizzaConfig.fromMap(snapshot.data() ?? const {});
    } catch (error) {
      throw RepositoryException(
        'No se pudo cargar la configuración de pizza.',
        code: error.toString(),
      );
    }
  }

  @override
  Stream<PizzaConfig> watchConfig() => _firestore
      .collection('configuracion')
      .doc('pizzaPersonalizada')
      .snapshots()
      .map((snapshot) => PizzaConfig.fromMap(snapshot.data() ?? const {}));

  List<Ingredient> _buildIngredients(List<Map<String, dynamic>> maps) {
    final ingredients = maps
        .map(Ingredient.fromMap)
        .where((ingredient) => ingredient.id.isNotEmpty)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ingredients;
  }
}
