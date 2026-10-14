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
import '../../core/persistence/data/services/daisth_database_service.dart';
import '../../core/timezone/data/repositories/timezone_repository_data.dart';
import '../../core/timezone/data/services/timezone_flutter_service.dart';
import '../../core/timezone/domain/repositories/timezone_repository.dart';
import '../../core/time/domain/models/calendar_day.dart';
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
import '../../features/reminders/data/mappers/routine_reminder_state_mapper.dart';
import '../../features/reminders/data/repositories/routine_reminder_state_repository_data.dart';
import '../../features/reminders/data/services/routine_reminder_state_sqlite_service.dart';
import '../../features/reminders/domain/repositories/reminder_repository.dart';
import '../../features/reminders/domain/models/reminder_priority.dart';
import '../../features/reminders/domain/models/reminder.dart';
import '../../features/reminders/domain/models/reminder_permission_status.dart';
import '../../features/reminders/domain/use_cases/build_today_reminder_plan_use_case.dart';
import '../../features/reminders/domain/use_cases/schedule_today_reminders_use_case.dart';
import '../../features/reminders/domain/use_cases/handle_reminder_action_use_case.dart';
import '../../features/reminders/domain/repositories/routine_reminder_state_repository.dart';
import '../../features/reminders/presentation/view_models/reminder_settings_view_model.dart';
import '../../features/routines/data/mappers/routine_record_mapper.dart';
import '../../features/routines/data/demo/routine_demo_data.dart';
import '../../features/routines/data/catalog/default_routine_template_catalog.dart';
import '../../features/routines/data/mappers/routine_definition_mapper.dart';
import '../../features/routines/data/repositories/routine_record_repository_data.dart';
import '../../features/routines/data/repositories/routine_repository_data.dart';
import '../../features/routines/data/repositories/routine_content_repository_data.dart';
import '../../features/routines/data/repositories/routine_attachment_repository_data.dart';
import '../../features/routines/data/repositories/routine_editor_repository_data.dart';
import '../../features/routines/data/services/routine_attachment_file_service.dart';
import '../../features/routines/data/services/routine_attachment_storage_service.dart';
import '../../features/routines/domain/repositories/routine_content_repository.dart';
import '../../features/routines/domain/repositories/routine_attachment_repository.dart';
import '../../features/routines/domain/repositories/routine_editor_repository.dart';
import '../../features/routines/data/resolvers/routine_resolver.dart';
import '../../features/routines/data/services/routine_record_sqlite_service.dart';
import '../../features/routines/data/services/routine_sqlite_service.dart';
import '../../features/routines/domain/repositories/routine_record_repository.dart';
import '../../features/routines/domain/repositories/routine_repository.dart';
import '../../features/routines/domain/use_cases/ensure_default_routines_use_case.dart';
import '../../features/routines/domain/models/routine_status.dart';
import '../../features/routines/domain/use_cases/mark_routine_complete_use_case.dart';
import '../../features/routines/domain/use_cases/mark_routine_not_today_use_case.dart';
import '../../features/routines/domain/use_cases/resolve_routine_status_use_case.dart';
import '../../features/routines/domain/use_cases/set_routine_step_completion_use_case.dart';
import '../../features/reflection/data/mappers/reflection_mapper.dart';
import '../../features/reflection/data/repositories/reflection_repository_data.dart';
import '../../features/reflection/data/services/reflection_sqlite_service.dart';
import '../../features/reflection/domain/repositories/reflection_repository.dart';
import '../../features/auth/data/repositories/auth_repository_data.dart';
import '../../features/auth/data/services/firebase_auth_service.dart';
import '../../features/auth/data/services/firebase_bootstrap_service.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/auth_view_model.dart';
import '../../features/auth/domain/use_cases/delete_account_use_case.dart';
import '../../features/onboarding/domain/current_onboarding_version.dart';
import '../../features/sync/data/mappers/firestore_document_ids.dart';
import '../../features/sync/data/repositories/sync_local_repository_data.dart';
import '../../features/sync/data/services/daisth_firestore_service.dart';
import '../../features/sync/data/services/sync_sqlite_service.dart';
import '../../features/sync/data/services/sync_outbox_sqlite_helper.dart';
import '../../features/sync/domain/models/sync_entity.dart';
import '../../features/sync/domain/repositories/cloud_data_repository.dart';
import '../../features/sync/domain/sync_coordinator.dart';
import '../../features/sync/presentation/sync_view_model.dart';

