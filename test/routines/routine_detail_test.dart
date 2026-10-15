import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:daisth/core/design_system/components/daisth_notice_controller.dart';
import 'package:daisth/core/design_system/theme/daisth_theme.dart';
import 'package:daisth/core/time/domain/models/calendar_day.dart';
import 'package:daisth/app/dependencies/app_dependencies.dart';
import 'package:daisth/core/location/domain/models/geo_coordinate.dart';
import 'package:daisth/core/location/domain/models/location_access_status.dart';
import 'package:daisth/core/location/domain/repositories/location_repository.dart';
import 'package:daisth/features/dhikr/data/demo/dhikr_demo_data.dart';
import 'package:daisth/features/routines/data/demo/routine_demo_data.dart';
import 'package:daisth/features/routines/domain/models/routine.dart';
import 'package:daisth/features/routines/domain/models/routine_content.dart';
import 'package:daisth/features/routines/domain/use_cases/mark_routine_complete_use_case.dart';
import 'package:daisth/features/routines/domain/use_cases/mark_routine_not_today_use_case.dart';
import 'package:daisth/features/routines/domain/use_cases/resolve_routine_status_use_case.dart';
import 'package:daisth/features/routines/domain/use_cases/set_routine_step_completion_use_case.dart';
import 'package:daisth/features/routines/presentation/routine_detail_screen.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_day_schedule.dart';
import 'package:daisth/features/prayer_times/domain/models/prayer_calculation_settings.dart';
import 'package:daisth/features/prayer_times/presentation/prayer_schedule_session.dart';
import 'package:daisth/features/today/presentation/today_screen.dart';

import '../support/fake_routine_record_repository.dart';
import '../support/test_persistence.dart';

