import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/components.dart';
import '../../services/connectivity_service.dart';

/// Aviso discreto de modo offline para pantallas con datos cacheados.
///
/// Usa el componente de marca y no interrumpe: ocupa una franja fina y
/// desaparece al recuperar la red.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.margin});

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: connectivity.isOffline
          ? Padding(
              padding:
                  margin ??
                  const EdgeInsets.fromLTRB(Brand.s16, Brand.s8, Brand.s16, 0),
              child: const OfflineNotice(),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
