import 'package:flutter/material.dart';

import '../core/design_system/theme/istiqam_theme.dart';
import 'app_shell.dart';

class IstiqamApp extends StatefulWidget {
  const IstiqamApp({super.key});

  @override
  State<IstiqamApp> createState() => _IstiqamAppState();
}

class _IstiqamAppState extends State<IstiqamApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _setThemeMode(ThemeMode themeMode) {
    if (themeMode == _themeMode) return;
    setState(() => _themeMode = themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Istiqam',
      debugShowCheckedModeBanner: false,
      theme: IstiqamTheme.light,
      darkTheme: IstiqamTheme.dark,
      themeMode: _themeMode,
      home: AppShell(themeMode: _themeMode, onThemeModeChanged: _setThemeMode),
    );
  }
}
