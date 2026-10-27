import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/load_state.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';
import '../repositories/repository_exception.dart';

/// Historial de pedidos del usuario autenticado.
class OrderController extends ChangeNotifier {
  OrderController({required OrderRepository repository})
    : _repository = repository;

  final OrderRepository _repository;
  StreamSubscription<List<Order>>? _subscription;

  LoadState _state = LoadState.idle;
  List<Order> _orders = const [];
  String? _error;
  String _uid = '';

  LoadState get state => _state;
  List<Order> get orders => _orders;
  String? get error => _error;
  bool get isEmpty => _orders.isEmpty;

  /// Cambia de usuario: reinicia el historial y vuelve a escuchar.
  void bind(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _subscription?.cancel();
    _subscription = null;
    _orders = const [];
    _error = null;
    _state = LoadState.idle;
    notifyListeners();
    if (uid.isNotEmpty) watch();
  }

  void watch() {
    if (_uid.isEmpty) return;
    _state = LoadState.loading;
    notifyListeners();
    _subscription ??= _repository
        .watchOrders(_uid)
        .listen(
          (orders) {
            _orders = orders;
            _state = LoadState.ready;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            _state = LoadState.error;
            _error = error is RepositoryException
                ? error.message
                : 'No se pudo cargar tu historial.';
            notifyListeners();
          },
        );
  }

  Future<void> load() async {
    if (_uid.isEmpty) return;
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _orders = await _repository.fetchOrders(_uid);
      _state = LoadState.ready;
    } catch (error) {
      _state = LoadState.error;
      _error = error is RepositoryException
          ? error.message
          : 'No se pudo cargar tu historial.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
