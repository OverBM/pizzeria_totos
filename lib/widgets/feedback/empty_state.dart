part of '../widgets.dart';


/// Estado vacío con acción de recarga.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.illustration,
    this.actionLabel = 'RECARGAR',
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? illustration;
  final String actionLabel;
  final VoidCallback? onAction;

  /// Acción secundaria opcional (p. ej. abrir la carpeta de Drive del negocio).
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Brand.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null)
              SizedBox(height: 160, width: 220, child: illustration)
            else
              Container(
                height: 96,
                width: 96,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(icon, size: 40, color: colors.action),
              ),
            const SizedBox(height: Brand.s16),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: Brand.display(22, h: 1.05, color: colors.textPrimary),
            ),
            const SizedBox(height: Brand.s8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodySm.copyWith(color: colors.textSecondary),
            ),
            if (onAction != null) ...[
              const SizedBox(height: Brand.s16),
              PillButton(
                label: actionLabel,
                onPressed: onAction,
                filled: false,
                showArrow: true,
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: Brand.s8),
              TextButton.icon(
                onPressed: onSecondary,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
