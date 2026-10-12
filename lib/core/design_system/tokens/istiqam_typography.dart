import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class IstiqamTypography {
  static const fontFamily = 'Plus Jakarta Sans';

  // Reserved for a future Arabic reader typeface decision.
  static const arabicReaderFontFamily = null;

  static TextStyle _font(TextStyle style) =>
      GoogleFonts.plusJakartaSans(textStyle: style);

  static final displayLarge = _font(
    const TextStyle(fontSize: 32, height: 40 / 32, fontWeight: FontWeight.w600),
  );
  static final displaySmall = _font(
    const TextStyle(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w600),
  );
  static final titleLarge = _font(
    const TextStyle(fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w600),
  );
  static final titleMedium = _font(
    const TextStyle(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600),
  );
  static final titleSmall = _font(
    const TextStyle(fontSize: 16, height: 22 / 16, fontWeight: FontWeight.w600),
  );
  static final bodyLarge = _font(
    const TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400),
  );
  static final bodyMedium = _font(
    const TextStyle(fontSize: 14, height: 21 / 14, fontWeight: FontWeight.w400),
  );
  static final bodySmall = _font(
    const TextStyle(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w400),
  );
  static final labelLarge = _font(
    const TextStyle(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w600),
  );
  static final labelMedium = _font(
    const TextStyle(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w500),
  );
  static final labelSmall = _font(
    const TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500),
  );

  static final textTheme = TextTheme(
    displayLarge: displayLarge,
    displaySmall: displaySmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
