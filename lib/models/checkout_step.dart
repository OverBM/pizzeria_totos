/// Pasos del checkout.
enum CheckoutStep {
  pedido('Pedido'),
  entrega('Entrega'),
  confirmar('Confirmar');

  const CheckoutStep(this.label);

  final String label;

  int get number => index + 1;

  static const int total = 3;
}
