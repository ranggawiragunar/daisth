import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/design_system/components/daisth_notice_controller.dart';
import 'package:daisth/core/design_system/theme/daisth_theme.dart';
import 'package:daisth/features/routines/presentation/routines_screen.dart';

import '../support/fake_routine_record_repository.dart';
import '../support/fake_routine_repository.dart';

void main() {
  testWidgets('manager renders defaults and can create a custom routine', (
    tester,
  ) async {
    final routines = FakeRoutineRepository();
    final records = FakeRoutineRecordRepository();
    final notices = DaisthNoticeController();
    addTearDown(routines.close);
    addTearDown(notices.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: DaisthTheme.light,
        home: Scaffold(
          body: RoutinesScreen(
            routineRepository: routines,
            routineRecordRepository: records,
            noticeController: notices,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sholat Malam'), findsOneWidget);
    expect(find.text('Subuh'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('No custom routines yet.'), findsOneWidget);

    await tester.tap(find.text('Add Routine'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Morning Reading');
    await tester.tap(find.text('Save Routine'));
    await tester.pumpAndSettle();

    expect(find.text('Morning Reading'), findsOneWidget);
    expect(find.text('No custom routines yet.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
