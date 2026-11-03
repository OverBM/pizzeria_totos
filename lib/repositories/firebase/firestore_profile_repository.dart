import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/account.dart';
import '../../services/firestore_mapper.dart';
import '../profile_repository.dart';
import '../repository_exception.dart';

/// Perfil del usuario en `usuarios/{uid}`.
class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('usuarios').doc(uid);

  @override
  Stream<Account?> watchProfile(String uid) => _doc(uid).snapshots().map(
    (snapshot) => snapshot.exists
        ? Account.fromMap(snapshot.data() ?? const {}, uid: uid)
        : null,
  );

  @override
  Future<Account?> fetchProfile(String uid) async {
    try {
      final snapshot = await _doc(uid).get();
      if (!snapshot.exists) return null;
      return Account.fromMap(snapshot.data() ?? const {}, uid: uid);
    } catch (error) {
      throw RepositoryException(
        'No se pudo cargar el perfil.',
        code: error.toString(),
      );
    }
  }

  @override
  Future<void> ensureProfile({
    required String uid,
    required String name,
    required String email,
    String alias = '',
  }) async {
    try {
      final reference = _doc(uid);
      final snapshot = await reference.get();
      if (snapshot.exists) return;
      final now = DateTime.now().toIso8601String();
      await reference.set(
        FirestoreMapper.toFirestore({
          'uid': uid,
          'nombre': name,
          'email': email,
          if (alias.isNotEmpty) 'usuario': alias,
          'telefono': '',
          'direcciones': <Map<String, dynamic>>[],
          'createdAt': now,
          'updatedAt': now,
        }, dateFields: {'createdAt', 'updatedAt'}),
      );
    } catch (error) {
      throw RepositoryException(
        'No se pudo crear el perfil.',
        code: error.toString(),
      );
    }
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? alias,
    String? phone,
    List<Address>? addresses,
  }) async {
    try {
      await _doc(uid).set(
        FirestoreMapper.toFirestore({
          'nombre': ?name,
          'usuario': ?alias,
          'telefono': ?phone,
          if (addresses != null)
            'direcciones': addresses.map((a) => a.toMap()).toList(),
          'updatedAt': DateTime.now().toIso8601String(),
        }, dateFields: {'updatedAt'}),
        SetOptions(merge: true),
      );
    } catch (error) {
      throw RepositoryException(
        'No se pudo guardar el perfil.',
        code: error.toString(),
      );
    }
  }

  @override
  Future<Address> addAddress({
    required String uid,
    required Address address,
  }) async {
    final current =
        await fetchProfile(uid) ?? Account(uid: uid, name: '', email: '');
    final updated = current.withAddress(address);
    await updateProfile(uid: uid, addresses: updated.addresses);
    return address;
  }

  @override
  Future<void> removeAddress({
    required String uid,
    required String addressId,
  }) async {
    final current = await fetchProfile(uid);
    if (current == null) return;
    await updateProfile(
      uid: uid,
      addresses: current.withoutAddress(addressId).addresses,
    );
  }
}
