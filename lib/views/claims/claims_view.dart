import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/claim_controller.dart';
import '../../controllers/order_controller.dart';
import '../../core/load_state.dart';
import '../../core/motion/motion_widgets.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/components.dart';
import '../../core/theme/theme_context.dart';
import '../../core/validation/validators.dart';
import '../../models/claim.dart';
import '../../models/order.dart';
import '../../services/contact_launcher.dart';
import '../../services/settings_service.dart';
import '../common/drive_image.dart';

/// Quinto destino: reclamos internos con historial y seguimiento por WhatsApp.
class ClaimsView extends StatefulWidget {
  const ClaimsView({
    super.key,
    required this.onOpenAuth,
    required this.onOpenClaim,
  });

  final VoidCallback onOpenAuth;
  final void Function(Claim claim) onOpenClaim;

  @override
  State<ClaimsView> createState() => _ClaimsViewState();
}

class _ClaimsViewState extends State<ClaimsView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _message = TextEditingController();
  String? _reasonId;
  String? _orderId;
  Claim? _lastClaim;

  static final DateFormat _date = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final claims = context.watch<ClaimController>();

    if (!auth.isSignedIn) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(top: Brand.s16),
        child: Column(
          children: [
            const ClaimsIllustration(),
            EmptyState(
              title: 'Reclamos',
              message:
                  'Inicia sesión para enviar un reclamo y hacer seguimiento '
                  'de tus casos.',
              actionLabel: 'INICIAR SESIÓN',
              onAction: widget.onOpenAuth,
            ),
          ],
        ),
      );
    }

    final reasons = claims.reasons;
    final reason = _selectedReason(reasons);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Brand.s16,
        Brand.s24,
        Brand.s16,
        Brand.s24,
      ),
      children: [
        _header(context),
        const SizedBox(height: Brand.s16),
        if (_lastClaim != null) ...[
          _sentCard(context, _lastClaim!),
          const SizedBox(height: Brand.s16),
        ],
        _form(context, claims, reason),
        const SizedBox(height: Brand.s24),
        SectionHeading(
          eyebrow: 'Tus casos',
          title: 'Historial',
          actionLabel: 'RECARGAR',
          onAction: claims.watch,
        ),
        const SizedBox(height: Brand.s12),
        _history(context, claims),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: ClaimsIllustration(height: 130, width: 190)),
        const SizedBox(height: Brand.s8),
        Text(
          '‹ ATENCIÓN AL CLIENTE ›',
          style: Brand.ui(11, weight: FontWeight.w700, color: colors.action),
        ),
        const SizedBox(height: Brand.s4),
        const OutlinedDisplayTitle('RECLAMOS', size: 38),
        const SizedBox(height: Brand.s8),
        Text(
          'Cuéntanos qué pasó y te respondemos por WhatsApp. Este es un canal '
          'interno de atención; no reemplaza el Libro de Reclamaciones oficial.',
          style: context.text.bodySm.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }

  Widget _sentCard(BuildContext context, Claim claim) {
    final colors = context.colors;
    final settings = Provider.of<SettingsService>(context, listen: false);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 260),
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        padding: const EdgeInsets.all(Brand.s16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: Brand.cardRadius,
          border: Border.all(color: colors.action, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: colors.action),
                const SizedBox(width: Brand.s8),
                Text(
                  'RECLAMO ENVIADO',
                  style: Brand.ui(
                    12,
                    weight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                MotionPulse(
                  child: StatusPill(
                    label: claim.status.label,
                    filled: false,
                    color: colors.action,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Brand.s8),
            Text(
              '#${claim.code}',
              style: Brand.ui(
                16,
                weight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: Brand.s4),
            Text(
              'Guarda este código. Puedes continuar la conversación por '
              'WhatsApp cuando quieras.',
              style: context.text.caption.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: Brand.s12),
            PillButton(
              label: 'CONTINUAR POR WHATSAPP',
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
    );
  }

  Widget _form(
    BuildContext context,
    ClaimController claims,
    ClaimReason reason,
  ) {
    final colors = context.colors;
    final orders = context.watch<OrderController>().orders;
    return Container(
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
            'NUEVO RECLAMO',
            style: Brand.ui(11, weight: FontWeight.w700, color: colors.action),
          ),
          const SizedBox(height: Brand.s12),
          Text('Motivo', style: context.text.bodySm),
          const SizedBox(height: Brand.s8),
          Wrap(
            spacing: Brand.s8,
            runSpacing: Brand.s8,
            children: [
              for (final item in claims.reasons)
                FilterPill(
                  label: item.label,
                  selected: reason.id == item.id,
                  onTap: () => setState(() => _reasonId = item.id),
                ),
            ],
          ),
          const SizedBox(height: Brand.s16),
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: TextFormField(
              controller: _message,
              maxLines: 4,
              maxLength: Validators.claimMaxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Cuéntanos qué pasó',
                hintText: 'Describe el problema con el mayor detalle posible.',
              ),
              validator: Validators.claimMessageError,
            ),
          ),
          if (orders.isNotEmpty) ...[
            const SizedBox(height: Brand.s12),
            DropdownButtonFormField<String?>(
              initialValue: _orderId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Pedido asociado (opcional)',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sin pedido asociado'),
                ),
                for (final Order order in orders)
                  DropdownMenuItem<String?>(
                    value: order.id,
                    child: Text(
                      '#${order.code} · ${order.branchName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _orderId = value),
            ),
          ],
          const SizedBox(height: Brand.s16),
          PillButton(
            label: claims.isSubmitting ? 'ENVIANDO…' : 'ENVIAR RECLAMO',
            expanded: true,
            showArrow: true,
            onPressed: claims.isSubmitting
                ? null
                : () => _submit(context, claims, reason, orders),
          ),
        ],
      ),
    );
  }

  Widget _history(BuildContext context, ClaimController claims) {
    if (claims.state == LoadState.loading && claims.isEmpty) {
      return const SkeletonList(count: 2, height: 92);
    }
    if (claims.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(Brand.s16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: Brand.cardRadius,
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, color: context.colors.textSecondary),
            const SizedBox(height: Brand.s8),
            Text(
              claims.error ?? 'Todavía no has enviado reclamos.',
              textAlign: TextAlign.center,
              style: context.text.bodySm,
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final claim in claims.claims) ...[
          _ClaimTile(
            claim: claim,
            date: _date,
            onTap: () => widget.onOpenClaim(claim),
          ),
          const SizedBox(height: Brand.s8),
        ],
      ],
    );
  }

  ClaimReason _selectedReason(List<ClaimReason> reasons) {
    final id = _reasonId;
    for (final reason in reasons) {
      if (reason.id == id) return reason;
    }
    return reasons.first;
  }

  Future<void> _submit(
    BuildContext context,
    ClaimController claims,
    ClaimReason reason,
    List<Order> orders,
  ) async {
    final auth = context.read<AuthController>();
    if (!auth.isSignedIn) {
      widget.onOpenAuth();
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Order? order;
    for (final item in orders) {
      if (item.id == _orderId) order = item;
    }
    final claim = await claims.submit(
      ClaimDraft(
        uid: auth.uid,
        categoryId: reason.id,
        categoryLabel: reason.label,
        message: _message.text,
        orderId: order?.id,
        branchId: order?.branchId,
        branchName: order?.branchName,
      ),
    );
    if (claim == null || !mounted) return;
    setState(() {
      _lastClaim = claim;
      _message.clear();
      _orderId = null;
    });
  }
}

class _ClaimTile extends StatelessWidget {
  const _ClaimTile({
    required this.claim,
    required this.date,
    required this.onTap,
  });

  final Claim claim;
  final DateFormat date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MotionPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Brand.s12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: Brand.cardRadius,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${claim.code}',
                    style: Brand.ui(
                      13,
                      weight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                StatusPill(
                  label: claim.status.label,
                  filled: false,
                  color: colors.action,
                ),
              ],
            ),
            const SizedBox(height: Brand.s4),
            Text(
              '${claim.categoryLabel} · ${date.format(claim.createdAt)}',
              style: context.text.caption.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: Brand.s4),
            Text(
              claim.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySm,
            ),
          ],
        ),
      ),
    );
  }
}
