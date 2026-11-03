import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/coupon.dart';
import '../../services/firestore_mapper.dart';
import '../coupon_repository.dart';
import '../repository_exception.dart';

/// Cupones en `cupones/{codigo}`. Solo se consulta por documento.
class FirestoreCouponRepository implements CouponRepository {
  FirestoreCouponRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _coupon(String code) =>
      _firestore.collection('cupones').doc(code.trim());

  DocumentReference<Map<String, dynamic>> _redemption(
    String code,
    String uid,
  ) => _firestore.collection('redenciones').doc('${code.trim()}_$uid');

  @override
  Future<Coupon?> fetchByCode(String code) async {
    try {
      final snapshot = await _coupon(code).get();
      if (!snapshot.exists) return null;
      return Coupon.fromMap(FirestoreMapper.fromDocument(snapshot));
    } catch (error) {
      throw RepositoryException(
        'No se pudo consultar el cupón.',
        code: error.toString(),
      );
    }
  }

  @override
  Future<bool> wasRedeemed({required String code, required String uid}) async {
    try {
      final snapshot = await _redemption(code, uid).get();
      return snapshot.exists;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> redeem({
    required String code,
    required String uid,
    required String orderId,
  }) async {
    final normalized = code.trim();
    try {
      await _firestore.runTransaction((transaction) async {
        final couponRef = _coupon(normalized);
        final redemptionRef = _redemption(normalized, uid);
        final couponSnapshot = await transaction.get(couponRef);
        final redemptionSnapshot = await transaction.get(redemptionRef);
        if (!couponSnapshot.exists) {
          throw const RepositoryException('Cupón no válido.');
        }
        if (redemptionSnapshot.exists) {
          throw const RepositoryException('Ya usaste este cupón.');
        }
        final coupon = Coupon.fromMap(
          FirestoreMapper.fromDocument(couponSnapshot),
        );
        if (coupon.isExhausted) {
          throw const RepositoryException(
            'Este cupón ya no tiene usos disponibles.',
          );
        }
        transaction.update(couponRef, {'usos': coupon.uses + 1});
        transaction.set(redemptionRef, {
          'uid': uid,
          'codigo': normalized,
          'pedidoId': orderId,
          'creadoEn': FieldValue.serverTimestamp(),
        });
      });
    } on RepositoryException {
      rethrow;
    } catch (error) {
      throw RepositoryException(
        'No se pudo registrar el cupón.',
        code: error.toString(),
      );
    }
  }
}
