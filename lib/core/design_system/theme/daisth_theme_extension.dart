import 'package:flutter/material.dart';

import '../tokens/daisth_colors.dart';

enum RoutineStatus { completed, partial, due, upcoming, unrecorded, notToday }

@immutable
class DaisthThemeExtension extends ThemeExtension<DaisthThemeExtension> {
  const DaisthThemeExtension({
    required this.border,
    required this.divider,
    required this.softSurface,
    required this.warmSurface,
    required this.artMatte,
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
  final Color artMatte;
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

  static const light = DaisthThemeExtension(
    border: DaisthColors.border,
    divider: DaisthColors.divider,
    softSurface: DaisthColors.primary50,
    warmSurface: DaisthColors.accent100,
    artMatte: Color(0xFFFAF6EE),
    completed: DaisthColors.primary700,
    partial: DaisthColors.accent700,
    due: DaisthColors.primary800,
    upcoming: DaisthColors.textSecondary,
    unrecorded: DaisthColors.textTertiary,
    notToday: DaisthColors.textTertiary,
  );

  static const dark = DaisthThemeExtension(
    border: DaisthColors.darkBorder,
    divider: DaisthColors.darkDivider,
    softSurface: Color(0xFF24342D),
    warmSurface: Color(0xFF342B25),
    artMatte: Color(0xFF342F28),
    completed: DaisthColors.darkPrimary,
    partial: DaisthColors.darkAccent,
    due: Color(0xFFA4C4B7),
    upcoming: DaisthColors.darkTextSecondary,
    unrecorded: DaisthColors.darkTextTertiary,
    notToday: DaisthColors.darkTextTertiary,
  );

  @override
  DaisthThemeExtension copyWith({
    Color? border,
    Color? divider,
    Color? softSurface,
    Color? warmSurface,
    Color? artMatte,
    Color? completed,
    Color? partial,
    Color? due,
    Color? upcoming,
    Color? unrecorded,
    Color? notToday,
  }) => DaisthThemeExtension(
    border: border ?? this.border,
    divider: divider ?? this.divider,
    softSurface: softSurface ?? this.softSurface,
    warmSurface: warmSurface ?? this.warmSurface,
    artMatte: artMatte ?? this.artMatte,
    completed: completed ?? this.completed,
    partial: partial ?? this.partial,
    due: due ?? this.due,
    upcoming: upcoming ?? this.upcoming,
    unrecorded: unrecorded ?? this.unrecorded,
    notToday: notToday ?? this.notToday,
  );

  @override
  DaisthThemeExtension lerp(
    covariant ThemeExtension<DaisthThemeExtension>? other,
    double t,
  ) {
    if (other is! DaisthThemeExtension) return this;
    return DaisthThemeExtension(
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      warmSurface: Color.lerp(warmSurface, other.warmSurface, t)!,
      artMatte: Color.lerp(artMatte, other.artMatte, t)!,
      completed: Color.lerp(completed, other.completed, t)!,
      partial: Color.lerp(partial, other.partial, t)!,
      due: Color.lerp(due, other.due, t)!,
      upcoming: Color.lerp(upcoming, other.upcoming, t)!,
      unrecorded: Color.lerp(unrecorded, other.unrecorded, t)!,
      notToday: Color.lerp(notToday, other.notToday, t)!,
    );
  }
}
