part of '../widgets.dart';


/// Titular display con contorno naranja.
class OutlinedDisplayTitle extends StatelessWidget {
  const OutlinedDisplayTitle(
    this.text, {
    super.key,
    this.size = 44,
    this.textAlign = TextAlign.left,
  });

  final String text;
  final double size;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = Brand.display(size, h: 0.95, color: colors.textPrimary);
    return Stack(
      children: [
        Text(
          text.toUpperCase(),
          textAlign: textAlign,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..strokeJoin = StrokeJoin.round
              ..color = colors.action,
          ),
        ),
        Text(text.toUpperCase(), textAlign: textAlign, style: base),
      ],
    );
  }
}
