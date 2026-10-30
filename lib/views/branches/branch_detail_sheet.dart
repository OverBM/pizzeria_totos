import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/format/money.dart';
import '../../core/theme/brand.dart';
import '../../widgets/widgets.dart';
import '../../core/theme/theme_context.dart';
import '../../core/time/lima_time.dart';
import '../../models/branch.dart';
import '../../services/contact_launcher.dart';

/// Detalle de una sede, reutilizado en Inicio y en Sedes.
///
/// Se abre al tocar el pin del mapa o la tarjeta de la sede. Devuelve `true`
/// cuando el usuario pide verla en el mapa principal.
class BranchDetailSheet extends StatelessWidget {
  const BranchDetailSheet({
    super.key,
    required this.branch,
    required this.phoneFallback,
    required this.whatsappFallback,
    this.distanceLabel,
  });

  final Branch branch;
  final String phoneFallback;
  final String whatsappFallback;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final open = branch.isOpenAt(LimaTime.now());

    return Container(
      decoration: BoxDecoration(
        color: colors.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Brand.s8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: Brand.s12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Brand.s16),
                child: ClipRRect(
                  borderRadius: Brand.cardRadius,
                  child: TotoMap(
                    markers: [
                      TotoMapMarker(
                        id: branch.id,
                        point: LatLng(branch.lat, branch.lng),
                        label: branch.name,
                        selected: true,
                      ),
                    ],
                    height: 150,
                    initialZoom: 15.5,
                    interactive: false,
                    showFitButton: false,
                    flush: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Brand.s16,
                  Brand.s16,
                  Brand.s16,
                  Brand.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            branch.name.toUpperCase(),
                            style: Brand.display(
                              26,
                              h: 1,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        StatusPill(
                          label: open ? 'ABIERTA' : 'CERRADA',
                          filled: open,
                        ),
                      ],
                    ),
                    const SizedBox(height: Brand.s4),
                    Text(branch.address, style: context.text.bodySm),
                    if (branch.district.isNotEmpty)
                      Text(
                        '${branch.district} · ${branch.province}',
                        style: context.text.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: Brand.s12),
                    _DetailRow(
                      icon: Icons.schedule_rounded,
                      label: 'Horario',
                      value: branch.hours.rangeLabel,
                    ),
                    _DetailRow(
                      icon: Icons.delivery_dining_rounded,
                      label: 'Delivery',
                      value: branch.delivers
                          ? 'Sí · envío ${Money.format(branch.deliveryFeeSoles)}'
                          : 'Solo recojo en tienda',
                    ),
                    if (distanceLabel != null)
                      _DetailRow(
                        icon: Icons.near_me_rounded,
                        label: 'Distancia',
                        value: distanceLabel!,
                      ),
                    _DetailRow(
                      icon: Icons.call_outlined,
                      label: 'Teléfono',
                      value: branch.phone.isEmpty
                          ? 'No publicado'
                          : branch.phone,
                    ),
                    const SizedBox(height: Brand.s16),
                    Row(
                      children: [
                        Expanded(
                          child: PillButton(
                            label: 'LLAMAR',
                            filled: false,
                            onPressed: () => ContactLauncher.call(
                              branch.phone.isEmpty
                                  ? phoneFallback
                                  : branch.phone,
                            ),
                          ),
                        ),
                        const SizedBox(width: Brand.s8),
                        Expanded(
                          child: PillButton(
                            label: 'WHATSAPP',
                            onPressed: () => ContactLauncher.whatsapp(
                              phone: branch.whatsapp.isEmpty
                                  ? whatsappFallback
                                  : branch.whatsapp,
                              message:
                                  'Hola TOTO\'S, quiero hacer un pedido en '
                                  'la sede ${branch.name}.',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Brand.s8),
                    PillButton(
                      label: 'CÓMO LLEGAR',
                      filled: false,
                      expanded: true,
                      showArrow: true,
                      onPressed: () => ContactLauncher.openMap(
                        branch.lat,
                        branch.lng,
                        label: "TOTO'S ${branch.name}",
                      ),
                    ),
                    const SizedBox(height: Brand.s8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('VER EN EL MAPA'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Brand.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colors.action),
          const SizedBox(width: Brand.s8),
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: context.text.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: context.text.bodySm)),
        ],
      ),
    );
  }
}
