import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/branch.dart';
import '../../services/firestore_mapper.dart';
import '../branch_repository.dart';
import '../repository_exception.dart';

/// Sedes desde Firestore (`sedes`), limitadas a las activas de Huancayo.
class FirestoreBranchRepository implements BranchRepository {
  FirestoreBranchRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _branches =>
      _firestore.collection('sedes');

  @override
  Future<List<Branch>> fetchBranches() async {
    try {
      final snapshot = await _branches.get();
      return _build(FirestoreMapper.fromQuery(snapshot));
    } catch (error) {
      throw RepositoryException(
        'No se pudieron cargar las sedes. Revisa tu conexión.',
        code: error.toString(),
      );
    }
  }

  @override
  Stream<List<Branch>> watchBranches() => _branches.snapshots().map(
    (snapshot) => _build(FirestoreMapper.fromQuery(snapshot)),
  );

  List<Branch> _build(List<Map<String, dynamic>> maps) {
    final branches =
        maps
            .map(Branch.fromMap)
            .where((b) => b.id.isNotEmpty && b.isVisible)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return branches;
  }
}
