import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/app/app.dart';

void main() {
  testWidgets('Today is the initial destination and navigation works', (
    tester,
  ) async {
    await tester.pumpWidget(const IstiqamApp());

    expect(find.text("Assalamu'alaikum"), findsOneWidget);
    expect(find.text('3 of 7 routines recorded'), findsOneWidget);
    expect(find.text('Sholat Zuhur'), findsNWidgets(2));

    await tester.tap(find.text('History').last);
    await tester.pumpAndSettle();

    expect(find.text('Your routine history will appear here.'), findsOneWidget);
  });
}
