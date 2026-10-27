import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Disponibilidad del backend al arrancar.
enum BackendStatus { available, unavailable }

/// Inicialización de Firebase y de la caché offline de Firestore.
class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static BackendStatus _status = BackendStatus.unavailable;
  static Object? _lastError;

  static BackendStatus get status => _status;
  static Object? get lastError => _lastError;
  static bool get isAvailable => _status == BackendStatus.available;

  /// Inicializa Firebase con la configuración nativa de la plataforma.
  ///
  /// Si falla (sin `google-services.json`, configuración inválida o error de
  /// red) devuelve [BackendStatus.unavailable]; la app muestra entonces una
  /// pantalla de servicio no disponible con reintento. Nunca carga datos de
  /// relleno.
  static Future<BackendStatus> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      _status = BackendStatus.available;
      _lastError = null;
    } catch (error, stack) {
      _status = BackendStatus.unavailable;
      _lastError = error;
      debugPrint('Firebase no disponible: $error');
      debugPrintStack(stackTrace: stack);
    }
    return _status;
  }
}
