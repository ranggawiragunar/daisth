import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/components/istiqam_notice_controller.dart';
import '../../app/dependencies/app_dependencies.dart';
import '../../features/history/presentation/history_placeholder_screen.dart';
import '../../features/dhikr/data/demo/dhikr_demo_data.dart';
import '../../features/dhikr/presentation/screens/dhikr_counter_screen.dart';
import '../../features/routines/data/demo/routine_demo_data.dart';
import '../../features/routines/presentation/routine_detail_screen.dart';
import '../../features/routines/presentation/routines_placeholder_screen.dart';
import '../../features/settings/presentation/settings_placeholder_screen.dart';
import '../../features/today/presentation/today_screen.dart';
import '../../features/reader/data/demo/reader_demo_data.dart';
import '../../features/reader/presentation/screens/reader_screen.dart';
import '../../features/mosque/presentation/screens/mosque_finder_screen.dart';
import '../../features/mosque/presentation/view_models/mosque_finder_view_model.dart';
import '../app_preferences_scope.dart';
import '../app_shell.dart';
import 'app_routes.dart';
import 'route_paths.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'app-root');

GoRouter createAppRouter({
  required IstiqamNoticeController noticeController,
  required AppDependencies dependencies,
  String initialLocation = RoutePaths.today,
}) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: RoutePaths.root,
      redirect: (context, state) => RoutePaths.today,
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.today,
              name: AppRoute.today.name,
              builder: (context, state) => TodayScreen(
                prayerScheduleSession: dependencies.prayerScheduleSession,
                routineRecordRepository: dependencies.routineRecordRepository,
                startClock: dependencies.startTodayClock,
                bottomContentPadding: AppShell.contentBottomPadding,
                onRoutineTap: (routineId) =>
                    context.push(RoutePaths.routineDetail(routineId)),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.history,
              name: AppRoute.history.name,
              builder: (context, state) => const HistoryPlaceholderScreen(
                bottomContentPadding: AppShell.contentBottomPadding,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.routines,
              name: AppRoute.routines.name,
              builder: (context, state) => const RoutinesPlaceholderScreen(
                bottomContentPadding: AppShell.contentBottomPadding,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.settings,
              name: AppRoute.settings.name,
              builder: (context, state) {
                final preferences = AppPreferencesScope.of(context);
                return SettingsPlaceholderScreen(
                  themeMode: preferences.themeMode,
                  onThemeModeChanged: preferences.onThemeModeChanged,
                  prayerScheduleSession: dependencies.prayerScheduleSession,
                  reminderSettings: dependencies.reminderSettings,
                  noticeController: noticeController,
                  bottomContentPadding: AppShell.contentBottomPadding,
                );
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: RoutePaths.routineDetailPattern,
      name: AppRoute.routineDetail.name,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final routineId = state.pathParameters['routineId']!;
        final routine = RoutineDemoData.byId(routineId);
        if (routine == null) {
          return RoutineUnavailableScreen(routineId: routineId);
        }
        return RoutineDetailScreen(
          key: ValueKey('routine-detail-$routineId'),
          routine: routine,
          noticeController: noticeController,
          routineRecordRepository: dependencies.routineRecordRepository,
          setRoutineStepCompletion: dependencies.setRoutineStepCompletion,
          markRoutineComplete: dependencies.markRoutineComplete,
          markRoutineNotToday: dependencies.markRoutineNotToday,
          prayerScheduleSession: dependencies.prayerScheduleSession,
        );
      },
      routes: [
        GoRoute(
          path: RoutePaths.readerPathSegment,
          name: AppRoute.reader.name,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final routineId = state.pathParameters['routineId']!;
            final contentId = state.pathParameters['contentId']!;
            final content = ReaderDemoData.byRoute(routineId, contentId);
            if (content == null) {
              return ReaderUnavailableScreen(routineId: routineId);
            }
            return ReaderScreen(
              key: ValueKey('reader-$routineId-$contentId'),
              routineId: routineId,
              content: content,
            );
          },
        ),
        GoRoute(
          path: RoutePaths.dhikrPathSegment,
          name: AppRoute.dhikrCounter.name,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final routineId = state.pathParameters['routineId']!;
            final dhikrId = state.pathParameters['dhikrId']!;
            final sequence = DhikrDemoData.byRoute(routineId, dhikrId);
            if (sequence == null) {
              return DhikrUnavailableScreen(routineId: routineId);
            }
            return DhikrCounterScreen(
              key: ValueKey('dhikr-$routineId-$dhikrId'),
              routineId: routineId,
              sequence: sequence,
            );
          },
        ),
        GoRoute(
          path: RoutePaths.mosquesPathSegment,
          name: AppRoute.mosqueFinder.name,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final routineId = state.pathParameters['routineId']!;
            return MosqueFinderScreen(
              key: ValueKey('mosques-$routineId'),
              routineId: routineId,
              viewModel: MosqueFinderViewModel(
                findNearbyMosques: dependencies.nearbyMosques,
              ),
              navigationService: dependencies.mapNavigationService,
              noticeController: noticeController,
            );
          },
        ),
      ],
    ),
  ],
);
