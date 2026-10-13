import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/app/app.dart';
import 'package:daisth/app/dependencies/app_dependencies.dart';
import 'package:daisth/core/design_system/components/daisth_notice.dart';
import 'package:daisth/features/routines/presentation/routine_detail_screen.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/core/location/domain/models/location_access_status.dart';
import 'package:daisth/core/location/domain/repositories/location_repository.dart';

import 'support/test_persistence.dart';
import 'support/fake_routine_record_repository.dart';

void main() {
  testWidgets('Today is the initial destination and navigation works', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    expect(find.text("Assalamu'alaikum"), findsOneWidget);
    expect(find.text('0 of 7 routines recorded'), findsOneWidget);
    expect(find.text('Sholat Zuhur'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('today-routine-zuhur')),
    );
    await tester.tap(find.byKey(const ValueKey('today-routine-zuhur')));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RoutineDetailScreen), findsOneWidget);
    expect(find.text('Rangkaian'), findsOneWidget);
    expect(find.byKey(const ValueKey('navigation-today')), findsNothing);

    await tester.tap(find.text('Mark Zuhur Done'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Zuhur recorded'), findsOneWidget);
    expect(find.byType(DaisthNotice), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(find.byType(DaisthNotice), findsNothing);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('navigation-history')));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada history'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-today')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-routine-zuhur')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('navigation-history')));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada history'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-routines')));
    await tester.pumpAndSettle();
    expect(find.text('Routine-mu akan ada di sini'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Prayer & Location'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-today')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-routine-zuhur')), findsOneWidget);
  });

  testWidgets('Appearance selector changes the app ThemeMode', (tester) async {
    await tester.pumpWidget(_testApp());

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

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    final compactWidthException = tester.takeException();
    expect(compactWidthException, isNull, reason: '$compactWidthException');

    for (final destination in ['History', 'Routines', 'Settings', 'Today']) {
      await tester.tap(
        find.byKey(ValueKey('navigation-${destination.toLowerCase()}')),
      );
      await tester.pumpAndSettle();
      if (destination == 'Settings') {
        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('Reminders'), findsOneWidget);
        expect(find.text('Timezone'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('selected navigation treatment is a label pill', (tester) async {
    await tester.pumpWidget(_testApp());

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

Widget _testApp() => DaisthApp(
  dependencies: AppDependencies(
    startTodayClock: false,
    locationRepository: _DeniedLocation(),
    routineRecordRepository: FakeRoutineRecordRepository(),
    databaseService: TestPersistence.createDatabaseService(),
  ),
);

class _DeniedLocation implements LocationRepository {
  @override
  Future<LocationAccessStatus> checkAccess() async =>
      LocationAccessStatus.denied;
  @override
  Future<GeoCoordinate> getCurrentLocation() async =>
      throw StateError('permission denied');
  @override
  Future<GeoCoordinate?> getLastKnownLocation() async => null;
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
  @override
  Future<LocationAccessStatus> requestAccess() async =>
      LocationAccessStatus.denied;
}
