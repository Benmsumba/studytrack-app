class AppConstants {
  // App metadata
  static const String appName = 'StudyTrack';
  static const String appVersion = '1.1.0';

  // Self-update — must match the +build_number in pubspec.yaml.
  // Bump this whenever you publish a new APK.
  static const int currentVersionCode = 1;

  // Environment placeholders. Provide real values via --dart-define.
  // Fallback to actual Supabase URL so OTA works even if --dart-define is missing.
  static const String supabaseUrl = 'https://xidpslwjxnyiptebwdff.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  static const String sentryDsn = '';

  static String get resolvedSupabaseUrl {
    const fromEnv = String.fromEnvironment('SUPABASE_URL');
    return fromEnv.isNotEmpty ? fromEnv : supabaseUrl;
  }

  static String get resolvedSupabaseAnonKey {
    const fromEnv = String.fromEnvironment('SUPABASE_ANON_KEY');
    return fromEnv.isNotEmpty ? fromEnv : supabaseAnonKey;
  }

  static String get resolvedGeminiApiKey {
    const fromEnv = String.fromEnvironment('GEMINI_API_KEY');
    return fromEnv.isNotEmpty ? fromEnv : geminiApiKey;
  }

  static String get resolvedOAuthRedirectUri {
    const fromEnv = String.fromEnvironment('OAUTH_REDIRECT_URI');
    return fromEnv.isNotEmpty ? fromEnv : 'com.studytrack.app://callback';
  }

  static bool get isSupabaseConfigured =>
      resolvedSupabaseUrl.isNotEmpty &&
      resolvedSupabaseAnonKey.isNotEmpty &&
      resolvedSupabaseUrl != 'YOUR_SUPABASE_URL' &&
      resolvedSupabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';

  static bool get isGeminiConfigured {
    final key = resolvedGeminiApiKey;
    return key.isNotEmpty && key != 'YOUR_GEMINI_API_KEY';
  }

  static String get resolvedSentryDsn {
    const fromEnv = String.fromEnvironment('SENTRY_DSN');
    return fromEnv.isNotEmpty ? fromEnv : sentryDsn;
  }

  // Spotify
  static const String spotifyClientId = '';
  static String get resolvedSpotifyClientId {
    const fromEnv = String.fromEnvironment('SPOTIFY_CLIENT_ID');
    return fromEnv.isNotEmpty ? fromEnv : spotifyClientId;
  }

  static bool get isSentryConfigured {
    final dsn = resolvedSentryDsn;
    return dsn.isNotEmpty && dsn != 'YOUR_SENTRY_DSN';
  }

  // OTA self-update: points at the public latest.json manifest in Supabase Storage.
  static String get updateCheckUrl {
    final base = resolvedSupabaseUrl;
    if (base.isEmpty || base == 'YOUR_SUPABASE_URL') {
      return '';
    }
    return '$base/storage/v1/object/public/app-updates/latest.json';
  }

  // Sections
  static const String timetableSection = 'Timetable';
  static const String modulesSection = 'Modules';
  static const String progressSection = 'Progress';
  static const String groupsSection = 'Group';

  // Auth strings
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot Password?';

  // Onboarding strings
  static const String onboardingTitle = 'Build your perfect study rhythm';
  static const String onboardingSubtitle =
      'Personalize StudyTrack in less than 2 minutes.';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String finish = 'Finish';
  static const String skip = 'Skip';

  // Modules and topics
  static const String addModule = 'Add Module';
  static const String addTopic = 'Add Topic';
  static const String moduleName = 'Module Name';
  static const String topicName = 'Topic Name';
  static const String topicRating = 'Topic Rating';
  static const String weakTopics = 'Weak Topics';

  // Study session
  static const String startSession = 'Start Session';
  static const String pauseSession = 'Pause Session';
  static const String resumeSession = 'Resume Session';
  static const String endSession = 'End Session';
  static const String pomodoro = 'Pomodoro';

  // AI tools
  static const String aiTutor = 'AI Tutor';
  static const String aiExplainer = 'Topic Explainer';
  static const String aiQuiz = 'Quiz Generator';
  static const String aiMnemonic = 'Mnemonic Generator';
  static const String aiSummary = 'Summary Generator';

  // Upload and storage
  static const String uploadNotes = 'Upload Notes';
  static const String uploadPdf = 'Upload PDF';
  static const String uploadPpt = 'Upload PPT';
  static const String chooseFile = 'Choose File';
  static const String noFileSelected = 'No file selected';

  // Progress and reports
  static const String weeklyWrapped = 'Weekly Wrapped';
  static const String shareCard = 'Share Card';
  static const String exportPdf = 'Export PDF';
  static const String streak = 'Study Streak';
  static const String achievements = 'Achievements';

  // Groups
  static const String createGroup = 'Create Group';
  static const String joinGroup = 'Join Group';
  static const String groupChat = 'Group Chat';
  static const String sharedNotes = 'Shared Notes';

  // Notifications
  static const String notifications = 'Notifications';
  static const String dailyBriefing = 'Morning Briefing';
  static const String weeklyReport = 'Sunday Weekly Report';
  static const String spacedRepetition = 'Spaced Repetition';

  // Generic actions
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String retry = 'Retry';
  static const String done = 'Done';

  // Generic states
  static const String loading = 'Loading...';
  static const String emptyState = 'Nothing here yet';
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String successSaved = 'Saved successfully';
}
