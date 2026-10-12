import 'package:flutter/material.dart';

import '../tokens/istiqam_colors.dart';

enum RoutineStatus { completed, partial, due, upcoming, unrecorded, notToday }

@immutable
class IstiqamThemeExtension extends ThemeExtension<IstiqamThemeExtension> {
  const IstiqamThemeExtension({
    required this.border,
    required this.divider,
    required this.softSurface,
    required this.warmSurface,
    required this.completed,
    required this.partial,
    required this.due,
    required this.upcoming,
    required this.unrecorded,
    required this.notToday,
  });

  final Color border;
  final Color divider;
  final Color softSurface;
  final Color warmSurface;
  final Color completed;
  final Color partial;
  final Color due;
  final Color upcoming;
  final Color unrecorded;
  final Color notToday;

  Color statusColor(RoutineStatus status) => switch (status) {
    RoutineStatus.completed => completed,
    RoutineStatus.partial => partial,
    RoutineStatus.due => due,
    RoutineStatus.upcoming => upcoming,
    RoutineStatus.unrecorded => unrecorded,
    RoutineStatus.notToday => notToday,
  };

  static const light = IstiqamThemeExtension(
    border: IstiqamColors.border,
    divider: IstiqamColors.divider,
    softSurface: IstiqamColors.primary50,
    warmSurface: IstiqamColors.accent100,
    completed: IstiqamColors.primary700,
    partial: IstiqamColors.accent700,
    due: IstiqamColors.primary800,
    upcoming: IstiqamColors.textSecondary,
    unrecorded: IstiqamColors.textTertiary,
    notToday: IstiqamColors.textTertiary,
  );

  static const dark = IstiqamThemeExtension(
    border: IstiqamColors.darkBorder,
    divider: IstiqamColors.darkDivider,
    softSurface: Color(0xFF24342D),
    warmSurface: Color(0xFF342B25),
    completed: IstiqamColors.darkPrimary,
    partial: IstiqamColors.darkAccent,
    due: Color(0xFFA4C4B7),
    upcoming: IstiqamColors.darkTextSecondary,
    unrecorded: IstiqamColors.darkTextTertiary,
    notToday: IstiqamColors.darkTextTertiary,
  );

  @override
  IstiqamThemeExtension copyWith({
    Color? border,
    Color? divider,
    Color? softSurface,
    Color? warmSurface,
    Color? completed,
    Color? partial,
    Color? due,
    Color? upcoming,
    Color? unrecorded,
    Color? notToday,
  }) => IstiqamThemeExtension(
    border: border ?? this.border,
    divider: divider ?? this.divider,
    softSurface: softSurface ?? this.softSurface,
    warmSurface: warmSurface ?? this.warmSurface,
    completed: completed ?? this.completed,
    partial: partial ?? this.partial,
    due: due ?? this.due,
    upcoming: upcoming ?? this.upcoming,
    unrecorded: unrecorded ?? this.unrecorded,
    notToday: notToday ?? this.notToday,
  );

  @override
  IstiqamThemeExtension lerp(
    covariant ThemeExtension<IstiqamThemeExtension>? other,
    double t,
  ) {
    if (other is! IstiqamThemeExtension) return this;
    return IstiqamThemeExtension(
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      warmSurface: Color.lerp(warmSurface, other.warmSurface, t)!,
      completed: Color.lerp(completed, other.completed, t)!,
      partial: Color.lerp(partial, other.partial, t)!,
      due: Color.lerp(due, other.due, t)!,
      upcoming: Color.lerp(upcoming, other.upcoming, t)!,
      unrecorded: Color.lerp(unrecorded, other.unrecorded, t)!,
      notToday: Color.lerp(notToday, other.notToday, t)!,
    );
  }
}
