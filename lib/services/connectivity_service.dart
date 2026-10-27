import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Estado de conectividad de red del dispositivo.
///
/// Es solo un aviso: Firestore mantiene su propia caché offline y la app sigue
/// mostrando los datos ya cargados. No bloquea el flujo principal.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Instancia con estado fijo, para pruebas y `--dart-define` sin plugin.
  ConnectivityService.manual({bool online = true})
    : _connectivity = null,
      _online = online;

  final Connectivity? _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _online = true;

  bool get isOnline => _online;
  bool get isOffline => !_online;

  /// Consulta el estado actual y escucha cambios. Nunca lanza.
  Future<void> start() async {
    final connectivity = _connectivity;
    if (connectivity == null) return;
    try {
      _update(await connectivity.checkConnectivity());
      _subscription = connectivity.onConnectivityChanged.listen(
        _update,
        onError: (_) {},
      );
    } catch (_) {
      // Sin plugin (tests/escritorio): se asume online y no se interrumpe.
      _online = true;
      notifyListeners();
    }
  }

  /// Solo para pruebas y para el aviso manual en entornos sin plugin.
  @visibleForTesting
  void setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    notifyListeners();
  }

  void _update(List<ConnectivityResult> results) {
    final online =
        results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);
    if (online == _online) return;
    _online = online;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
