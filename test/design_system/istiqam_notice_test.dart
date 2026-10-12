import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:istiqam/core/design_system/components/istiqam_notice.dart';
import 'package:istiqam/core/design_system/components/istiqam_notice_controller.dart';
import 'package:istiqam/core/design_system/theme/istiqam_theme.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

void main() {
  testWidgets('renders its title, message, and semantic variant icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: IstiqamTheme.light,
        home: const Scaffold(
          body: IstiqamNotice(
            type: IstiqamNoticeType.info,
            title: 'Saved for later',
            message: 'Your progress is ready when you return.',
          ),
        ),
      ),
    );

    expect(find.text('Saved for later'), findsOneWidget);
    expect(
      find.text('Your progress is ready when you return.'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Icon && widget.icon == PhosphorIconsRegular.info,
      ),
      findsOneWidget,
    );
  });

  testWidgets('runs an optional action and close callback', (tester) async {
    var actionCount = 0;
    var closeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: IstiqamTheme.light,
        home: Scaffold(
          body: IstiqamNotice(
            type: IstiqamNoticeType.success,
            title: 'Routine recorded',
            actionLabel: 'View history',
            onAction: () => actionCount++,
            onClose: () => closeCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('View history'));
    await tester.tap(find.byTooltip('Dismiss notification'));

    expect(actionCount, 1);
    expect(closeCount, 1);
  });

  testWidgets('keeps the rest of the screen interactive', (tester) async {
    final controller = IstiqamNoticeController();
    addTearDown(controller.dispose);
    var outsideTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: IstiqamTheme.light,
        home: IstiqamNoticeScope(
          controller: controller,
          child: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  TextButton(
                    onPressed: () => controller.show(
                      context,
                      type: IstiqamNoticeType.info,
                      title: 'A transient notice',
                      duration: null,
                    ),
                    child: const Text('Show notice'),
                  ),
                  TextButton(
                    onPressed: () => outsideTapCount++,
                    child: const Text('Underlying action'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show notice'));
    await tester.pumpAndSettle();
    expect(find.text('A transient notice'), findsOneWidget);

    await tester.tap(find.text('Underlying action'));
    expect(outsideTapCount, 1);
  });
}
