import 'package:flutter/material.dart';

import 'app_services.dart';
import '../core/theme/toto_theme.dart';
import 'app_shell.dart';
import 'providers.dart';

/// Aplicación TOTO'S Pizza, solo con tema oscuro.
///
/// `AppScope` envuelve al `MaterialApp` a propósito: los providers tienen que
/// quedar **por encima** del `Navigator` para que las rutas que se abren sobre
/// el shell (perfil, detalle, historial, hoja de confirmación) los encuentren.
class TotosApp extends StatelessWidget {
  const TotosApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: MaterialApp(
        title: "TOTO'S Pizza",
        debugShowCheckedModeBanner: false,
        theme: totoTheme(),
        darkTheme: totoTheme(),
        themeMode: ThemeMode.dark,
        home: const AppShell(),
      ),
    );
  }
}
