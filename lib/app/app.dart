import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_settings/domain/models/app_settings.dart';
import '../core/design_system/components/istiqam_notice.dart';
import '../core/design_system/components/istiqam_notice_controller.dart';
import '../core/design_system/theme/istiqam_theme.dart';
import '../core/location/domain/repositories/location_repository.dart';
import 'app_preferences_scope.dart';
import 'dependencies/app_dependencies.dart';
import 'router/app_router.dart';
import 'router/reminder_notification_route_resolver.dart';

class IstiqamApp extends StatefulWidget {
  const IstiqamApp({
    this.startTodayClock = true,
    this.locationRepository,
    this.dependencies,
    super.key,
  });

  final bool startTodayClock;
  final LocationRepository? locationRepository;
  final AppDependencies? dependencies;

  @override
  State<IstiqamApp> createState() => _IstiqamAppState();
}

class _IstiqamAppState extends State<IstiqamApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;
  late final IstiqamNoticeController _noticeController;
  late final GoRouter _router;
  late final AppDependencies _dependencies;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _noticeController = IstiqamNoticeController();
    _dependencies =
        widget.dependencies ??
        AppDependencies(
          locationRepository: widget.locationRepository,
          startTodayClock: widget.startTodayClock,
        );
    _router = createAppRouter(
      noticeController: _noticeController,
      dependencies: _dependencies,
    );
    unawaited(_initializeDependencies());
  }

  Future<void> _initializeDependencies() async {
    await _dependencies.initialize(
      onNotificationTap: _onReminderNotificationTap,
    );
    if (!mounted) return;
    setState(() {
      _themeMode = _toThemeMode(_dependencies.appSettings.themePreference);
    });
  }

  void _onReminderNotificationTap(String? payload) {
    final destination = ReminderNotificationRouteResolver(
      _dependencies.reminderMapper,
    ).resolve(payload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _router.go(destination);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_dependencies.reminderSettings.onAppResumed());
    }
  }

  void _setThemeMode(ThemeMode themeMode) {
    if (themeMode == _themeMode) return;
    setState(() => _themeMode = themeMode);
    unawaited(_persistThemeMode(themeMode));
  }

  Future<void> _persistThemeMode(ThemeMode mode) async {
    final preference = switch (mode) {
      ThemeMode.light => AppThemePreference.light,
      ThemeMode.dark => AppThemePreference.dark,
      ThemeMode.system => AppThemePreference.system,
    };
    try {
      await _dependencies.setThemePreference(preference);
    } catch (error) {
      _dependencies.initializationError ??= error;
      if (mounted) {
        _noticeController.show(
          context,
          type: IstiqamNoticeType.error,
          title: 'Tema belum dapat disimpan.',
        );
      }
    }
  }

  ThemeMode _toThemeMode(AppThemePreference preference) => switch (preference) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
