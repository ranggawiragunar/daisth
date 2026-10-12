import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/app/app.dart';
import 'package:istiqam/core/design_system/components/istiqam_notice.dart';

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

    expect(find.text('Routine detail segera hadir'), findsOneWidget);
    expect(find.byType(IstiqamNotice), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.byTooltip('Dismiss notification'));
    await tester.pumpAndSettle();
    expect(find.byType(IstiqamNotice), findsNothing);

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

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );

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
}
