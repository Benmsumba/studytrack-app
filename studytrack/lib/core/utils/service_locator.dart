import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../repositories/auth_repository.dart';
import '../repositories/class_timetable_repository.dart';
import '../repositories/impl/auth_repository_impl.dart';
import '../repositories/impl/class_timetable_repository_impl.dart';
import '../repositories/impl/module_repository_impl.dart';
import '../repositories/impl/profile_repository_impl.dart';
import '../repositories/impl/study_group_repository_impl.dart';
import '../repositories/impl/study_session_repository_impl.dart';
import '../repositories/impl/topic_repository_impl.dart';
import '../repositories/module_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/study_group_repository.dart';
import '../repositories/study_session_repository.dart';
import '../repositories/topic_repository.dart';
import '../services/achievement_service.dart';
import '../services/export_service.dart';
import '../services/gemini_service.dart';
import '../services/notification_service.dart';
import '../services/offline_data_store.dart';
import '../services/offline_sync_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../services/voice_note_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final supabaseService = SupabaseService();
  getIt.registerSingleton<SupabaseService>(supabaseService);

  final offlineDataStore = OfflineDataStore.instance;
  try {
    await offlineDataStore.initialize();
  } catch (e) {
    debugPrint('OfflineDataStore init failed: $e');
  }
  getIt.registerSingleton<OfflineDataStore>(offlineDataStore);

  final offlineSyncService = OfflineSyncService.instance;
  getIt.registerSingleton<OfflineSyncService>(offlineSyncService);

  getIt.registerSingleton<AuthRepository>(AuthRepositoryImpl(supabaseService));
  getIt.registerSingleton<ProfileRepository>(
    ProfileRepositoryImpl(supabaseService),
  );
  getIt.registerSingleton<ClassTimetableRepository>(
    ClassTimetableRepositoryImpl(supabaseService),
  );
  getIt.registerSingleton<ModuleRepository>(
    ModuleRepositoryImpl(supabaseService),
  );
  getIt.registerSingleton<TopicRepository>(
    TopicRepositoryImpl(supabaseService),
  );
  getIt.registerSingleton<StudyGroupRepository>(
    StudyGroupRepositoryImpl(supabaseService),
  );
  getIt.registerSingleton<StudySessionRepository>(
    StudySessionRepositoryImpl(supabaseService),
  );

  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
  }
  getIt.registerSingleton<NotificationService>(notificationService);

  getIt.registerSingleton<AchievementService>(
    AchievementService(supabaseService: supabaseService),
  );
  getIt.registerSingleton<ExportService>(ExportService());
  getIt.registerSingleton<GeminiService>(GeminiService());
  getIt.registerSingleton<StorageService>(StorageService());
  getIt.registerSingleton<VoiceNoteService>(VoiceNoteService());
}

/// Reset the service locator (useful for testing)
void resetServiceLocator() {
  getIt.reset();
}
