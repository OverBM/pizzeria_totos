import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/claim.dart';
import '../../services/firestore_mapper.dart';
import '../claim_repository.dart';
import '../repository_exception.dart';

/// Reclamos del usuario en `reclamos`.
class FirestoreClaimRepository implements ClaimRepository {
  FirestoreClaimRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _claims =>
      _firestore.collection('reclamos');

  @override
  Stream<List<Claim>> watchClaims(String uid) => _claims
      .where('uid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(_build);

  @override
  Future<List<Claim>> fetchClaims(String uid) async {
    try {
      final snapshot = await _claims
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      return _build(snapshot);
    } catch (error) {
      throw RepositoryException(
        'No se pudo cargar tus reclamos.',
        code: error.toString(),
      );
    }
  }

  @override
  Future<String> createClaim(Claim claim) async {
    try {
      final reference = _claims.doc();
      await reference.set(
        FirestoreMapper.toFirestore({
          ...claim.toMap(),
          'id': reference.id,
        }, dateFields: {'createdAt', 'updatedAt'}),
      );
      return reference.id;
    } catch (error) {
      throw RepositoryException(
        'No se pudo enviar el reclamo. Inténtalo de nuevo.',
        code: error.toString(),
      );
    }
  }

  List<Claim> _build(QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot
      .docs
      .map((doc) => Claim.fromMap(doc.data(), id: doc.id))
      .toList();
}
