import 'package:flutter/material.dart';

import '../../models/claim.dart';
import '../../widgets/widgets.dart';
import 'claims_view.dart';

/// Reclamos como pantalla propia, para abrirlos desde el perfil.
class ClaimsScreen extends StatelessWidget {
  const ClaimsScreen({
    super.key,
    required this.onOpenAuth,
    required this.onOpenClaim,
  });

  final VoidCallback onOpenAuth;
  final void Function(Claim claim) onOpenClaim;

  @override
  Widget build(BuildContext context) {
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
            child: ClaimsView(
              onOpenAuth: onOpenAuth,
              onOpenClaim: onOpenClaim,
            ),
          ),
        ],
      ),
    );
  }
}
