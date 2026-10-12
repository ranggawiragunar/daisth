import 'package:flutter/material.dart';

import '../core/design_system/theme/istiqam_theme.dart';
import 'app_shell.dart';

class IstiqamApp extends StatelessWidget {
  const IstiqamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Istiqam',
      debugShowCheckedModeBanner: false,
      theme: IstiqamTheme.light,
      darkTheme: IstiqamTheme.dark,
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
