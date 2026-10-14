import 'package:flutter/widgets.dart';

abstract final class DaisthLocalizations {
  static const supportedLocales = [Locale('id'), Locale('en')];

  static bool isEnglish(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'en';

  static String text(
    BuildContext context, {
    required String id,
    required String en,
  }) => isEnglish(context) ? en : id;
}
