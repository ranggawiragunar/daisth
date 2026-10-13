import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daisth/core/design_system/components/daisth_notice.dart';
import 'package:daisth/core/design_system/components/daisth_notice_controller.dart';
import 'package:daisth/core/design_system/theme/daisth_theme.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

void main() {
  testWidgets('renders its title, message, and semantic variant icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DaisthTheme.light,
        home: const Scaffold(
          body: DaisthNotice(
            type: DaisthNoticeType.info,
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
        theme: DaisthTheme.light,
        home: Scaffold(
          body: DaisthNotice(
            type: DaisthNoticeType.success,
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

  testWidgets('one-line notice centers its icon and title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DaisthTheme.light,
        home: const Scaffold(
          body: Center(
            child: DaisthNotice(
              type: DaisthNoticeType.info,
              title: 'Saved',
              showCloseButton: false,
            ),
          ),
        ),
      ),
    );

    final iconCenter = tester.getCenter(
      find.byWidgetPredicate(
        (widget) => widget is Icon && widget.icon == PhosphorIconsRegular.info,
      ),
    );
    final titleCenter = tester.getCenter(find.text('Saved'));
    expect((iconCenter.dy - titleCenter.dy).abs(), lessThan(2));
  });

  testWidgets('title and body remain a compact vertical text group', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DaisthTheme.light,
        home: const Scaffold(
          body: Center(
            child: DaisthNotice(
              type: DaisthNoticeType.warning,
              title: 'Complete your prayer first',
              message: 'Then you can continue to the next step.',
              showCloseButton: false,
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(DaisthNotice)).height, lessThan(76));
  });

  testWidgets('notice overlay floats above its contextual bottom anchor', (
    tester,
  ) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: DaisthTheme.light,
        home: DaisthNoticeScope(
          controller: controller,
          child: DaisthNoticeAnchor(
            bottomInset: 120,
            child: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => controller.show(
                    context,
                    type: DaisthNoticeType.info,
                    title: 'Dock clearance',
                    duration: null,
                  ),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    final noticeRect = tester.getRect(find.text('Dock clearance'));
    expect(noticeRect.bottom, lessThan(680));
    expect(noticeRect.center.dy, greaterThan(400));
    expect(find.byTooltip('Dismiss notification'), findsOneWidget);
  });

  testWidgets('new notice replaces the current overlay notice', (tester) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: DaisthTheme.light,
        home: DaisthNoticeScope(
          controller: controller,
          child: Builder(
            builder: (context) {
              pageContext = context;
              return const Scaffold(body: Text('Page'));
            },
          ),
        ),
      ),
    );

    controller.show(
      pageContext,
      type: DaisthNoticeType.info,
      title: 'First notice',
      duration: null,
    );
    await tester.pumpAndSettle();
    controller.show(
      pageContext,
      type: DaisthNoticeType.success,
      title: 'Replacement notice',
      duration: null,
    );
    await tester.pumpAndSettle();

    expect(find.text('First notice'), findsNothing);
    expect(find.text('Replacement notice'), findsOneWidget);
  });

  testWidgets('action notices retain a close control while persistent', (
    tester,
  ) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: DaisthTheme.light,
        home: DaisthNoticeScope(
          controller: controller,
          child: Builder(
            builder: (context) {
              pageContext = context;
              return const Scaffold(body: Text('Page'));
            },
          ),
        ),
      ),
    );

    controller.show(
      pageContext,
      type: DaisthNoticeType.info,
      title: 'Retry required',
      actionLabel: 'Retry',
      onAction: () {},
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.byTooltip('Dismiss notification'), findsOneWidget);
  });

  testWidgets('standalone notice stays above the device safe area', (
    tester,
  ) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        theme: DaisthTheme.light,
        home: DaisthNoticeScope(
          controller: controller,
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => controller.show(
                  context,
                  type: DaisthNoticeType.info,
                  title: 'Standalone notice',
                  duration: null,
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byType(DaisthNotice)).bottom,
      lessThanOrEqualTo(764),
    );
  });

  testWidgets('keeps the rest of the screen interactive', (tester) async {
    final controller = DaisthNoticeController();
    addTearDown(controller.dispose);
    var outsideTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: DaisthTheme.light,
        home: DaisthNoticeScope(
          controller: controller,
          child: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  TextButton(
                    onPressed: () => controller.show(
                      context,
                      type: DaisthNoticeType.info,
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
