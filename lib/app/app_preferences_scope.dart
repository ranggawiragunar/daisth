import 'package:flutter/material.dart';

import '../core/app_settings/domain/models/app_settings.dart';

class AppPreferencesScope extends InheritedWidget {
  const AppPreferencesScope({
    required this.themeMode,
    required this.onThemeModeChanged,
    this.languagePreference = AppLanguagePreference.system,
    this.onLanguagePreferenceChanged,
    required super.child,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final AppLanguagePreference languagePreference;
  final ValueChanged<AppLanguagePreference>? onLanguagePreferenceChanged;

  static AppPreferencesScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppPreferencesScope>()!;

  @override
  bool updateShouldNotify(AppPreferencesScope oldWidget) =>
      themeMode != oldWidget.themeMode ||
      languagePreference != oldWidget.languagePreference ||
      onThemeModeChanged != oldWidget.onThemeModeChanged ||
      onLanguagePreferenceChanged != oldWidget.onLanguagePreferenceChanged;
}
