import 'package:flutter/material.dart';

abstract final class ReaderTypography {
  static TextStyle arabic(BuildContext context, double scale) => TextStyle(
    fontFamilyFallback: const [
      'Noto Naskh Arabic',
      'Noto Sans Arabic',
      'Geeza Pro',
      'serif',
    ],
    fontSize: 32 * scale,
    height: 1.9,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );
}
