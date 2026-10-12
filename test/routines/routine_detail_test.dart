import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/core/design_system/components/istiqam_notice_controller.dart';
import 'package:istiqam/core/design_system/theme/istiqam_theme.dart';
import 'package:istiqam/app/app.dart';
import 'package:istiqam/features/routines/data/demo/routine_demo_data.dart';
import 'package:istiqam/features/routines/domain/models/routine.dart';
import 'package:istiqam/features/routines/presentation/routine_detail_screen.dart';

void main() {
  testWidgets('Sholat Malam tracks partial progress, completion, and undo', (
    tester,
  ) async {
    final controller = IstiqamNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(tester, RoutineDemoData.sholatMalam, controller);

    expect(find.text('Partial · 2 of 4'), findsOneWidget);
    expect(find.text('Mark Remaining Done'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('routine-step-toggle-hajat')),
    );
    await tester.tap(find.byKey(const ValueKey('routine-step-toggle-hajat')));
    await tester.pumpAndSettle();
    expect(find.text('Partial · 3 of 4'), findsOneWidget);

    await tester.tap(find.text('Mark Remaining Done'));
    await tester.pumpAndSettle();
    expect(find.text('Completed · 4 of 4'), findsOneWidget);
    expect(find.text('Sholat Malam recorded'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    await _dismissNotice(tester, controller);

    await tester.ensureVisible(
      find.byKey(const ValueKey('routine-step-toggle-hajat')),
    );
    await tester.tap(find.byKey(const ValueKey('routine-step-toggle-hajat')));
    await tester.pumpAndSettle();
    expect(find.text('Partial · 3 of 4'), findsOneWidget);
  });

  testWidgets('Dhuha completes at its minimum while extra remains optional', (
    tester,
  ) async {
    final controller = IstiqamNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(tester, RoutineDemoData.dhuha, controller);

    expect(find.text('Partial'), findsNothing);
    expect(find.text('Not Today'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('routine-step-toggle-dhuha-minimum')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Completed · 2 rakaat'), findsOneWidget);
    expect(find.text('Partial'), findsNothing);
    expect(find.text('Tambahan 2 rakaat'), findsOneWidget);
    expect(find.text('Not Today'), findsOneWidget);
    expect(find.text('Mark Remaining Done'), findsOneWidget);
    await _dismissNotice(tester, controller);

    await tester.tap(find.text('Mark Remaining Done'));
    await tester.pumpAndSettle();
    expect(find.text('Completed · 4 rakaat'), findsOneWidget);
    await _dismissNotice(tester, controller);
    await _dismissNotice(tester, controller);
  });

  testWidgets('optional routine can be marked Not Today without a reason', (
    tester,
  ) async {
    final controller = IstiqamNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(tester, RoutineDemoData.dhuha, controller);

    await tester.tap(find.text('Not Today'));
    await tester.pumpAndSettle();
    expect(find.text('Tidak dilakukan hari ini?'), findsOneWidget);
    await tester.tap(find.text('Lewati alasan'));
    await tester.pumpAndSettle();

    expect(find.text('Tidak dilakukan hari ini'), findsOneWidget);
    expect(find.text('Status routine diperbarui'), findsOneWidget);
    await _dismissNotice(tester, controller);
  });

  testWidgets('Not Today saves a selected reason in this detail session', (
    tester,
  ) async {
    final controller = IstiqamNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(tester, RoutineDemoData.sholatMalam, controller);

    await tester.tap(find.text('Not Today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bepergian'));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Alasan: Bepergian'), findsOneWidget);
    await _dismissNotice(tester, controller);
  });

  testWidgets('mandatory Zuhur completes and has no Not Today action', (
    tester,
  ) async {
    final controller = IstiqamNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(tester, RoutineDemoData.zuhur, controller);

    expect(find.text('Not Today'), findsNothing);
    expect(find.text('Nearby Mosque'), findsOneWidget);
    expect(find.text('Post-Prayer Dhikr'), findsOneWidget);

    await tester.tap(find.text('Mark Zuhur Done'));
    await tester.pumpAndSettle();
    expect(find.text('Recorded just now'), findsOneWidget);
    expect(find.text('Zuhur recorded'), findsOneWidget);
    expect(find.text('Mark Zuhur Done'), findsNothing);
    await _dismissNotice(tester, controller);
  });

  testWidgets('Today timeline opens the Malam and Dhuha demos', (tester) async {
    await tester.pumpWidget(const IstiqamApp());

    await tester.ensureVisible(find.text('Sholat Malam'));
    await tester.tap(find.text('Sholat Malam'));
    await tester.pumpAndSettle();
    expect(find.text('Partial · 2 of 4'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Sholat Dhuha'));
    await tester.tap(find.text('Sholat Dhuha'));
    await tester.pumpAndSettle();
    expect(find.text('Belum dimulai'), findsOneWidget);
    expect(find.text('Sholat Dhuha'), findsOneWidget);
    expect(find.text('2 rakaat'), findsOneWidget);
  });

  testWidgets('step guidance opens a sheet and Reader uses an Istiqam notice', (
    tester,
  ) async {
    final controller = IstiqamNoticeController();
    addTearDown(controller.dispose);
    await _pumpRoutine(tester, RoutineDemoData.sholatMalam, controller);

    await tester.tap(find.text('Tahajud'));
    await tester.pumpAndSettle();
    expect(find.text('Guidance'), findsOneWidget);
    await tester.tap(find.text('Open Reading'));
    await tester.pumpAndSettle();
    expect(find.text('Reader segera hadir'), findsOneWidget);
    await _dismissNotice(tester, controller);
  });

  testWidgets('detail page builds in light and dark at compact width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = IstiqamNoticeController();
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
}

Future<void> _pumpRoutine(
  WidgetTester tester,
  Routine data,
  IstiqamNoticeController controller, {
  bool dark = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: IstiqamTheme.light,
      darkTheme: IstiqamTheme.dark,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: RoutineDetailScreen(routine: data, noticeController: controller),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _dismissNotice(
  WidgetTester tester,
  IstiqamNoticeController controller,
) async {
  controller.dismiss();
  await tester.pumpAndSettle();
}
