import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/components/istiqam_notice_controller.dart';
import '../../features/history/presentation/history_placeholder_screen.dart';
import '../../features/routines/data/demo/routine_demo_data.dart';
import '../../features/routines/presentation/routine_detail_screen.dart';
import '../../features/routines/presentation/routines_placeholder_screen.dart';
import '../../features/settings/presentation/settings_placeholder_screen.dart';
import '../../features/today/presentation/today_screen.dart';
import '../app_preferences_scope.dart';
import '../app_shell.dart';
import 'app_routes.dart';
import 'route_paths.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'app-root');

GoRouter createAppRouter({
  required IstiqamNoticeController noticeController,
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
        );
      },
    ),
  ],
);