void main() {
  testWidgets('Routine Detail renders Notes loaded after the first frame', (
    tester,
  ) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    final routine = RoutineDemoData.sholatMalam;

    await _pumpRoutine(tester, routine, controller);
    expect(find.text('Notes'), findsNothing);

    await _pumpRoutine(
      tester,
      routine,
      controller,
      userContent: RoutineContent(
        routineId: routine.id,
        serializedDelta: '[{"insert":"Loaded QA notes\\n"}]',
        plainText: 'Loaded QA notes',
        formatVersion: 1,
        createdAt: DateTime.utc(2026, 10, 15),
        updatedAt: DateTime.utc(2026, 10, 15),
      ),
    );

    expect(find.text('Notes'), findsOneWidget);
    await tester.ensureVisible(find.text('Notes'));
    await _settle(tester);
    final notesEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    expect(notesEditor.controller.document.toPlainText(), 'Loaded QA notes\n');
  });

  testWidgets('Night Prayer tracks partial progress, completion, and undo', (
    tester,
  ) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(tester, RoutineDemoData.sholatMalam, controller);

    expect(find.text('Not started'), findsOneWidget);
    expect(find.text('Mark All Done'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('routine-step-toggle-hajat')),
    );
    await tester.tap(find.byKey(const ValueKey('routine-step-toggle-hajat')));
    await _settle(tester);
    expect(find.text('Partial · 1 of 4'), findsOneWidget);

    await tester.tap(find.text('Mark Remaining Done'));
    await _settle(tester);
    expect(find.text('Completed · 4 of 4'), findsOneWidget);
    expect(find.text('Night Prayer recorded'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    await _dismissNotice(tester, controller);

    await tester.ensureVisible(
      find.byKey(const ValueKey('routine-step-toggle-hajat')),
    );
    await tester.tap(find.byKey(const ValueKey('routine-step-toggle-hajat')));
    await _settle(tester);
    expect(find.text('Partial · 3 of 4'), findsOneWidget);
  });

  testWidgets('Dhuha completes at its minimum while extra remains optional', (
    tester,
  ) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(tester, RoutineDemoData.dhuha, controller);

    expect(find.text('Partial'), findsNothing);
    expect(find.text('Not Today'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('routine-step-toggle-dhuha-minimum')),
    );
    await _settle(tester);

    expect(find.text('Completed · 2 rakaat'), findsOneWidget);
    expect(find.text('Partial'), findsNothing);
    expect(find.text('Additional 2 rakaat'), findsOneWidget);
    expect(find.text('Not Today'), findsOneWidget);
    expect(find.text('Mark Remaining Done'), findsOneWidget);
    await _dismissNotice(tester, controller);

    await tester.tap(find.text('Mark Remaining Done'));
    await _settle(tester);
    expect(find.text('Completed · 4 rakaat'), findsOneWidget);
    await _dismissNotice(tester, controller);
    await _dismissNotice(tester, controller);
  });

  testWidgets('Dhuha guidance title follows the selected locale', (
    tester,
  ) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(
      tester,
      RoutineDemoData.dhuha,
      controller,
      locale: const Locale('en'),
    );

    await tester.tap(find.text('2 rakaat'));
    await _settle(tester);

    expect(find.text('Duha Prayer Guide'), findsWidgets);
    expect(find.text('Panduan Sholat Dhuha'), findsNothing);
  });

  testWidgets('optional routine can be marked Not Today without a reason', (
    tester,
  ) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(tester, RoutineDemoData.dhuha, controller);

    await tester.tap(find.text('Not Today'));
    await _settle(tester);
    expect(find.text('Not today?'), findsOneWidget);
    final saveButton = find.text('Save');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await _settle(tester);

    expect(find.text('Not today'), findsOneWidget);
    expect(find.text('Routine status updated'), findsOneWidget);
    await _dismissNotice(tester, controller);
  });

  testWidgets('Not Today saves a selected reason in this detail session', (
    tester,
  ) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(tester, RoutineDemoData.sholatMalam, controller);

    await tester.tap(find.text('Not Today'));
    await _settle(tester);
    await tester.tap(find.text('Travelling'));
    await tester.tap(find.text('Save'));
    await _settle(tester);

    expect(find.text('Reason: Travelling'), findsOneWidget);
    await _dismissNotice(tester, controller);
  });

  testWidgets('mandatory Zuhur completes and has no Not Today action', (
    tester,
  ) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(tester, RoutineDemoData.zuhur, controller);

    expect(find.text('Not Today'), findsNothing);
    expect(find.text('Nearby Masjid & Mushola'), findsOneWidget);
    expect(find.text('Zikir after prayer'), findsOneWidget);

    await tester.tap(find.text('Mark Dhuhr Done'));
    await _settle(tester);
    expect(find.text('Recorded just now'), findsOneWidget);
    expect(find.text('Dhuhr recorded'), findsOneWidget);
    expect(find.text('Mark Dhuhr Done'), findsNothing);
    await _dismissNotice(tester, controller);
  });

  testWidgets('all five mandatory prayer details use calculated times', (
    tester,
  ) async {
    final controller = DaisthNoticeController();
    final dependencies = AppDependencies(
      locationRepository: _TestLocation(),
      databaseService: TestPersistence.createDatabaseService(),
    );
    addTearDown(controller.dispose);
    addTearDown(dependencies.dispose);
    final day = DateTime(2026, 10, 10);
    dependencies.prayerScheduleSession.schedule = PrayerDaySchedule(
      date: day,
      coordinate: const GeoCoordinate(latitude: -6.2, longitude: 106.8),
      fajr: day.add(const Duration(hours: 4, minutes: 16)),
      sunrise: day.add(const Duration(hours: 5, minutes: 30)),
      dhuhr: day.add(const Duration(hours: 11, minutes: 41)),
      asr: day.add(const Duration(hours: 14, minutes: 42)),
      maghrib: day.add(const Duration(hours: 17, minutes: 46)),
      isha: day.add(const Duration(hours: 18, minutes: 56)),
      calculationSettings: PrayerCalculationSettings.defaultSettings,
    );
    final cases = [
      (RoutineDemoData.subuh, '04:16', 'Mark Fajr Done'),
      (RoutineDemoData.zuhur, '11:41', 'Mark Dhuhr Done'),
      (RoutineDemoData.asar, '14:42', 'Mark Asr Done'),
      (RoutineDemoData.maghrib, '17:46', 'Mark Maghrib Done'),
      (RoutineDemoData.isya, '18:56', 'Mark Isha Done'),
    ];

    for (final (routine, time, completeLabel) in cases) {
      await _pumpRoutine(
        tester,
        routine,
        controller,
        prayerScheduleSession: dependencies.prayerScheduleSession,
      );
      expect(find.text(time), findsOneWidget);
      expect(find.text(completeLabel), findsOneWidget);
      expect(find.text('Not Today'), findsNothing);
      expect(find.text('Nearby Masjid & Mushola'), findsOneWidget);
      expect(find.text('Zikir after prayer'), findsOneWidget);
      expect(find.text('Available after prayer'), findsOneWidget);
    }

    for (final id in ['subuh', 'zuhur', 'asar', 'maghrib', 'isya']) {
      expect(
        DhikrDemoData.byRoute(id, 'post-prayer'),
        same(DhikrDemoData.postPrayer),
      );
    }
  });

  testWidgets('Today timeline opens the Malam and Dhuha demos', (tester) async {
    final repository = FakeRoutineRecordRepository();
    final noticeController = DaisthNoticeController();
    final dependencies = AppDependencies(
      databaseService: TestPersistence.createDatabaseService(),
      locationRepository: _TestLocation(access: LocationAccessStatus.denied),
      routineRecordRepository: repository,
      startTodayClock: false,
    );
    final session = dependencies.prayerScheduleSession;
    addTearDown(noticeController.dispose);
    addTearDown(dependencies.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: DaisthTheme.light,
        home: Builder(
          builder: (context) => TodayScreen(
            prayerScheduleSession: session,
            routineRecordRepository: repository,
            startClock: false,
            onRoutineTap: (id) {
              final routine = RoutineDemoData.byId(id);
              if (routine == null) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RoutineDetailScreen(
                    routine: routine,
                    noticeController: noticeController,
                    routineRecordRepository: repository,
                    setRoutineStepCompletion: SetRoutineStepCompletionUseCase(
                      repository: repository,
                    ),
                    markRoutineComplete: MarkRoutineCompleteUseCase(
                      repository: repository,
                      resolveStatus: const ResolveRoutineStatusUseCase(),
                    ),
                    markRoutineNotToday: MarkRoutineNotTodayUseCase(repository),
                    prayerScheduleSession: session,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await _settle(tester);

    await tester.ensureVisible(find.text('Night Prayer'));
    await tester.tap(find.text('Night Prayer'));
    await _settle(tester);
    expect(find.text('Not started'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await _settle(tester);

    await tester.ensureVisible(find.text('Duha'));
    await tester.tap(find.text('Duha'));
    await _settle(tester);
    expect(find.text('Not started'), findsOneWidget);
    expect(find.text('Duha'), findsOneWidget);
    expect(find.text('2 rakaat'), findsOneWidget);
  });

  testWidgets('Night Prayer has only Taubat and Hajat reading actions', (
    tester,
  ) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(tester, RoutineDemoData.sholatMalam, controller);

    expect(find.text('Zikir & Sholawat Readings'), findsOneWidget);
    expect(find.text('After Taubat Prayer'), findsOneWidget);
    expect(find.text('After Hajat Prayer'), findsOneWidget);
    expect(find.text('Doa setelah Tahajud'), findsNothing);
    expect(find.text('Panduan Witir'), findsNothing);
    expect(find.text('Doa Sebelum Tidur'), findsNothing);
    expect(find.text('Tahajud'), findsOneWidget);
    expect(find.text('Witir'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('routine-link-After Taubat Prayer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('routine-link-After Hajat Prayer')),
      findsOneWidget,
    );
  });

  testWidgets('detail page builds in light and dark at compact width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);

    await _pumpRoutine(
      tester,
      RoutineDemoData.sholatMalam,
      controller,
      dark: false,
    );
    expect(tester.takeException(), isNull);

    await _pumpRoutine(
      tester,
      RoutineDemoData.sholatMalam,
      controller,
      dark: true,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('built-in Night Prayer detail localizes its routine content', (
    tester,
  ) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(
      tester,
      RoutineDemoData.sholatMalam,
      controller,
      locale: const Locale('en'),
    );

    expect(
      find.text('Complete the night prayer sequence before Fajr time.'),
      findsOneWidget,
    );
    expect(find.text('Taubat prayer'), findsOneWidget);
    expect(find.text('Hajat prayer'), findsOneWidget);
    expect(find.text('Routine steps'), findsOneWidget);
    expect(find.text('Sholat Taubat'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('historical routine context follows the selected locale', (
    tester,
  ) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(
      tester,
      RoutineDemoData.zuhur,
      controller,
      locale: const Locale('id'),
      historical: true,
      calendarDay: const CalendarDay(year: 2026, month: 10, day: 12),
    );

    expect(find.textContaining('Mengedit'), findsOneWidget);
    expect(find.textContaining('Editing'), findsNothing);
    expect(find.text('Rangkaian'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpRoutine(
  WidgetTester tester,
  Routine data,
  DaisthNoticeController controller, {
  bool dark = false,
  PrayerScheduleSession? prayerScheduleSession,
  Locale? locale,
  bool historical = false,
  CalendarDay? calendarDay,
  RoutineContent? userContent,
}) async {
  final repository = FakeRoutineRecordRepository();
  final resolveStatus = const ResolveRoutineStatusUseCase();
  await tester.pumpWidget(
    MaterialApp(
      theme: DaisthTheme.light,
      darkTheme: DaisthTheme.dark,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: RoutineDetailScreen(
        key: ValueKey('test-routine-${data.id}'),
        routine: data,
        noticeController: controller,
        routineRecordRepository: repository,
        setRoutineStepCompletion: SetRoutineStepCompletionUseCase(
          repository: repository,
        ),
        markRoutineComplete: MarkRoutineCompleteUseCase(
          repository: repository,
          resolveStatus: resolveStatus,
        ),
        markRoutineNotToday: MarkRoutineNotTodayUseCase(repository),
        prayerScheduleSession: prayerScheduleSession,
        historical: historical,
        calendarDay: calendarDay,
        userContent: userContent,
      ),
    ),
  );
  await _settle(tester);
}

class _TestLocation implements LocationRepository {
  _TestLocation({this.access = LocationAccessStatus.granted});

  final LocationAccessStatus access;

  @override
  Future<LocationAccessStatus> checkAccess() async => access;
  @override
  Future<GeoCoordinate> getCurrentLocation() async =>
      const GeoCoordinate(latitude: -6.2, longitude: 106.8);
  @override
  Future<GeoCoordinate?> getLastKnownLocation() async => null;
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openLocationSettings() async => true;
  @override
  Future<LocationAccessStatus> requestAccess() async => access;
}

Future<void> _dismissNotice(
  WidgetTester tester,
  DaisthNoticeController controller,
) async {
  controller.dismiss();
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}
