import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/cart_item.dart';
import 'storage_keys.dart';

/// Persistencia local del carrito.
///
/// El carrito no vive en Firestore: se conserva en el dispositivo y sobrevive
/// al inicio de sesión, al ir al perfil y al cerrar la app.
class CartStorage {
  const CartStorage();

  Future<List<CartItem>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(StorageKeys.cart);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = json.decode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => CartItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        StorageKeys.cart,
        json.encode(items.map((e) => e.toMap()).toList()),
      );
    } catch (_) {
      // La persistencia es best-effort; el estado en memoria ya cambió.
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.cart);
    } catch (_) {
      // Sin efecto fuera de la app.
    }
  }
}
