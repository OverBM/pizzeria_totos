part of '../widgets.dart';


/// Tarjeta de sede con bloque de mapa de marca.
class BranchMapCard extends StatelessWidget {
  const BranchMapCard({
    super.key,
    required this.name,
    required this.address,
    required this.statusLabel,
    required this.open,
    this.hoursLabel,
    this.distanceLabel,
    this.deliveryLabel,
    this.thumbnail,
    this.onCall,
    this.onMap,
    this.onWhatsapp,
    this.selected = false,
    this.onSelect,
  });

  final String name;
  final String address;
  final String statusLabel;
  final bool open;
  final String? hoursLabel;

  /// Distancia a la dirección buscada (solo en el módulo de Sedes).
  final String? distanceLabel;
  final String? deliveryLabel;

  /// Imagen superior de la tarjeta; si falta, se dibuja el mapa estilizado.
  final Widget? thumbnail;
  final VoidCallback? onCall;
  final VoidCallback? onMap;
  final VoidCallback? onWhatsapp;
  final bool selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MotionPressable(
      onTap: onSelect,
      semanticLabel: 'Sede $name',
      child: Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(
          color: selected ? colors.action : colors.border,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: thumbnail ??
                CustomPaint(
                  painter: _MapGridPainter(color: colors.action),
                  child: Center(
                    child: Icon(
                      Icons.location_on_rounded,
                      color: colors.action,
                      size: 32,
                    ),
                  ),
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(Brand.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name.toUpperCase(),
                        style: Brand.display(
                          18,
                          h: 1,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (selected)
                      Padding(
                        padding: const EdgeInsets.only(right: Brand.s4),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: colors.action,
                        ),
                      ),
                    StatusPill(label: statusLabel, filled: open),
                  ],
                ),
                const SizedBox(height: Brand.s4),
                Text(address, style: context.text.bodySm),
                if (hoursLabel != null) ...[
                  const SizedBox(height: Brand.s2),
                  Text(
                    hoursLabel!,
                    style: Brand.ui(11, color: colors.textSecondary),
                  ),
                ],
                if (distanceLabel != null) ...[
                  const SizedBox(height: Brand.s4),
                  Row(
                    children: [
                      Icon(
                        Icons.near_me_outlined,
                        size: 13,
                        color: colors.action,
                      ),
                      const SizedBox(width: Brand.s4),
                      Expanded(
                        child: Text(
                          distanceLabel!,
                          style: Brand.ui(11, color: colors.action),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: Brand.s8),
                Row(
                  children: [
                    if (onCall != null)
                      _IconAction(
                        icon: Icons.call_outlined,
                        label: 'Llamar',
                        onTap: onCall,
                      ),
                    if (onWhatsapp != null)
                      _IconAction(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'WhatsApp',
                        onTap: onWhatsapp,
                      ),
                    if (onMap != null)
                      _IconAction(
                        icon: Icons.map_outlined,
                        label: 'Mapa',
                        onTap: onMap,
                      ),
                  ],
                ),
                if (deliveryLabel != null)
                  Text(
                    deliveryLabel!,
                    style: Brand.ui(11, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      icon: Icon(icon, size: 17, color: context.colors.textPrimary),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFF3E0A0C);
    canvas.drawRect(Offset.zero & size, background);
    final line = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    const step = 18.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final road = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.35,
        size.width,
        size.height * 0.5,
      );
    canvas.drawPath(path, road);
    final dot = Paint()..color = color.withValues(alpha: 0.45);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(12 + i * (size.width - 24) / 4, size.height * 0.2),
        2,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) =>
      oldDelegate.color != color;
}
