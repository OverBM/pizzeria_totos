import 'package:cloud_functions/cloud_functions.dart';

/// Resuelve alias con una Cloud Function y App Check.
///
/// La app usa el fallback de Firestore en beta; este resolvedor queda listo
/// para activarse cuando la función esté desplegada y el proyecto tenga Blaze.
class CallableAliasResolver {
  CallableAliasResolver({FirebaseFunctions? functions, String region = 'us-central1'})
    : _functions = functions ?? FirebaseFunctions.instanceFor(region: region);

  final FirebaseFunctions _functions;

  Future<String?> resolveEmail(String alias) async {
    try {
      final result = await _functions.httpsCallable('resolveAlias').call({
        'alias': alias.trim().toLowerCase(),
      });
      final data = result.data;
      if (data is Map && data['email'] is String) {
        final email = (data['email'] as String).trim();
        return email.isEmpty ? null : email;
      }
      return null;
    } on FirebaseFunctionsException {
      // La UI muestra un mensaje genérico; no se revela si el alias existe.
      return null;
    }
  }
}
