import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../controllers/checkout_controller.dart';
import '../../models/checkout_step.dart';

/// Navega entre los pasos del checkout.
///
/// Solo se puede volver a un paso ya alcanzado: en el paso 1 no hay destinos,
/// en el 2 se puede ir al 1, y en el 3 se puede ir a cualquiera. Al avanzar se
/// validan los pasos que quedan atrás para no llegar a una pantalla inválida.
void goToCheckoutStep(BuildContext context, CheckoutStep target) {
  final checkout = context.read<CheckoutController>();
  if (target.index > checkout.maxStep.index) return;

  final current = ModalRoute.of(context)?.settings.name;
  final navigator = Navigator.of(context);

  // Volver: el destino ya fue visitado y validado.
  if (current == AppRoutes.confirmRouteName) {
    switch (target) {
      case CheckoutStep.confirmar:
        return;
      case CheckoutStep.entrega:
        checkout.reachStep(target);
        _popUntil(navigator, AppRoutes.deliveryRouteName);
        return;
      case CheckoutStep.pedido:
        checkout.reachStep(target);
        _popUntil(navigator, AppRoutes.cartRouteName);
        return;
    }
  }

  if (current == AppRoutes.deliveryRouteName) {
    switch (target) {
      case CheckoutStep.entrega:
        return;
      case CheckoutStep.pedido:
        checkout.reachStep(target);
        _popUntil(navigator, AppRoutes.cartRouteName);
        return;
      case CheckoutStep.confirmar:
        if (!_check(context, checkout, CheckoutStep.entrega)) return;
        checkout.reachStep(target);
        navigator.push(AppRoutes.checkoutConfirm());
        return;
    }
  }

  // Desde el carrito (paso 1) solo se avanza.
  switch (target) {
    case CheckoutStep.pedido:
      return;
    case CheckoutStep.entrega:
      if (!_check(context, checkout, CheckoutStep.pedido)) return;
      checkout.reachStep(target);
      navigator.push(AppRoutes.checkoutDelivery());
      return;
    case CheckoutStep.confirmar:
      if (!_check(context, checkout, CheckoutStep.pedido)) return;
      if (!_check(context, checkout, CheckoutStep.entrega)) return;
      checkout.reachStep(target);
      navigator.push(AppRoutes.checkoutDelivery());
      navigator.push(AppRoutes.checkoutConfirm());
      return;
  }
}

/// Vuelve atrás hasta la ruta indicada sin salir de la pila del checkout.
void _popUntil(NavigatorState navigator, String name) {
  navigator.popUntil((route) => route.settings.name == name || route.isFirst);
}

/// Muestra el primer problema del paso y devuelve si se puede continuar.
bool _check(
  BuildContext context,
  CheckoutController checkout,
  CheckoutStep step,
) {
  final issues = checkout.validateStep(step);
  if (issues.isEmpty) return true;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(issues.first.message)));
  return false;
}
