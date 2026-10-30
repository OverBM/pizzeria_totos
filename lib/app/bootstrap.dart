import 'package:flutter/material.dart';

import 'app_services.dart';
import '../core/theme/brand.dart';
import '../widgets/widgets.dart';
import '../core/theme/theme_context.dart';
import '../services/firebase_bootstrap.dart';

/// Arranque de la app: Firebase → servicios → `runApp`.
///
/// Si Firebase no inicializa, muestra un estado de servicio no disponible con
/// reintento. Nunca carga datos de relleno.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key, required this.builder});

  final Widget Function(AppServices services) builder;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<AppServices?> _future = _initialize();

  Future<AppServices?> _initialize() async {
    final status = await FirebaseBootstrap.initialize();
    if (status != BackendStatus.available) return null;
    final services = AppServices.create();
    await services.start();
    return services;
  }

  void _retry() {
    setState(() => _future = _initialize());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppServices?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingScreen();
        }
        final services = snapshot.data;
        if (services == null || snapshot.hasError) {
          return _UnavailableScreen(
            error: FirebaseBootstrap.lastError,
            onRetry: _retry,
          );
        }
        return widget.builder(services);
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Brand.signMaroon,
      body: Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Brand.ovenOrange,
          ),
        ),
      ),
    );
  }
}

class _UnavailableScreen extends StatelessWidget {
  const _UnavailableScreen({required this.onRetry, this.error});

  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Brand.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 56,
                  color: Brand.ovenOrange,
                ),
                const SizedBox(height: Brand.s16),
                Text(
                  'SERVICIO NO DISPONIBLE',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: Brand.s8),
                Text(
                  'No pudimos conectar con la carta de TOTO\'S. Revisa tu '
                  'conexión e inténtalo de nuevo.',
                  textAlign: TextAlign.center,
                  style: context.text.bodySm.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: Brand.s24),
                PillButton(
                  label: 'REINTENTAR',
                  onPressed: onRetry,
                  showArrow: true,
                ),
                if (error != null) ...[
                  const SizedBox(height: Brand.s24),
                  Text(
                    'Diagnóstico: ${error.runtimeType}',
                    textAlign: TextAlign.center,
                    style: context.text.caption.copyWith(
                      color: context.colors.textDisabled,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
