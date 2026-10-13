import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_settings/domain/models/app_settings.dart';
import '../core/design_system/components/daisth_notice.dart';
import '../core/design_system/components/daisth_notice_controller.dart';
import '../core/design_system/theme/daisth_theme.dart';
import '../core/location/domain/repositories/location_repository.dart';
import '../features/reminders/domain/models/reminder_action.dart';
import '../features/reminders/domain/models/reminder_payload.dart';
import 'app_preferences_scope.dart';
import 'dependencies/app_dependencies.dart';
import 'router/app_router.dart';
import 'router/reminder_notification_route_resolver.dart';

class DaisthApp extends StatefulWidget {
  const DaisthApp({
    this.startTodayClock = true,
    this.locationRepository,
    this.dependencies,
    super.key,
  });

  final bool startTodayClock;
  final LocationRepository? locationRepository;
  final AppDependencies? dependencies;

  @override
  State<DaisthApp> createState() => _DaisthAppState();
}

class _DaisthAppState extends State<DaisthApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;
  late final DaisthNoticeController _noticeController;
  late final GoRouter _router;
  late final AppDependencies _dependencies;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _noticeController = DaisthNoticeController();
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
    if (payload == null) return;
    final separator = payload.indexOf('|');
    if (separator > 0) {
      final action = ReminderActionIds.parse(payload.substring(0, separator));
      final encoded = payload.substring(separator + 1);
      final parsed = ReminderPayload.tryParse(encoded);
      if (parsed != null && action != null && action != ReminderAction.open) {
        unawaited(_dispatchForegroundReminderAction(action, parsed));
        return;
      }
      payload = encoded;
    }
    final destination = ReminderNotificationRouteResolver(
      _dependencies.reminderMapper,
    ).resolve(payload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _router.go(destination);
    });
  }

  Future<void> _dispatchForegroundReminderAction(
    ReminderAction action,
    ReminderPayload payload,
  ) async {
    try {
      await _dependencies.handleReminderAction(
        action: action,
        payload: payload,
      );
    } catch (error) {
      _dependencies.initializationError ??= error;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_dependencies.onAppResumed());
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
          type: DaisthNoticeType.error,
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
      title: 'Daisth',
      debugShowCheckedModeBanner: false,
      theme: DaisthTheme.light,
      darkTheme: DaisthTheme.dark,
      themeMode: _themeMode,
      routerConfig: _router,
      builder: (context, child) => AppPreferencesScope(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
        child: DaisthNoticeScope(
          controller: _noticeController,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
