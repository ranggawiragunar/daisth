import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_screens.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/domain/current_onboarding_version.dart';

import '../../core/design_system/components/daisth_notice_controller.dart';
import '../../core/time/domain/models/calendar_day.dart';
import '../../app/dependencies/app_dependencies.dart';
import '../../features/history/presentation/screens/history_screens.dart';
import '../../features/dhikr/data/demo/dhikr_demo_data.dart';
import '../../features/dhikr/presentation/screens/dhikr_counter_screen.dart';
import '../../features/routines/presentation/routine_detail_route_screen.dart';
import '../../features/routines/presentation/routines_screen.dart';
import '../../features/settings/presentation/settings_placeholder_screen.dart';
import '../../features/settings/presentation/settings_detail_screens.dart';
import '../../features/today/presentation/today_screen.dart';
import '../../features/reader/data/catalog/reader_content_catalog.dart';
import '../../features/reader/presentation/screens/reader_screen.dart';
import '../../features/mosque/presentation/screens/mosque_finder_screen.dart';
import '../../features/mosque/presentation/view_models/mosque_finder_view_model.dart';
import '../../features/reflection/presentation/screens/reflection_screen.dart';
import '../app_preferences_scope.dart';
import '../app_shell.dart';
import 'app_routes.dart';
import 'route_paths.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'app-root');

GoRouter createAppRouter({
  required DaisthNoticeController noticeController,
  required AppDependencies dependencies,
  String initialLocation = RoutePaths.today,
  bool enforceOnboarding = true,
}) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: initialLocation,
  redirect: enforceOnboarding
      ? (context, state) async {
          final version = await dependencies.getOnboardingVersion();
          final onboarding = state.uri.path == RoutePaths.onboarding;
          if ((version ?? 0) < currentOnboardingVersion && !onboarding) {
            return RoutePaths.onboarding;
          }
          if ((version ?? 0) >= currentOnboardingVersion && onboarding) {
            return RoutePaths.today;
          }
          return null;
        }
      : null,
  routes: [
    GoRoute(
      path: RoutePaths.onboarding,
      name: AppRoute.onboarding.name,
      builder: (context, state) => OnboardingScreen(
        completeOnboarding: dependencies.completeOnboarding,
        notices: noticeController,
      ),
    ),
    GoRoute(
      path: RoutePaths.account,
      name: AppRoute.account.name,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AccountScreen(
        viewModel: dependencies.authViewModel,
        deleteAccountUseCase: dependencies.deleteAccountUseCase,
        syncViewModel: dependencies.syncViewModel,
        notices: noticeController,
      ),
    ),
    GoRoute(
      path: RoutePaths.settingsPrayerLocation,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => PrayerLocationSettingsScreen(
        locationRepository: dependencies.locationRepository,
        timezoneRepository: dependencies.timezoneRepository,
        prayerScheduleSession: dependencies.prayerScheduleSession,
        reminderSettings: dependencies.reminderSettings,
      ),
    ),
    GoRoute(
      path: RoutePaths.settingsNotifications,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => NotificationsSettingsScreen(
        reminderSettings: dependencies.reminderSettings,
      ),
    ),
    GoRoute(
      path: RoutePaths.settingsPrivacy,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DataPrivacySettingsScreen(),
    ),
    GoRoute(
      path: RoutePaths.settingsAbout,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AboutDaisthScreen(),
    ),
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
                routineRepository: dependencies.routineRepository,
                reflectionRepository: dependencies.reflectionRepository,
                ensureRoutinesReady: dependencies.ensureRoutineDefinitionsReady,
                startClock: dependencies.startTodayClock,
                bottomContentPadding: AppShell.contentBottomPadding,
                onRoutineTap: (routineId) =>
                    context.push(RoutePaths.routineDetail(routineId)),
                onReflectionTap: () => context.push(RoutePaths.reflection),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.history,
              name: AppRoute.history.name,
              builder: (context, state) => HistoryScreen(
                dependencies: dependencies,
                bottomContentPadding: AppShell.contentBottomPadding,
              ),
              routes: [
                GoRoute(
                  path: ':date',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => HistoryDayScreen(
                    date: state.pathParameters['date']!,
                    dependencies: dependencies,
                  ),
                  routes: [
                    GoRoute(
                      path: 'reflection',
                      parentNavigatorKey: _rootNavigatorKey,
                      redirect: (context, state) {
                        try {
                          CalendarDay.parseDateKey(
                            state.pathParameters['date']!,
                          );
                          return null;
                        } on FormatException {
                          return RoutePaths.history;
                        }
                      },
                      builder: (context, state) => ReflectionScreen(
                        key: ValueKey(
                          'history-reflection-${state.pathParameters['date']}',
                        ),
                        day: CalendarDay.parseDateKey(
                          state.pathParameters['date']!,
                        ),
                        historical: true,
                        dependencies: dependencies,
                        noticeController: noticeController,
                      ),
                    ),
                    GoRoute(
                      path: 'routines/:routineId',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final dateValue = state.pathParameters['date']!;
                        CalendarDay? selectedDay;
                        try {
                          selectedDay = CalendarDay.parseDateKey(dateValue);
                        } on FormatException {
                          return HistoryDayScreen(
                            date: dateValue,
                            dependencies: dependencies,
                          );
                        }
                        return RoutineDetailRouteScreen(
                          key: ValueKey(
                            'history-routine-$dateValue-${state.pathParameters['routineId']}',
                          ),
                          routineId: state.pathParameters['routineId']!,
                          dependencies: dependencies,
                          noticeController: noticeController,
                          calendarDay: selectedDay,
                          historical: true,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.routines,
              name: AppRoute.routines.name,
              builder: (context, state) => RoutinesScreen(
                routineRepository: dependencies.routineRepository,
                routineRecordRepository: dependencies.routineRecordRepository,
                noticeController: noticeController,
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
      path: RoutePaths.reflection,
      name: AppRoute.reflection.name,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ReflectionScreen(
        key: const ValueKey('current-reflection'),
        day: CalendarDay.fromDateTime(DateTime.now()),
        historical: false,
        dependencies: dependencies,
        noticeController: noticeController,
      ),
    ),
    GoRoute(
      path: RoutePaths.routineDetailPattern,
      name: AppRoute.routineDetail.name,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final routineId = state.pathParameters['routineId']!;
        return RoutineDetailRouteScreen(
          key: ValueKey('routine-detail-route-$routineId'),
          routineId: routineId,
          dependencies: dependencies,
          noticeController: noticeController,
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
            final content = ReaderContentCatalog.byRoute(routineId, contentId);
            if (content == null) {
              return ReaderUnavailableScreen(routineId: routineId);
            }
            return ReaderScreen(
              key: ValueKey('reader-$routineId-$contentId'),
              routineId: routineId,
              content: content,
              fallbackRoute: _readerFallbackRoute(state, routineId),
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

String? _readerFallbackRoute(GoRouterState state, String routineId) {
  final dateKey = state.uri.queryParameters['historyDate'];
  if (dateKey == null) return null;
  try {
    CalendarDay.parseDateKey(dateKey);
  } on FormatException {
    return null;
  }
  return RoutePaths.historyRoutine(dateKey, routineId);
}
