import 'package:daisth/core/app_settings/domain/models/app_settings.dart';
import 'package:daisth/core/design_system/theme/daisth_theme.dart';
import 'package:daisth/core/localization/daisth_localizations.dart';
import 'package:daisth/features/settings/presentation/settings_placeholder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'language selector switches the visible Settings UI immediately',
    (tester) async {
      var preference = AppLanguagePreference.system;
      var locale = const Locale('id');

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            locale: locale,
            supportedLocales: DaisthLocalizations.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: DaisthTheme.light,
            home: Scaffold(
              body: SettingsPlaceholderScreen(
                themeMode: ThemeMode.system,
                onThemeModeChanged: (_) {},
                languagePreference: preference,
                onLanguagePreferenceChanged: (next) => setState(() {
                  preference = next;
                  locale = switch (next) {
                    AppLanguagePreference.system => const Locale('id'),
                    AppLanguagePreference.indonesian => const Locale('id'),
                    AppLanguagePreference.english => const Locale('en'),
                  };
                }),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Ikuti Sistem'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('settings-language')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('language-option-system')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('language-option-indonesian')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('language-option-english')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('language-option-english')));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('settings-language')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('language-option-indonesian')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Indonesia'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('settings-language')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-option-system')));
      await tester.pumpAndSettle();
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Ikuti Sistem'), findsOneWidget);
    },
  );
}
