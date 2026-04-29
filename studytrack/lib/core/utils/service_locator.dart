import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';
import '../repositories/impl/auth_repository_impl.dart';
import '../repositories/impl/module_repository_impl.dart';
import '../repositories/impl/study_group_repository_impl.dart';
import '../repositories/impl/study_session_repository_impl.dart';
import '../repositories/impl/topic_repository_impl.dart';
import '../repositories/module_repository.dart';
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

/// Service locator singleton for dependency injection
final getIt = GetIt.instance;

/// Initialize all service dependencies
/// Call this in main.dart before runApp()
Future<void> setupServiceLocator() async {
  // Initialize core Supabase service
  final supabaseService = SupabaseService();
  getIt.registerSingleton<SupabaseService>(supabaseService);

  // Initialize offline services
  final offlineDataStore = OfflineDataStore();
  await offlineDataStore.initialize();
  getIt.registerSingleton<OfflineDataStore>(offlineDataStore);

  final offlineSyncService = OfflineSyncService.instance;
  getIt.registerSingleton<OfflineSyncService>(offlineSyncService);

  // Register repositories
  getIt.registerSingleton<AuthRepository>(AuthRepositoryImpl(supabaseService));
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

  // Initialize platform services
  final notificationService = NotificationService();
  await notificationService.initialize();
  getIt.registerSingleton<NotificationService>(notificationService);

  final achievementService = AchievementService(supabaseService);
  getIt.registerSingleton<AchievementService>(achievementService);

  final exportService = ExportService();
  getIt.registerSingleton<ExportService>(exportService);

  final geminiService = GeminiService();
  getIt.registerSingleton<GeminiService>(geminiService);

  final storageService = StorageService();
  getIt.registerSingleton<StorageService>(storageService);

  final voiceNoteService = VoiceNoteService();
  getIt.registerSingleton<VoiceNoteService>(voiceNoteService);
}

/// Reset the service locator (useful for testing)
void resetServiceLocator() {
  getIt.reset();
}
