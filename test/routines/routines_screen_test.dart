import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/design_system/components/daisth_notice_controller.dart';
import 'package:daisth/core/design_system/theme/daisth_theme.dart';
import 'package:daisth/features/routines/presentation/routines_screen.dart';

import '../support/fake_routine_record_repository.dart';
import '../support/fake_routine_repository.dart';

void main() {
  testWidgets('manager renders defaults and offers full-screen creation', (
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

    expect(find.text('Night Prayer'), findsOneWidget);
    expect(find.text('Fajr'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('No custom routines yet.'), findsOneWidget);

    expect(find.text('Add Routine'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty custom-routine state localizes to Indonesian', (
    tester,
  ) async {
    final routines = FakeRoutineRepository();
    final records = FakeRoutineRecordRepository();
    final notices = DaisthNoticeController();
    addTearDown(routines.close);
    addTearDown(notices.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada rutinitas khusus.'), findsOneWidget);
    expect(
      find.text(
        'Buat rutinitas untuk hal yang ingin kamu jaga konsistensinya.',
      ),
      findsOneWidget,
    );
    expect(find.text('No custom routines yet.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
