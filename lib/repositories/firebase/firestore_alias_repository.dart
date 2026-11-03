import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/auth/alias_policy.dart';
import '../alias_repository.dart';
import '../repository_exception.dart';

/// Resolución de alias con Firestore.
///
/// Es el fallback de beta cuando no hay Cloud Functions; se retira antes del
/// 2026-12-31. El documento solo debe leerse por `get`, nunca listarse.
class FirestoreAliasRepository implements AliasRepository {
  FirestoreAliasRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _alias(String alias) =>
      _firestore.collection('aliases').doc(alias.trim().toLowerCase());

  @override
  Future<String?> emailForAlias(String alias) async {
    try {
      final snapshot = await _alias(alias).get();
      if (!snapshot.exists) return null;
      final email = snapshot.data()?['email'];
      return email is String && email.isNotEmpty ? email : null;
    } catch (error) {
      throw RepositoryException(
        'No se pudo resolver el alias.',
        code: error.toString(),
      );
    }
  }

  @override
  Future<void> claimAlias({
    required String uid,
    required String alias,
    required String email,
  }) async {
    final normalized = alias.trim().toLowerCase();
    final error = AliasPolicy.validate(normalized);
    if (error != null) {
      throw RepositoryException(error);
    }
    try {
      await _firestore.runTransaction((transaction) async {
        final reference = _alias(normalized);
        final snapshot = await transaction.get(reference);
        if (snapshot.exists) {
          final owner = snapshot.data()?['uid'];
          if (owner != uid) {
            throw const RepositoryException(
              'Ese alias ya está en uso. Elige otro.',
            );
          }
          return;
        }
        transaction.set(reference, {
          'uid': uid,
          'email': email,
          'alias': normalized,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on RepositoryException {
      rethrow;
    } catch (error) {
      throw RepositoryException(
        'No se pudo guardar el alias.',
        code: error.toString(),
      );
    }
  }

  @override
  Future<void> releaseAlias({
    required String uid,
    required String alias,
  }) async {
    try {
      final reference = _alias(alias);
      final snapshot = await reference.get();
      if (snapshot.data()?['uid'] == uid) {
        await reference.delete();
      }
    } catch (error) {
      throw RepositoryException(
        'No se pudo liberar el alias anterior.',
        code: error.toString(),
      );
    }
  }

  @override
  Future<String?> aliasForUid(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('aliases')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data()['alias'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Alias sugerido a partir de la parte local del correo.
  @override
  String suggestFromEmail(String email) {
    final local = email.split('@').first.toLowerCase();
    final clean = local
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '')
        .replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');
    return clean.isEmpty ? 'totos' : clean;
  }

  /// Genera un alias único agregando sufijo numérico.
  @override
  Future<String> uniqueAlias(String base) async {
    var candidate = base;
    var suffix = 1;
    while (AliasPolicy.validate(candidate) != null ||
        await emailForAlias(candidate) != null) {
      candidate = '$base$suffix';
      suffix += 1;
      if (suffix > 9999) return 'totos${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
    return candidate;
  }
}
