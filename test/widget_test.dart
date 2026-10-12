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

    await tester.tap(find.text('History').last);
    await tester.pumpAndSettle();

    expect(find.text('Belum ada history'), findsOneWidget);
  });
}
