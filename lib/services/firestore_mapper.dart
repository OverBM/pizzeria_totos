import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversión entre documentos de Firestore y los mapas que consumen los
/// modelos puros.
///
/// Los modelos aceptan `Timestamp` (vía `toDate()`), cadenas ISO-8601 y
/// `DateTime`, así que la lectura es tolerante a documentos incompletos.
class FirestoreMapper {
  const FirestoreMapper._();

  /// Datos de un documento con su `id` incluido cuando el modelo lo necesita.
  static Map<String, dynamic> fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return {...data, 'id': data['id'] ?? doc.id};
  }

  /// Datos de una consulta, conservando el `id` de cada documento.
  static List<Map<String, dynamic>> fromQuery(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => snapshot.docs.map(fromDocument).toList();

  /// Convierte campos de fecha ISO-8601 a `Timestamp` antes de escribir.
  ///
  /// El modelo guarda fechas legibles en sus mapas (para pruebas y caché); en
  /// Firestore se persisten como `Timestamp` para poder ordenar e indexar.
  static Map<String, dynamic> toFirestore(
    Map<String, dynamic> map, {
    Set<String> dateFields = const {},
  }) {
    return map.map((key, value) {
      if (dateFields.contains(key)) {
        if (value is DateTime) {
          return MapEntry(key, Timestamp.fromDate(value));
        }
        if (value is String) {
          final parsed = DateTime.tryParse(value);
          if (parsed != null) {
            return MapEntry(key, Timestamp.fromDate(parsed));
          }
        }
      }
      return MapEntry(key, value);
    });
  }

  /// Convierte marcas de tiempo de Firestore a ISO-8601 para almacenamiento
  /// local (carrito, caché de perfil).
  static Object? toLocalValue(Object? value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return value;
  }
}
