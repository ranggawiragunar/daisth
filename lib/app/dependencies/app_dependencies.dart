import 'dart:async';

import 'package:http/http.dart' as http;

import '../../core/app_settings/data/repositories/app_settings_repository_data.dart';
import '../../core/app_settings/data/services/app_settings_sqlite_service.dart';
import '../../core/app_settings/domain/models/app_settings.dart';
import '../../core/app_settings/domain/repositories/app_settings_repository.dart';
import '../../core/location/data/repositories/location_repository_data.dart';
import '../../core/location/domain/repositories/location_repository.dart';
import '../../core/location/domain/use_cases/resolve_current_location_use_case.dart';
import '../../core/maps/services/map_navigation_service.dart';
import '../../core/persistence/data/services/istiqam_database_service.dart';
import '../../core/timezone/data/repositories/timezone_repository_data.dart';
import '../../core/timezone/data/services/timezone_flutter_service.dart';
import '../../core/timezone/domain/repositories/timezone_repository.dart';
import '../../features/prayer_times/data/mappers/prayer_time_mapper.dart';
import '../../features/prayer_times/data/repositories/prayer_time_repository_data.dart';
import '../../features/prayer_times/data/services/prayer_time_adhan_service.dart';
import '../../features/prayer_times/domain/repositories/prayer_time_repository.dart';
import '../../features/prayer_times/domain/use_cases/load_today_prayer_schedule_use_case.dart';
import '../../features/prayer_times/presentation/prayer_schedule_session.dart';
import '../../features/mosque/data/mappers/mosque_mapper.dart';
import '../../features/mosque/data/repositories/mosque_repository_data.dart';
import '../../features/mosque/data/services/mosque_overpass_service.dart';
import '../../features/mosque/domain/repositories/mosque_repository.dart';
import '../../features/mosque/domain/use_cases/find_nearby_mosques_use_case.dart';
import '../../features/reminders/data/mappers/reminder_mapper.dart';
import '../../features/reminders/data/repositories/reminder_repository_data.dart';
import '../../features/reminders/data/services/reminder_local_notifications_service.dart';
import '../../features/reminders/data/services/reminder_notification_gateway.dart';
import '../../features/reminders/domain/repositories/reminder_repository.dart';
import '../../features/reminders/domain/use_cases/build_today_reminder_plan_use_case.dart';
import '../../features/reminders/domain/use_cases/schedule_today_reminders_use_case.dart';
import '../../features/reminders/presentation/view_models/reminder_settings_view_model.dart';
import '../../features/routines/data/mappers/routine_record_mapper.dart';
import '../../features/routines/data/repositories/routine_record_repository_data.dart';
import '../../features/routines/data/services/routine_record_sqlite_service.dart';
import '../../features/routines/domain/repositories/routine_record_repository.dart';
import '../../features/routines/domain/use_cases/mark_routine_complete_use_case.dart';
import '../../features/routines/domain/use_cases/mark_routine_not_today_use_case.dart';
import '../../features/routines/domain/use_cases/resolve_routine_status_use_case.dart';
import '../../features/routines/domain/use_cases/set_routine_step_completion_use_case.dart';

