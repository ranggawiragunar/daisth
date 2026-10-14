import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/app_settings/domain/models/app_settings.dart';
import '../core/design_system/components/daisth_notice.dart';
import '../core/design_system/components/daisth_notice_controller.dart';
import '../core/design_system/theme/daisth_theme.dart';
import '../core/location/domain/repositories/location_repository.dart';
import '../core/localization/daisth_localizations.dart';
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
  AppLanguagePreference _languagePreference = AppLanguagePreference.system;
  Locale _effectiveLocale = const Locale('en');
  List<Locale> _systemLocales = const [];
  bool _localeReady = false;
  late final DaisthNoticeController _noticeController;
  late final GoRouter _router;
  late final AppDependencies _dependencies;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _systemLocales = WidgetsBinding.instance.platformDispatcher.locales;
    _noticeController = DaisthNoticeController();
    _dependencies =
        widget.dependencies ??
        AppDependencies(
          languageCode: AppLanguagePreferenceResolver.resolveCode(
            AppLanguagePreference.system,
            _systemLocales.map((locale) => locale.languageCode),
          ),
          locationRepository: widget.locationRepository,
          startTodayClock: widget.startTodayClock,
        );
    _router = createAppRouter(
      noticeController: _noticeController,
      dependencies: _dependencies,
    );
    unawaited(_loadLocalPreferences());
    unawaited(_initializeDependencies());
  }

  Future<void> _loadLocalPreferences() async {
    try {
      final settings = await _dependencies.appSettingsRepository.getSettings();
      _dependencies.appSettings = settings;
      _languagePreference = settings.languagePreference;
      _themeMode = _toThemeMode(settings.themePreference);
    } catch (_) {
      _languagePreference = AppLanguagePreference.system;
    }
    _effectiveLocale = _resolveLocale();
    _dependencies.updateLanguageCode(_effectiveLocale.languageCode);
    if (!mounted) return;
    setState(() => _localeReady = true);
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

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    _systemLocales =
        locales ?? WidgetsBinding.instance.platformDispatcher.locales;
    if (_languagePreference != AppLanguagePreference.system) return;
    final locale = _resolveLocale();
    if (locale == _effectiveLocale) return;
    setState(() => _effectiveLocale = locale);
    _dependencies.updateLanguageCode(locale.languageCode);
  }

  Locale _resolveLocale() => Locale(
    AppLanguagePreferenceResolver.resolveCode(
      _languagePreference,
      _systemLocales.map((locale) => locale.languageCode),
    ),
  );

  void _setLanguagePreference(AppLanguagePreference preference) {
    if (_languagePreference == preference) return;
    setState(() {
      _languagePreference = preference;
      _effectiveLocale = _resolveLocale();
    });
    _dependencies.updateLanguageCode(_effectiveLocale.languageCode);
    unawaited(_persistLanguagePreference(preference));
  }

  Future<void> _persistLanguagePreference(
    AppLanguagePreference preference,
  ) async {
    try {
      final current = await _dependencies.appSettingsRepository.getSettings();
      final updated = current.copyWith(
        languagePreference: preference,
        updatedAt: DateTime.now().toUtc(),
      );
      await _dependencies.appSettingsRepository.saveSettings(updated);
      _dependencies.appSettings = updated;
    } catch (_) {
      if (mounted) {
        _noticeController.show(
          context,
          type: DaisthNoticeType.error,
          title: DaisthLocalizations.text(
            context,
            id: 'Bahasa belum dapat disimpan di perangkat.',
            en: 'Language preference could not be saved on this device.',
          ),
        );
      }
    }
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
          title: DaisthLocalizations.text(
            context,
            id: 'Tema belum dapat disimpan.',
            en: 'Theme preference could not be saved.',
          ),
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
    if (!_localeReady) {
      return ColoredBox(color: DaisthTheme.light.scaffoldBackgroundColor);
    }
    return MaterialApp.router(
      title: 'Daisth',
      debugShowCheckedModeBanner: false,
      locale: _effectiveLocale,
      supportedLocales: DaisthLocalizations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: DaisthTheme.light,
      darkTheme: DaisthTheme.dark,
      themeMode: _themeMode,
      routerConfig: _router,
      builder: (context, child) => AppPreferencesScope(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
        languagePreference: _languagePreference,
        onLanguagePreferenceChanged: _setLanguagePreference,
        child: DaisthNoticeScope(
          controller: _noticeController,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