class AppDependencies {
  AppDependencies({
    String languageCode = 'id',
    http.Client? httpClient,
    LocationRepository? locationRepository,
    MosqueRepository? mosqueRepository,
    MapNavigationService? mapNavigationService,
    PrayerTimeRepository? prayerTimeRepository,
    ReminderRepository? reminderRepository,
    TimezoneRepository? timezoneRepository,
    ReminderNotificationGateway? reminderNotificationGateway,
    DaisthDatabaseService? databaseService,
    AppSettingsRepository? appSettingsRepository,
    RoutineRecordRepository? routineRecordRepository,
    RoutineRepository? routineRepository,
    RoutineContentRepository? routineContentRepository,
    RoutineAttachmentRepository? routineAttachmentRepository,
    RoutineEditorRepository? routineEditorRepository,
    RoutineAttachmentFileService? routineAttachmentFileService,
    RoutineAttachmentStorageService? routineAttachmentStorageService,
    ReflectionRepository? reflectionRepository,
    AuthRepository? authRepository,
    CloudDataRepository? cloudDataRepository,
    this.startTodayClock = true,
  }) : languageCode = languageCode,
       httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null {
    _reminderNotificationGateway =
        reminderNotificationGateway ??
        ReminderLocalNotificationsService(languageCode: languageCode);
    this.databaseService = databaseService ?? DaisthDatabaseService();
    this.routineAttachmentFileService =
        routineAttachmentFileService ?? RoutineAttachmentFileService();
    this.routineAttachmentStorageService =
        routineAttachmentStorageService ?? RoutineAttachmentStorageService();
    firebaseAuthService = FirebaseAuthService();
    firebaseBootstrapService = FirebaseBootstrapService();
    this.authRepository =
        authRepository ??
        AuthRepositoryData(firebaseAuthService, firebaseBootstrapService);
    authViewModel = AuthViewModel(this.authRepository);
    syncLocalRepository = SyncLocalRepositoryData(
      SyncSqliteService(this.databaseService),
    );
    this.cloudDataRepository =
        cloudDataRepository ??
        DaisthFirestoreService(
          attachmentStorage: this.routineAttachmentStorageService,
          attachmentFiles: this.routineAttachmentFileService,
        );
    syncCoordinator = SyncCoordinator(
      authRepository: this.authRepository,
      localRepository: syncLocalRepository,
      cloudRepository: this.cloudDataRepository,
      onRemoteChanges: _notifyRemoteChanges,
    );
    syncViewModel = SyncViewModel(syncCoordinator);
    deleteAccountUseCase = DeleteAccountUseCase(
      authRepository: this.authRepository,
      cloudRepository: this.cloudDataRepository,
      syncLocalRepository: syncLocalRepository,
      syncCoordinator: syncCoordinator,
    );
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
    this.routineRepository =
        routineRepository ??
        RoutineRepositoryData(
          service: RoutineSqliteService(this.databaseService),
          mapper: RoutineDefinitionMapper(),
        );
    this.routineContentRepository =
        routineContentRepository ??
        RoutineContentRepositoryData(database: this.databaseService);
    this.routineAttachmentRepository =
        routineAttachmentRepository ??
        RoutineAttachmentRepositoryData(database: this.databaseService);
    this.routineEditorRepository =
        routineEditorRepository ??
        RoutineEditorRepositoryData(
          database: this.databaseService,
          onRoutineChanged: () {
            final repository = this.routineRepository;
            if (repository is RoutineRepositoryData) {
              repository.notifyLocalChanged();
            }
          },
        );
    this.reflectionRepository =
        reflectionRepository ??
        ReflectionRepositoryData(
          service: ReflectionSqliteService(this.databaseService),
          mapper: ReflectionMapper(),
        );
    ensureDefaultRoutines = EnsureDefaultRoutinesUseCase(
      repository: this.routineRepository,
      templates: DefaultRoutineTemplateCatalog.definitions,
    );
    routineResolver = RoutineResolver(this.routineRepository);
    routineReminderStateRepository = RoutineReminderStateRepositoryData(
      service: RoutineReminderStateSqliteService(this.databaseService),
      mapper: RoutineReminderStateMapper(),
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
          service: _reminderNotificationGateway,
          mapper: reminderMapper,
        );
    buildTodayReminderPlan = BuildTodayReminderPlanUseCase(
      languageCode: languageCode,
    );
    scheduleTodayReminders = ScheduleTodayRemindersUseCase(
      reminderRepository: this.reminderRepository,
      timezoneRepository: this.timezoneRepository,
      loadTodayPrayerSchedule: loadTodayPrayerSchedule,
      buildTodayReminderPlan: buildTodayReminderPlan,
      routineRecordRepository: this.routineRecordRepository,
      routineRepository: this.routineRepository,
      reminderStateRepository: routineReminderStateRepository,
      reflectionRepository: this.reflectionRepository,
    );
    handleReminderAction = HandleReminderActionUseCase(
      routineRepository: this.routineRecordRepository,
      reminderStateRepository: routineReminderStateRepository,
      reminderRepository: this.reminderRepository,
      markRoutineComplete: markRoutineComplete,
      resolveRoutine: (id) async =>
          (await routineResolver.resolve(id))?.routine,
    );
    reminderSettings = ReminderSettingsViewModel(
      reminderRepository: this.reminderRepository,
      timezoneRepository: this.timezoneRepository,
      scheduleTodayReminders: scheduleTodayReminders,
      prayerScheduleSession: prayerScheduleSession,
      appSettingsRepository: this.appSettingsRepository,
      reminderStateRepository: routineReminderStateRepository,
      languageCode: languageCode,
    );
  }

