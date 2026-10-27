/// Estado de carga expuesto por los controladores a las vistas.
enum LoadState {
  idle,
  loading,
  ready,
  error;

  bool get isLoading => this == LoadState.loading;
  bool get isReady => this == LoadState.ready;
  bool get hasError => this == LoadState.error;
}
