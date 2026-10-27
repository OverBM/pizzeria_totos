import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/branch_controller.dart';
import '../../core/format/money.dart';
import '../../core/load_state.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/components.dart';
import '../../core/theme/theme_context.dart';
import '../../core/time/lima_time.dart';
import '../../services/contact_launcher.dart';
import '../../services/settings_service.dart';

/// Sedes de Huancayo con horario, delivery y acciones de contacto.
class BranchesView extends StatelessWidget {
  const BranchesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BranchController>();
    final settings = Provider.of<SettingsService>(context, listen: false);

    if (controller.state == LoadState.loading && controller.isEmpty) {
      return const SingleChildScrollView(
        child: SkeletonList(count: 3, height: 230),
      );
    }

    if (controller.isEmpty) {
      return SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: EmptyState(
            title: controller.state == LoadState.error
                ? 'No pudimos cargar las sedes'
                : 'No hay sedes publicadas',
            message:
                controller.error ??
                'Estamos actualizando nuestras sedes de Huancayo. '
                    'Vuelve a intentarlo en un momento.',
            icon: controller.state == LoadState.error
                ? Icons.wifi_off_rounded
                : Icons.location_off_outlined,
            onAction: controller.load,
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Brand.s16,
              Brand.s24,
              Brand.s16,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '‹ DÓNDE ESTAMOS ›',
                  style: Brand.ui(
                    11,
                    weight: FontWeight.w700,
                    color: context.colors.action,
                  ),
                ),
                const SizedBox(height: Brand.s4),
                const OutlinedDisplayTitle('SEDES', size: 40),
                const SizedBox(height: Brand.s8),
                Text(
                  'Cuatro puntos en la provincia de Huancayo. '
                  'Elige la más cercana y coordina tu pedido por WhatsApp.',
                  style: context.text.bodySm.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(Brand.s16),
          sliver: SliverList.separated(
            itemCount: controller.branches.length,
            separatorBuilder: (_, _) => const SizedBox(height: Brand.s12),
            itemBuilder: (context, index) {
              final branch = controller.branches[index];
              final open = branch.isOpenAt(LimaTime.now());
              return BranchMapCard(
                name: branch.name,
                address: branch.address,
                statusLabel: open ? 'ABIERTA' : 'CERRADA',
                open: open,
                hoursLabel: branch.hours.rangeLabel,
                deliveryLabel: branch.delivers
                    ? 'Delivery · envío ${Money.format(branch.deliveryFeeSoles)}'
                    : 'Solo recojo en tienda',
                onCall: () => ContactLauncher.call(
                  branch.phone.isEmpty ? settings.phone : branch.phone,
                ),
                onWhatsapp: () => ContactLauncher.whatsapp(
                  phone: branch.whatsapp.isEmpty
                      ? settings.whatsapp
                      : branch.whatsapp,
                  message:
                      'Hola TOTO\'S, quiero hacer un pedido en la sede '
                      '${branch.name}.',
                ),
                onMap: () => ContactLauncher.openMap(
                  branch.lat,
                  branch.lng,
                  label: 'TOTO\'S ${branch.name}',
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Brand.s24)),
      ],
    );
  }
}