  String languageCode;
  final http.Client httpClient;
  final bool startTodayClock;
  final bool _ownsHttpClient;
  late final DaisthDatabaseService databaseService;
  late final FirebaseAuthService firebaseAuthService;
  late final FirebaseBootstrapService firebaseBootstrapService;
  late final AuthRepository authRepository;
  late final AuthViewModel authViewModel;
  late final SyncLocalRepositoryData syncLocalRepository;
  late final CloudDataRepository cloudDataRepository;
  late final SyncCoordinator syncCoordinator;
  late final SyncViewModel syncViewModel;
  late final DeleteAccountUseCase deleteAccountUseCase;
  late final AppSettingsRepository appSettingsRepository;
  late final RoutineRecordRepository routineRecordRepository;
  late final RoutineRepository routineRepository;
  late final RoutineContentRepository routineContentRepository;
  late final RoutineAttachmentRepository routineAttachmentRepository;
  late final RoutineEditorRepository routineEditorRepository;
  late final RoutineAttachmentFileService routineAttachmentFileService;
  late final RoutineAttachmentStorageService routineAttachmentStorageService;
  late final ReflectionRepository reflectionRepository;
  late final EnsureDefaultRoutinesUseCase ensureDefaultRoutines;
  late final RoutineResolver routineResolver;
  late final RoutineReminderStateRepository routineReminderStateRepository;
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
  late final ReminderNotificationGateway _reminderNotificationGateway;
  late final ReminderMapper reminderMapper = ReminderMapper(
    languageCode: languageCode,
  );
  late final BuildTodayReminderPlanUseCase buildTodayReminderPlan;
  late final ScheduleTodayRemindersUseCase scheduleTodayReminders;
  late final HandleReminderActionUseCase handleReminderAction;
  late final ReminderSettingsViewModel reminderSettings;
  AppSettings appSettings = const AppSettings();
  Object? initializationError;
  Future<void>? _initialization;
  Future<int?>? _onboardingVersionLoad;
  Future<void>? _routineDefinitionsInitialization;
  StreamSubscription<RoutineRecordChange>? _routineReminderChangeSubscription;
  StreamSubscription<void>? _routineDefinitionChangeSubscription;
  StreamSubscription<ReflectionChange>? _reflectionChangeSubscription;
  StreamSubscription<void>? _syncMutationSubscription;

  Future<void> initialize({void Function(String? payload)? onNotificationTap}) {
    return _initialization ??= _initialize(onNotificationTap);
  }

