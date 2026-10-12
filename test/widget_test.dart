import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/app/app.dart';
import 'package:istiqam/core/design_system/components/istiqam_notice.dart';
import 'package:istiqam/features/routines/presentation/routine_detail_screen.dart';

void main() {
  testWidgets('Today is the initial destination and navigation works', (
    tester,
  ) async {
    await tester.pumpWidget(const IstiqamApp());

    expect(find.text("Assalamu'alaikum"), findsOneWidget);
    expect(find.text('3 of 7 routines recorded'), findsOneWidget);
    expect(find.text('Sholat Zuhur'), findsNWidgets(2));

    await tester.ensureVisible(find.text('Open Routine'));
    await tester.tap(find.text('Open Routine'));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineDetailScreen), findsOneWidget);
    expect(find.text('Rangkaian'), findsOneWidget);
    expect(find.byKey(const ValueKey('navigation-today')), findsNothing);

    await tester.tap(find.text('Mark Zuhur Done'));
    await tester.pumpAndSettle();
    expect(find.text('Zuhur recorded'), findsOneWidget);
    expect(find.byType(IstiqamNotice), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.byTooltip('Dismiss notification'));
    await tester.pumpAndSettle();
    expect(find.byType(IstiqamNotice), findsNothing);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('navigation-history')));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada history'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-today')));
    await tester.pumpAndSettle();
    expect(find.text('Open Routine'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('navigation-history')));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada history'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-routines')));
    await tester.pumpAndSettle();
    expect(find.text('Routine-mu akan ada di sini'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan segera hadir'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-today')));
    await tester.pumpAndSettle();
    expect(find.text('Open Routine'), findsOneWidget);
  });

  testWidgets('Appearance selector changes the app ThemeMode', (tester) async {
    await tester.pumpWidget(const IstiqamApp());

    await tester.tap(find.byKey(const ValueKey('navigation-settings')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dark'));
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.dark,
    );
    expect(find.byKey(const ValueKey('navigation-settings')), findsOneWidget);
    final darkSettingsPill =
        tester
                .widget<AnimatedContainer>(
                  find.byKey(const ValueKey('navigation-label-settings')),
                )
                .decoration!
            as BoxDecoration;
    expect(
      darkSettingsPill.color,
      Theme.of(
        tester.element(find.text('Appearance')),
      ).colorScheme.primaryContainer,
    );
    expect(tester.widget<Text>(find.text('System')).style?.fontSize, 12);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    expect(find.byKey(const ValueKey('navigation-settings')), findsOneWidget);

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
  });

  testWidgets('navigation and Settings fit a compact phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const IstiqamApp());
    await tester.pumpAndSettle();
    final compactWidthException = tester.takeException();
    expect(compactWidthException, isNull, reason: '$compactWidthException');

    for (final destination in ['History', 'Routines', 'Settings', 'Today']) {
      await tester.tap(
        find.byKey(ValueKey('navigation-${destination.toLowerCase()}')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('selected navigation treatment is a label pill', (tester) async {
    await tester.pumpWidget(const IstiqamApp());

    final todayLabel = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('navigation-label-today')),
    );
    final todayDecoration = todayLabel.decoration! as BoxDecoration;
    expect(
      todayDecoration.color,
      Theme.of(
        tester.element(find.text('Assalamu\'alaikum')),
      ).colorScheme.primaryContainer,
    );
    expect(todayDecoration.borderRadius, BorderRadius.circular(999));
    expect(
      tester
          .widget<Icon>(find.byKey(const ValueKey('navigation-icon-today')))
          .size,
      20,
    );
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('navigation-label-today')),
              matching: find.text('Today'),
            ),
          )
          .style
          ?.fontSize,
      10.5,
    );

    await tester.tap(find.byKey(const ValueKey('navigation-history')));
    await tester.pumpAndSettle();
    final historyDecoration =
        tester
                .widget<AnimatedContainer>(
                  find.byKey(const ValueKey('navigation-label-history')),
                )
                .decoration!
            as BoxDecoration;
    final inactiveTodayDecoration =
        tester
                .widget<AnimatedContainer>(
                  find.byKey(const ValueKey('navigation-label-today')),
                )
                .decoration!
            as BoxDecoration;
    expect(
      historyDecoration.color,
      Theme.of(
        tester.element(find.text('Belum ada history')),
      ).colorScheme.primaryContainer,
    );
    expect(inactiveTodayDecoration.color, Colors.transparent);
  });
}
