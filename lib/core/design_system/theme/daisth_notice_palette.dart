import 'package:flutter/material.dart';

@immutable
class DaisthNoticePalette extends ThemeExtension<DaisthNoticePalette> {
  const DaisthNoticePalette({
    required this.successSurface,
    required this.successInk,
    required this.infoSurface,
    required this.infoInk,
    required this.warningSurface,
    required this.warningInk,
    required this.errorSurface,
    required this.errorInk,
    required this.neutralSurface,
    required this.neutralInk,
  });

  final Color successSurface;
  final Color successInk;
  final Color infoSurface;
  final Color infoInk;
  final Color warningSurface;
  final Color warningInk;
  final Color errorSurface;
  final Color errorInk;
  final Color neutralSurface;
  final Color neutralInk;

  static const light = DaisthNoticePalette(
    successSurface: Color(0xFFE3ECE8),
    successInk: Color(0xFF294C43),
    infoSurface: Color(0xFFF1F6F4),
    infoInk: Color(0xFF365F53),
    warningSurface: Color(0xFFF1E7DE),
    warningInk: Color(0xFF8A654C),
    errorSurface: Color(0xFFF5E9E5),
    errorInk: Color(0xFF875247),
    neutralSurface: Color(0xFFF1F0EB),
    neutralInk: Color(0xFF666B67),
  );

  static const dark = DaisthNoticePalette(
    successSurface: Color(0xFF294239),
    successInk: Color(0xFFA9CDBD),
    infoSurface: Color(0xFF24342D),
    infoInk: Color(0xFFB7D1C7),
    warningSurface: Color(0xFF3A3028),
    warningInk: Color(0xFFD0AA8C),
    errorSurface: Color(0xFF392B29),
    errorInk: Color(0xFFD7A097),
    neutralSurface: Color(0xFF202B26),
    neutralInk: Color(0xFFB3B8B3),
  );

  @override
  DaisthNoticePalette copyWith({
    Color? successSurface,
    Color? successInk,
    Color? infoSurface,
    Color? infoInk,
    Color? warningSurface,
    Color? warningInk,
    Color? errorSurface,
    Color? errorInk,
    Color? neutralSurface,
    Color? neutralInk,
  }) => DaisthNoticePalette(
    successSurface: successSurface ?? this.successSurface,
    successInk: successInk ?? this.successInk,
    infoSurface: infoSurface ?? this.infoSurface,
    infoInk: infoInk ?? this.infoInk,
    warningSurface: warningSurface ?? this.warningSurface,
    warningInk: warningInk ?? this.warningInk,
    errorSurface: errorSurface ?? this.errorSurface,
    errorInk: errorInk ?? this.errorInk,
    neutralSurface: neutralSurface ?? this.neutralSurface,
    neutralInk: neutralInk ?? this.neutralInk,
  );

  @override
  DaisthNoticePalette lerp(
    covariant ThemeExtension<DaisthNoticePalette>? other,
    double t,
  ) {
    if (other is! DaisthNoticePalette) return this;
    return DaisthNoticePalette(
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      successInk: Color.lerp(successInk, other.successInk, t)!,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t)!,
      infoInk: Color.lerp(infoInk, other.infoInk, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      warningInk: Color.lerp(warningInk, other.warningInk, t)!,
      errorSurface: Color.lerp(errorSurface, other.errorSurface, t)!,
      errorInk: Color.lerp(errorInk, other.errorInk, t)!,
      neutralSurface: Color.lerp(neutralSurface, other.neutralSurface, t)!,
      neutralInk: Color.lerp(neutralInk, other.neutralInk, t)!,
    );
  }
}
