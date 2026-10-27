import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/settings.dart';
import '../repository_exception.dart';
import '../settings_repository.dart';

/// Configuración del negocio en `configuracion/app`.
class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('configuracion').doc('app');

  @override
  Future<AppSettings> fetchSettings() async {
    try {
      final snapshot = await _doc.get();
      if (!snapshot.exists) return AppSettings.fallback;
      return AppSettings.fromMap(snapshot.data() ?? const {});
    } catch (error) {
      throw RepositoryException(
        'No se pudo cargar la configuración del negocio.',
        code: error.toString(),
      );
    }
  }

  @override
  Stream<AppSettings> watchSettings() => _doc.snapshots().map(
    (snapshot) => snapshot.exists
        ? AppSettings.fromMap(snapshot.data() ?? const {})
        : AppSettings.fallback,
  );
}
