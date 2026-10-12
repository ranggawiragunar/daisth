import 'package:flutter/material.dart';

class AppPreferencesScope extends InheritedWidget {
  const AppPreferencesScope({
    required this.themeMode,
    required this.onThemeModeChanged,
    required super.child,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  static AppPreferencesScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppPreferencesScope>()!;

  @override
  bool updateShouldNotify(AppPreferencesScope oldWidget) =>
      themeMode != oldWidget.themeMode ||
      onThemeModeChanged != oldWidget.onThemeModeChanged;
}