  Future<void> _initialize(
    void Function(String? payload)? onNotificationTap,
  ) async {
    try {
      await ensureRoutineDefinitionsReady();
      try {
        await routineAttachmentFileService.cleanStaging();
        await routineAttachmentFileService.deleteOrphanFiles(
          await routineAttachmentRepository.getAllLocalRelativePaths(),
        );
      } catch (_) {
        // Attachment cleanup is best-effort and never blocks local startup.
      }
      appSettings = await appSettingsRepository.getSettings();
      _routineReminderChangeSubscription ??= routineRecordRepository.changes
          .listen((change) {
            if (!change.isRemoteSync) {
              unawaited(_reconcileRoutineChange(change));
            }
          });
      final routineLocalChanges = switch (routineRepository) {
        RoutineRepositoryData data => data.localChanges,
        _ => routineRepository.changes,
      };
      _routineDefinitionChangeSubscription ??= routineLocalChanges.listen(
        (_) => unawaited(_reconcileRoutineDefinitionChange()),
      );
      _reflectionChangeSubscription ??= reflectionRepository.changes.listen((
        change,
      ) {
        if (!change.isRemoteSync) {
          unawaited(_reconcileReflectionChange(change));
        }
      });
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
    try {
      if (await firebaseBootstrapService.initialize()) {
        if (cloudDataRepository case final DaisthFirestoreService service) {
          service.configureTransport();
        }
        firebaseAuthService.attachDefault();
        await authViewModel.refreshSession();
      }
    } catch (_) {
      // Optional account setup must not prevent local Daisth startup.
    }
    try {
      await syncCoordinator.initialize();
      _syncMutationSubscription ??= SyncOutboxSqliteHelper.localMutations
          .listen((_) => unawaited(syncCoordinator.onLocalDataChanged()));
    } catch (_) {
      // Sync initialization never blocks local app startup.
    }
  }

  Future<void> _notifyRemoteChanges(List<SyncEntity> entities) async {
    var routineDefinitionsChanged = false;
    var reconcileToday = false;
    final today = CalendarDay.fromDateTime(DateTime.now());
    final changedDefinitionIds = <String>{};
    final affectedRecords = <String, (CalendarDay, String)>{};
    for (final entity in entities) {
      switch (entity.type) {
        case SyncEntityType.routineDefinition:
          routineDefinitionsChanged = true;
          changedDefinitionIds.add(Uri.decodeComponent(entity.id));
        case SyncEntityType.routineStepDefinition:
          routineDefinitionsChanged = true;
          changedDefinitionIds.add(
            FirestoreDocumentIds.splitPair(entity.id).$1,
          );
        case SyncEntityType.routineRecord:
          final pair = FirestoreDocumentIds.splitPair(entity.id);
          final day = CalendarDay.parseDateKey(pair.$1);
          reconcileToday |= day == today;
          final key = '${pair.$1}|${pair.$2}';
          affectedRecords[key] = (day, pair.$2);
        case SyncEntityType.routineStepRecord:
          final parts = FirestoreDocumentIds.splitTriple(entity.id);
          final day = CalendarDay.parseDateKey(parts.$1);
          reconcileToday |= day == today;
          final key = '${parts.$1}|${parts.$2}';
          affectedRecords[key] = (day, parts.$2);
        case SyncEntityType.dailyReflection:
          reconcileToday |= CalendarDay.parseDateKey(entity.id) == today;
          if (reflectionRepository case final ReflectionRepositoryData data) {
            data.notifyRemoteChanged(CalendarDay.parseDateKey(entity.id));
          }
        case SyncEntityType.routineContent || SyncEntityType.routineAttachment:
          // User notes and images do not change routine status or reminders.
          break;
      }
    }
    if (routineRecordRepository case final RoutineRecordRepositoryData data) {
      for (final routineId in changedDefinitionIds) {
        for (final record in await data.getRecordsForRoutine(routineId)) {
          affectedRecords['${record.calendarDay.toDateKey()}|$routineId'] = (
            record.calendarDay,
            routineId,
          );
        }
      }
      for (final (day, routineId) in affectedRecords.values) {
        final resolved = await routineResolver.resolve(routineId);
        final reconciled = resolved == null
            ? false
            : await data.reconcileCompositeStatus(
                routine: resolved.routine,
                day: day,
                now: DateTime.now().toUtc(),
              );
        if (!reconciled) data.notifyRemoteChanged(day, routineId);
      }
    }
    if (routineDefinitionsChanged) {
      reconcileToday = true;
      if (routineRepository case final RoutineRepositoryData data) {
        data.notifyRemoteChanged();
      }
    }
    if (reconcileToday) await _reconcileRoutineDefinitionChange();
  }

  Future<int?> getOnboardingVersion() =>
      _onboardingVersionLoad ??= appSettingsRepository.getOnboardingVersion();

  Future<void> completeOnboarding() async {
    await appSettingsRepository.setOnboardingVersion(currentOnboardingVersion);
    _onboardingVersionLoad = Future.value(currentOnboardingVersion);
  }

  Future<void> ensureRoutineDefinitionsReady() =>
      _routineDefinitionsInitialization ??= _ensureRoutineDefinitionsReady();

  void updateLanguageCode(String code) {
    final normalized = code.toLowerCase() == 'id' ? 'id' : 'en';
    if (languageCode == normalized) return;
    languageCode = normalized;
    reminderMapper.languageCode = normalized;
    buildTodayReminderPlan.languageCode = normalized;
    reminderSettings.languageCode = normalized;
    final gateway = _reminderNotificationGateway;
    if (gateway is ReminderLocalNotificationsService) {
      unawaited(gateway.updateLanguageCode(normalized));
    }
    unawaited(reminderSettings.onLanguageChanged());
  }

  Future<void> _ensureRoutineDefinitionsReady() async {
    await ensureDefaultRoutines();
  }

  Future<void> _reconcileRoutineDefinitionChange() async {
    if (!reminderSettings.remindersEnabled ||
        reminderSettings.permissionStatus != ReminderPermissionStatus.granted) {
      return;
    }
    try {
      await scheduleTodayReminders(
        schedule: prayerScheduleSession.schedule,
        now: DateTime.now(),
      );
      await reminderSettings.refreshPermissionStatus();
    } catch (error) {
      initializationError ??= error;
    }
  }

  Future<void> _reconcileReflectionChange(ReflectionChange change) async {
    if (change.day != CalendarDay.fromDateTime(DateTime.now()) ||
        !reminderSettings.remindersEnabled ||
        reminderSettings.permissionStatus != ReminderPermissionStatus.granted) {
      return;
    }
    try {
      await scheduleTodayReminders(
        schedule: prayerScheduleSession.schedule,
        now: DateTime.now(),
      );
      await reminderSettings.refreshPermissionStatus();
    } catch (error) {
      initializationError ??= error;
    }
  }

  Future<void> _reconcileRoutineChange(RoutineRecordChange change) async {
    if (change.calendarDay != CalendarDay.fromDateTime(DateTime.now())) return;
    try {
      final record = await routineRecordRepository.getRoutineRecord(
        change.calendarDay,
        change.routineId,
      );
      if (record?.status != RoutineStatus.completed &&
          record?.status != RoutineStatus.notToday) {
        return;
      }
      final title =
          RoutineDemoData.byId(change.routineId)?.title ?? change.routineId;
      final timezone = await timezoneRepository.getDeviceTimezone();
      for (final type in [ReminderType.followUp, ReminderType.snooze]) {
        final kind = type == ReminderType.followUp ? 'follow-up' : 'snooze';
        await reminderRepository.cancel(
          Reminder(
            id: '${change.routineId}-$kind-${change.calendarDay.toDateKey()}',
            routineId: change.routineId,
            title: title,
            body: '',
            scheduledAt: DateTime.now(),
            priority: ReminderPriority.medium,
            type: type,
            dateKey: change.calendarDay.toDateKey(),
            timezoneIdentifier: timezone.ianaName,
          ),
        );
      }
      final now = DateTime.now().toUtc();
      await routineReminderStateRepository.clearSnooze(
        change.calendarDay,
        change.routineId,
        now: now,
      );
      await routineReminderStateRepository.clearFollowUp(
        change.calendarDay,
        change.routineId,
        now: now,
      );
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
    unawaited(_routineReminderChangeSubscription?.cancel());
    unawaited(_routineDefinitionChangeSubscription?.cancel());
    unawaited(_reflectionChangeSubscription?.cancel());
    unawaited(_syncMutationSubscription?.cancel());
    reminderSettings.dispose();
    syncViewModel.dispose();
    unawaited(syncCoordinator.dispose());
    authViewModel.dispose();
    unawaited(firebaseAuthService.dispose());
    if (routineRecordRepository case final RoutineRecordRepositoryData data) {
      unawaited(data.closeChanges());
    }
    if (routineRepository case final RoutineRepositoryData data) {
      unawaited(data.closeChanges());
    }
    if (reflectionRepository case final ReflectionRepositoryData data) {
      unawaited(data.closeChanges());
    }
    unawaited(databaseService.close());
    prayerScheduleSession.dispose();
    if (_ownsHttpClient) httpClient.close();
  }

  Future<void> onAppResumed() async {
    await prayerScheduleSession.refresh(requestPermission: false);
    await reminderSettings.onAppResumed();
    unawaited(syncCoordinator.onAppResumed());
  }
}
