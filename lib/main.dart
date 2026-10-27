import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_services.dart';
import 'app/bootstrap.dart';
import 'core/theme/brand.dart';
import 'core/theme/toto_theme.dart';

/// Arranque: Firebase → repositorios → controladores → `runApp`.
///
/// Si Firebase no está disponible se muestra la pantalla de servicio no
/// disponible con reintento, sin cargar datos de relleno.
///
/// El `MaterialApp` raíz usa el tema oscuro de la app y un fondo vino de
/// seguridad: así la pantalla de carga, la de servicio no disponible y las
/// barras del sistema no heredan el tema claro de Android antes de que
/// `TotosApp` tome el control.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "TOTO'S Pizza",
      theme: totoTheme(),
      darkTheme: totoTheme(),
      themeMode: ThemeMode.dark,
      home: const ColoredBox(
        color: Brand.signMaroon,
        child: AppBootstrap(builder: _buildApp),
      ),
    ),
  );
}

Widget _buildApp(AppServices services) => TotosApp(services: services);
