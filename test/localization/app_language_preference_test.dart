import 'package:daisth/core/app_settings/domain/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLanguagePreferenceResolver', () {
    test('defaults to Indonesian for an Indonesian system locale', () {
      expect(
        AppLanguagePreferenceResolver.resolveCode(
          AppLanguagePreference.system,
          ['id'],
        ),
        'id',
      );
    });

    test('resolves region codes and the legacy Indonesian code', () {
      expect(
        AppLanguagePreferenceResolver.resolveCode(
          AppLanguagePreference.system,
          ['id-ID'],
        ),
        'id',
      );
      expect(
        AppLanguagePreferenceResolver.resolveCode(
          AppLanguagePreference.system,
          ['in'],
        ),
        'id',
      );
      expect(
        AppLanguagePreferenceResolver.resolveCode(
          AppLanguagePreference.system,
          ['en-US'],
        ),
        'en',
      );
    });

    test('unsupported or missing system locale falls back to English', () {
      for (final locales in [
        <String>['ja-JP'],
        <String>[],
      ]) {
        expect(
          AppLanguagePreferenceResolver.resolveCode(
            AppLanguagePreference.system,
            locales,
          ),
          'en',
        );
      }
    });

    test('manual language preference overrides system locale', () {
      expect(
        AppLanguagePreferenceResolver.resolveCode(
          AppLanguagePreference.indonesian,
          ['en-US'],
        ),
        'id',
      );
      expect(
        AppLanguagePreferenceResolver.resolveCode(
          AppLanguagePreference.english,
          ['id-ID'],
        ),
        'en',
      );
    });
  });
}
