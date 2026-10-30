import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/brand.dart';
import '../../widgets/widgets.dart';
import '../../core/theme/theme_context.dart';
import '../../models/claim.dart';
import '../../services/contact_launcher.dart';
import '../../services/settings_service.dart';

/// Detalle de un reclamo con estado «Enviado» y seguimiento por WhatsApp.
class ClaimDetailView extends StatelessWidget {
  const ClaimDetailView({super.key, required this.claim});

  final Claim claim;

  static final DateFormat _date = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final settings = Provider.of<SettingsService>(context, listen: false);
    return Scaffold(
      appBar: TotoTopBar(
        showWordmark: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Brand.s16),
              children: [
                const Center(
                  child: ClaimsIllustration(height: 120, width: 180),
                ),
                const SizedBox(height: Brand.s16),
                Text(
                  '‹ RECLAMO ›',
                  style: Brand.ui(
                    11,
                    weight: FontWeight.w700,
                    color: colors.action,
                  ),
                ),
                const SizedBox(height: Brand.s4),
                Text(
                  '#${claim.code}',
                  style: Brand.display(30, h: 1, color: colors.textPrimary),
                ),
                const SizedBox(height: Brand.s8),
                Row(
                  children: [
                    StatusPill(
                      label: claim.status.label,
                      filled: false,
                      color: colors.action,
                    ),
                    const SizedBox(width: Brand.s8),
                    Text(
                      _date.format(claim.createdAt),
                      style: context.text.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Brand.s16),
                _block(context, 'MOTIVO', claim.categoryLabel),
                const SizedBox(height: Brand.s8),
                _block(context, 'MENSAJE', claim.message),
                if (claim.orderId != null) ...[
                  const SizedBox(height: Brand.s8),
                  _block(context, 'PEDIDO ASOCIADO', '#${claim.orderId}'),
                ],
                if (claim.branchName != null) ...[
                  const SizedBox(height: Brand.s8),
                  _block(context, 'SEDE', claim.branchName!),
                ],
                const SizedBox(height: Brand.s24),
                Text(
                  'Este código identifica tu caso. Continúa la conversación por '
                  'WhatsApp para recibir una respuesta.',
                  style: context.text.bodySm.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: Brand.s16),
                PillButton(
                  label: 'CONTINUAR POR WHATSAPP',
                  expanded: true,
                  showArrow: true,
                  onPressed: () => ContactLauncher.whatsapp(
                    phone: settings.whatsapp,
                    message:
                        'Hola TOTO\'S, hago seguimiento a mi reclamo '
                        '#${claim.code}.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _block(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Brand.s12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: Brand.cardRadius,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Brand.ui(9, weight: FontWeight.w700, color: colors.action),
          ),
          const SizedBox(height: Brand.s4),
          Text(value, style: context.text.bodySm),
        ],
      ),
    );
  }
}