class AppDependencies {
  AppDependencies({
    http.Client? httpClient,
    LocationRepository? locationRepository,
    MosqueRepository? mosqueRepository,
    MapNavigationService? mapNavigationService,
    PrayerTimeRepository? prayerTimeRepository,
    ReminderRepository? reminderRepository,
    TimezoneRepository? timezoneRepository,
    ReminderNotificationGateway? reminderNotificationGateway,
    IstiqamDatabaseService? databaseService,
    AppSettingsRepository? appSettingsRepository,
    RoutineRecordRepository? routineRecordRepository,
    this.startTodayClock = true,
  }) : httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null {
    this.databaseService = databaseService ?? IstiqamDatabaseService();
    this.appSettingsRepository =
        appSettingsRepository ??
        AppSettingsRepositoryData(
          service: AppSettingsSqliteService(this.databaseService),
        );
    this.routineRecordRepository =
        routineRecordRepository ??
        RoutineRecordRepositoryData(
          service: RoutineRecordSqliteService(this.databaseService),
          mapper: RoutineRecordMapper(),
        );
    resolveRoutineStatus = const ResolveRoutineStatusUseCase();
    setRoutineStepCompletion = SetRoutineStepCompletionUseCase(
      repository: this.routineRecordRepository,
    );
    markRoutineComplete = MarkRoutineCompleteUseCase(
      repository: this.routineRecordRepository,
      resolveStatus: resolveRoutineStatus,
    );
    markRoutineNotToday = MarkRoutineNotTodayUseCase(
      this.routineRecordRepository,
    );
    this.locationRepository = locationRepository ?? LocationRepositoryData();
    this.mosqueRepository =
        mosqueRepository ??
        MosqueRepositoryData(
          service: MosqueOverpassService(client: this.httpClient),
          mapper: MosqueMapper(),
        );
    this.mapNavigationService = mapNavigationService ?? MapNavigationService();
    resolveCurrentLocation = ResolveCurrentLocationUseCase(
      locationRepository: this.locationRepository,
    );
    this.prayerTimeRepository =
        prayerTimeRepository ??
        PrayerTimeRepositoryData(
          service: PrayerTimeAdhanService(),
          mapper: PrayerTimeMapper(),
        );
    loadTodayPrayerSchedule = LoadTodayPrayerScheduleUseCase(
      resolveCurrentLocation: resolveCurrentLocation,
      prayerTimeRepository: this.prayerTimeRepository,
    );
    prayerScheduleSession = PrayerScheduleSession(loadTodayPrayerSchedule);
    nearbyMosques = FindNearbyMosquesUseCase(
      locationRepository: this.locationRepository,
      mosqueRepository: this.mosqueRepository,
      resolveCurrentLocation: resolveCurrentLocation,
    );
    this.timezoneRepository =
        timezoneRepository ??
        TimezoneRepositoryData(service: TimezoneFlutterService());
    this.reminderRepository =
        reminderRepository ??
        ReminderRepositoryData(
          service:
              reminderNotificationGateway ??
              ReminderLocalNotificationsService(),
          mapper: reminderMapper,
        );
    buildTodayReminderPlan = BuildTodayReminderPlanUseCase();
    scheduleTodayReminders = ScheduleTodayRemindersUseCase(
      reminderRepository: this.reminderRepository,
      timezoneRepository: this.timezoneRepository,
      loadTodayPrayerSchedule: loadTodayPrayerSchedule,
      buildTodayReminderPlan: buildTodayReminderPlan,
    );
    reminderSettings = ReminderSettingsViewModel(
      reminderRepository: this.reminderRepository,
      timezoneRepository: this.timezoneRepository,
      scheduleTodayReminders: scheduleTodayReminders,
      prayerScheduleSession: prayerScheduleSession,
      appSettingsRepository: this.appSettingsRepository,
    );
  }

  final http.Client httpClient;
  final bool startTodayClock;
  final bool _ownsHttpClient;
  late final IstiqamDatabaseService databaseService;
  late final AppSettingsRepository appSettingsRepository;
  late final RoutineRecordRepository routineRecordRepository;
  late final ResolveRoutineStatusUseCase resolveRoutineStatus;
  late final SetRoutineStepCompletionUseCase setRoutineStepCompletion;
  late final MarkRoutineCompleteUseCase markRoutineComplete;
  late final MarkRoutineNotTodayUseCase markRoutineNotToday;
  late final LocationRepository locationRepository;
  late final ResolveCurrentLocationUseCase resolveCurrentLocation;
  late final PrayerTimeRepository prayerTimeRepository;
  late final LoadTodayPrayerScheduleUseCase loadTodayPrayerSchedule;
  late final PrayerScheduleSession prayerScheduleSession;
  late final MosqueRepository mosqueRepository;
  late final MapNavigationService mapNavigationService;
  late final FindNearbyMosquesUseCase nearbyMosques;
  late final TimezoneRepository timezoneRepository;
  late final ReminderRepository reminderRepository;
  late final ReminderMapper reminderMapper = ReminderMapper();
  late final BuildTodayReminderPlanUseCase buildTodayReminderPlan;
  late final ScheduleTodayRemindersUseCase scheduleTodayReminders;
  late final ReminderSettingsViewModel reminderSettings;
  AppSettings appSettings = const AppSettings();
  Object? initializationError;
  Future<void>? _initialization;

  Future<void> initialize({void Function(String? payload)? onNotificationTap}) {
    return _initialization ??= _initialize(onNotificationTap);
  }

  Future<void> _initialize(
    void Function(String? payload)? onNotificationTap,
  ) async {
    try {
      await databaseService.open();
      appSettings = await appSettingsRepository.getSettings();
    } catch (error) {
      initializationError = error;
    }
    try {
      await timezoneRepository.initialize();
      await reminderRepository.initialize(onNotificationTap: onNotificationTap);
      final launchPayload = await reminderRepository.getLaunchPayload();
      if (launchPayload != null) onNotificationTap?.call(launchPayload);
      await reminderSettings.initialize();
    } catch (error) {
      initializationError ??= error;
    }
  }

  Future<void> setThemePreference(AppThemePreference preference) async {
    appSettings = (await appSettingsRepository.getSettings()).copyWith(
      themePreference: preference,
      updatedAt: DateTime.now().toUtc(),
    );
    await appSettingsRepository.saveSettings(appSettings);
  }

  void dispose() {
    reminderSettings.dispose();
    if (routineRecordRepository case final RoutineRecordRepositoryData data) {
      unawaited(data.closeChanges());
    }
    unawaited(databaseService.close());
    prayerScheduleSession.dispose();
    if (_ownsHttpClient) httpClient.close();
  }
}
