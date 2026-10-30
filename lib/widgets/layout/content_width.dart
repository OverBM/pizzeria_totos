part of '../widgets.dart';

/// Limita el contenido a [maxWidth] y lo centra en pantallas anchas.
///
/// En un teléfono no cambia nada; en una tablet evita que las tarjetas
/// horizontales se estiren hasta los bordes.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 520});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
