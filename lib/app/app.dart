import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system/components/istiqam_notice_controller.dart';
import '../core/design_system/theme/istiqam_theme.dart';
import 'app_preferences_scope.dart';
import 'dependencies/app_dependencies.dart';
import 'router/app_router.dart';

class IstiqamApp extends StatefulWidget {
  const IstiqamApp({super.key});

  @override
  State<IstiqamApp> createState() => _IstiqamAppState();
}

class _IstiqamAppState extends State<IstiqamApp> {
  ThemeMode _themeMode = ThemeMode.system;
  late final IstiqamNoticeController _noticeController;
  late final GoRouter _router;
  late final AppDependencies _dependencies;

  @override
  void initState() {
    super.initState();
    _noticeController = IstiqamNoticeController();
    _dependencies = AppDependencies();
    _router = createAppRouter(
      noticeController: _noticeController,
      dependencies: _dependencies,
    );
  }

  void _setThemeMode(ThemeMode themeMode) {
    if (themeMode == _themeMode) return;
    setState(() => _themeMode = themeMode);
  }

  @override
  void dispose() {
    _router.dispose();
    _dependencies.dispose();
    _noticeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Istiqam',
      debugShowCheckedModeBanner: false,
      theme: IstiqamTheme.light,
      darkTheme: IstiqamTheme.dark,
      themeMode: _themeMode,
      routerConfig: _router,
      builder: (context, child) => AppPreferencesScope(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
        child: IstiqamNoticeScope(
          controller: _noticeController,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
