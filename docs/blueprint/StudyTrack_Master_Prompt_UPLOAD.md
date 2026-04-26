#---

## ═══════════════════════════════════════
## PHASE 0 — PROJECT IDENTITY & CONTEXT
## ═══════════════════════════════════════

> Paste this FIRST before anything else. This is the master context
> that Copilot will remember throughout the entire build.

```
You are helping me build a Flutter mobile app called StudyTrack.
Here is the complete context for the entire project:

APP NAME: StudyTrack
PLATFORM: Android (Flutter — produces APK)
DATABASE: Supabase (PostgreSQL + Auth + Storage + Realtime)
AI: Gemini API (free tier)
BACKEND: Python FastAPI deployed on Azure Container Apps
STORAGE: Azure Blob Storage (for uploaded PDFs and PPTs)
ENVIRONMENT: GitHub Codespaces
DEPLOYMENT: GitHub Actions (automated — no manual steps)

WHO THIS IS FOR:
Health sciences students — Pharmacy, MBBS, Physiotherapy, Nursing,
Dentistry and other medical courses. Different students have different
modules so everything is self-configured by the user. Built for
students at universities in Malawi and Africa broadly.

CORE PHILOSOPHY:
Simple to use. Addictive. Saves time. Feels premium.
Never overwhelming. Every feature must earn its place.
The app must feel like a personal study companion, not a task manager.

THE 4 MAIN SECTIONS:
1. Timetable — class schedule + personal study sessions
2. Modules — self-added subjects, topics, ratings, AI tutor, notes
3. Progress — charts, analytics, Weekly Wrapped shareable cards
4. Group — study groups, topic chat, shared notes

KEY FEATURES SUMMARY:
- Onboarding wizard (6 questions, sets up app for that student)
- Self-added modules and topics (no preloaded course content)
- Topic rating system 1-10 (self-assessment after studying)
- Study session timer with Pomodoro-style flow
- AI Topic Explainer using Gemini (context-aware — reads student notes)
- AI Quiz Generator from uploaded notes
- AI Mnemonic Generator
- AI Summary Generator from uploaded PDFs and PPTs
- PDF and PPT upload per topic (stored on Azure, chunked for AI)
- Weekly Wrapped — Spotify-style full screen swipeable cards
- Shareable progress cards (generated as images for WhatsApp)
- Charts: bar chart, radar/spider chart, heatmap, line graph, donut
- Study groups with real-time topic chat (Supabase Realtime)
- Shared notes within groups (privacy toggle per upload)
- Smart notifications (context-aware — mentions exam dates and weak topics)
- Sunday weekly report notification
- Morning daily briefing notification
- Study streaks and achievement badges
- Spaced repetition alerts based on ratings
- Exam countdown with readiness indicator
- Dark mode (default dark, light mode option)
- Data export (weekly report as PDF)
- Google Drive backup

DESIGN SYSTEM:
- Default: Dark theme
- Primary color: Deep violet #7C3AED
- Accent color: Cyan #06B6D4
- Success: Emerald #10B981
- Warning: Amber #F59E0B
- Danger: Rose #F43F5E
- Background dark: #0F0F1A
- Surface dark: #1A1A2E
- Card dark: #16213E
- Font: Use Google Fonts — Outfit (headings) + Inter (body)
- Border radius: 16px for cards, 12px for buttons, 24px for bottom sheets
- All cards use subtle gradient borders
- Animations: smooth, 300ms standard duration
- Bottom navigation bar (4 tabs)
- No top app bars on main screens — use floating headers

TECH STACK SUMMARY:
Flutter (Dart) — mobile app
Supabase — auth, database, realtime, file storage
Python FastAPI — document processing backend
Azure Container Apps — hosts Python backend
Azure Blob Storage — stores uploaded PDFs and PPTs
Gemini API — all AI features
GitHub Actions — automated build and deploy pipeline
GitHub Codespaces — development environment

Remember this context for every single prompt I give you in this session.
Confirm you understand by saying "StudyTrack context loaded. Ready to build."
```

---

## ═══════════════════════════════════════
## PHASE 1 — ENVIRONMENT SETUP
## ═══════════════════════════════════════

### PROMPT 1.1 — Codespaces Dev Container

```
Create the complete .devcontainer/devcontainer.json file for StudyTrack.

Requirements:
- Base image: Ubuntu 22.04
- Install Flutter SDK (latest stable)
- Install Dart SDK (comes with Flutter)
- Install Python 3.11
- Install Node.js 18 (for any tooling)
- Install Supabase CLI
- Install Azure CLI
- Install the following VS Code extensions automatically:
  * Dart (dart-code.dart-code)
  * Flutter (dart-code.flutter)
  * Python (ms-python.python)
  * GitHub Copilot (github.copilot)
  * GitHub Copilot Chat (github.copilotchat)
  * Prettier (esbenp.prettier-vscode)
  * GitLens (eamodio.gitlens)
- Set Flutter path in environment variables
- Forward ports: 8000 (FastAPI backend), 54321 (Supabase local)
- Run flutter doctor on container creation to verify setup

Output the complete devcontainer.json file.
```

### PROMPT 1.2 — Flutter Project Initialization

```
Create the complete Flutter project structure for StudyTrack.

Run these commands in order and show me each one:
1. flutter create studytrack --org com.studytrack --platforms android
2. cd studytrack
3. Add all required dependencies to pubspec.yaml

The pubspec.yaml dependencies must include:
- supabase_flutter: latest
- google_generative_ai: latest (Gemini)
- flutter_local_notifications: latest
- fl_chart: latest (charts)
- image_gallery_saver: latest (save cards to gallery)
- share_plus: latest (share cards to WhatsApp)
- file_picker: latest (pick PDF/PPT files)
- path_provider: latest
- google_fonts: latest
- flutter_animate: latest (animations)
- lottie: latest (animated illustrations)
- shared_preferences: latest
- provider: latest (state management)
- go_router: latest (navigation)
- intl: latest (date formatting)
- percent_indicator: latest
- table_calendar: latest
- flutter_slidable: latest
- cached_network_image: latest
- shimmer: latest (loading states)
- confetti: latest (celebrations)
- screenshot: latest (generate shareable cards)
- permission_handler: latest
- flutter_svg: latest
- dotenv: latest (environment variables)

Also create the complete folder structure:
lib/
  main.dart
  app.dart
  core/
    constants/
      app_colors.dart
      app_text_styles.dart
      app_constants.dart
    services/
      supabase_service.dart
      gemini_service.dart
      notification_service.dart
      storage_service.dart
    utils/
      helpers.dart
      validators.dart
    widgets/
      custom_button.dart
      custom_text_field.dart
      loading_widget.dart
      empty_state_widget.dart
  features/
    auth/
      screens/
      widgets/
      controllers/
    onboarding/
      screens/
      widgets/
      controllers/
    timetable/
      screens/
      widgets/
      controllers/
    modules/
      screens/
      widgets/
      controllers/
    progress/
      screens/
      widgets/
      controllers/
    groups/
      screens/
      widgets/
      controllers/
    ai_tutor/
      screens/
      widgets/
      controllers/
  models/
backend/
  main.py
  requirements.txt
  document_processor.py
  chunker.py
  azure_storage.py
  Dockerfile
.github/
  workflows/
    build_apk.yml
    deploy_backend.yml

Create all files as empty with correct imports ready.
Show me the complete pubspec.yaml content.
```

### PROMPT 1.3 — Design System Foundation

```
Create the complete design system for StudyTrack.

Create lib/core/constants/app_colors.dart with:
- All colors defined as static const Color values
- Primary: #7C3AED (deep violet)
- Accent: #06B6D4 (cyan)
- Success: #10B981 (emerald)
- Warning: #F59E0B (amber)
- Danger: #F43F5E (rose)
- Background dark: #0F0F1A
- Surface dark: #1A1A2E
- Card dark: #16213E
- Text primary: #FFFFFF
- Text secondary: #9CA3AF
- Text muted: #6B7280
- Border: #2D2D44
- Include gradient definitions as LinearGradient static values
- Primary gradient: violet to cyan diagonal
- Card gradient: subtle dark gradient for card backgrounds
- Subject colors map (10 different colors for subjects):
  Pharmacology: #7C3AED, Anatomy: #EF4444, Physiology: #F59E0B,
  Biochemistry: #10B981, Pathology: #3B82F6, Surgery: #EC4899,
  Microbiology: #8B5CF6, Medicine: #06B6D4, Paediatrics: #F97316,
  Default: #6B7280

Create lib/core/constants/app_text_styles.dart with:
- Import Google Fonts (Outfit for headings, Inter for body)
- Define all text styles: displayLarge, displayMedium, headingLarge,
  headingMedium, headingSmall, bodyLarge, bodyMedium, bodySmall,
  caption, label, button
- All in white color by default

Create lib/core/constants/app_constants.dart with:
- App name, version
- Supabase URL and anon key placeholders
- Gemini API key placeholder
- All string constants for the app

Show me the complete content of all three files.
```

---

## ═══════════════════════════════════════
## PHASE 2 — SUPABASE DATABASE SETUP
## ═══════════════════════════════════════

### PROMPT 2.1 — Complete Database Schema

```
Write the complete Supabase SQL schema for StudyTrack.
Create a file called supabase/schema.sql with ALL tables.

Tables needed:

1. profiles
   - id (uuid, references auth.users, primary key)
   - name (text)
   - course (text)
   - year_level (integer)
   - prime_study_time (text) -- morning/afternoon/evening/night
   - study_hours_per_day (integer)
   - study_preference (text) -- alone/group
   - avatar_url (text)
   - streak_count (integer, default 0)
   - last_study_date (date)
   - created_at (timestamptz)
   - updated_at (timestamptz)

2. modules
   - id (uuid, primary key)
   - user_id (uuid, references profiles)
   - name (text)
   - color (text) -- hex color code
   - semester (text)
   - is_active (boolean, default true)
   - created_at (timestamptz)

3. topics
   - id (uuid, primary key)
   - module_id (uuid, references modules)
   - user_id (uuid, references profiles)
   - name (text)
   - is_studied (boolean, default false)
   - current_rating (integer) -- 1-10
   - study_count (integer, default 0)
   - last_studied_at (timestamptz)
   - next_review_at (timestamptz) -- spaced repetition
   - notes (text)
   - created_at (timestamptz)

4. topic_ratings_history
   - id (uuid, primary key)
   - topic_id (uuid, references topics)
   - user_id (uuid, references profiles)
   - rating (integer)
   - rated_at (timestamptz)

5. uploaded_notes
   - id (uuid, primary key)
   - topic_id (uuid, references topics)
   - user_id (uuid, references profiles)
   - file_name (text)
   - file_url (text) -- Azure blob URL
   - file_type (text) -- pdf/pptx
   - is_shared_with_group (boolean, default false)
   - processing_status (text) -- pending/processing/ready/failed
   - created_at (timestamptz)

6. note_chunks
   - id (uuid, primary key)
   - note_id (uuid, references uploaded_notes)
   - chunk_index (integer)
   - content (text)
   - created_at (timestamptz)

7. class_timetable
   - id (uuid, primary key)
   - user_id (uuid, references profiles)
   - subject_name (text)
   - day_of_week (integer) -- 1=Monday to 7=Sunday
   - start_time (time)
   - end_time (time)
   - room (text)
   - lecturer (text)
   - color (text)
   - created_at (timestamptz)

8. study_sessions
   - id (uuid, primary key)
   - user_id (uuid, references profiles)
   - topic_id (uuid, references topics, nullable)
   - module_id (uuid, references modules, nullable)
   - title (text)
   - scheduled_date (date)
   - start_time (time)
   - end_time (time)
   - duration_minutes (integer)
   - status (text) -- planned/completed/missed/rescheduled
   - actual_duration_minutes (integer)
   - created_at (timestamptz)

9. exams
   - id (uuid, primary key)
   - user_id (uuid, references profiles)
   - module_id (uuid, references modules)
   - title (text)
   - exam_date (date)
   - exam_time (time)
   - venue (text)
   - exam_type (text) -- written/practical/oral/continuous
   - created_at (timestamptz)

10. study_groups
    - id (uuid, primary key)
    - name (text)
    - description (text)
    - created_by (uuid, references profiles)
    - invite_code (text, unique)
    - created_at (timestamptz)

11. group_members
    - id (uuid, primary key)
    - group_id (uuid, references study_groups)
    - user_id (uuid, references profiles)
    - role (text) -- admin/member
    - joined_at (timestamptz)

12. group_messages
    - id (uuid, primary key)
    - group_id (uuid, references study_groups, nullable)
    - topic_id (uuid, references topics, nullable)
    - sender_id (uuid, references profiles)
    - content (text)
    - message_type (text) -- text/system
    - created_at (timestamptz)

13. badges
    - id (uuid, primary key)
    - user_id (uuid, references profiles)
    - badge_type (text)
    - earned_at (timestamptz)

14. weekly_reports
    - id (uuid, primary key)
    - user_id (uuid, references profiles)
    - week_start (date)
    - week_end (date)
    - topics_studied (integer)
    - topics_planned (integer)
    - sessions_completed (integer)
    - sessions_planned (integer)
    - average_rating (decimal)
    - best_subject (text)
    - weakest_subject (text)
    - streak_at_end (integer)
    - ai_summary (text)
    - created_at (timestamptz)

Add:
- Row Level Security (RLS) policies for every table
  (users can only access their own data)
- Indexes on all foreign keys and commonly queried columns
- Triggers: updated_at auto-updates on any row change
- Function to auto-generate invite codes for study groups
- Function to calculate spaced repetition next_review_at based on rating

Show the complete SQL file.
```

### PROMPT 2.2 — Supabase Service in Flutter

```
Create lib/core/services/supabase_service.dart

This is the central service that handles ALL Supabase operations.
Include complete implementations for:

AUTH:
- signUpWithEmail(email, password, name, course, yearLevel,
  primeStudyTime, studyHoursPerDay, studyPreference)
- signInWithEmail(email, password)
- signOut()
- getCurrentUser()
- isLoggedIn() bool

PROFILES:
- getProfile(userId)
- updateProfile(userId, data)
- updateStreak(userId)

MODULES:
- getModules(userId) — returns List<ModuleModel>
- addModule(userId, name, color)
- updateModule(moduleId, data)
- deleteModule(moduleId)

TOPICS:
- getTopics(moduleId) — returns List<TopicModel>
- addTopic(moduleId, userId, name)
- updateTopicRating(topicId, rating) — also saves to history
- markTopicStudied(topicId)
- updateTopicNotes(topicId, notes)
- getTopicsNeedingReview(userId) — spaced repetition query
- deleteTopics(topicId)

TIMETABLE:
- getClassTimetable(userId)
- addClassSlot(data)
- updateClassSlot(id, data)
- deleteClassSlot(id)
- getStudySessions(userId, date)
- addStudySession(data)
- updateSessionStatus(sessionId, status, actualDuration)

EXAMS:
- getExams(userId)
- addExam(data)
- updateExam(id, data)
- deleteExam(id)
- getUpcomingExams(userId) — sorted by date ascending

STUDY GROUPS:
- createGroup(name, description, createdBy)
- joinGroup(inviteCode, userId)
- getMyGroups(userId)
- getGroupMembers(groupId)
- leaveGroup(groupId, userId)

MESSAGES (Realtime):
- getTopicMessages(topicId)
- sendMessage(data)
- subscribeToMessages(topicId, onMessage callback)
- unsubscribeFromMessages()

WEEKLY REPORTS:
- saveWeeklyReport(data)
- getWeeklyReports(userId, limit)
- getLastWeekReport(userId)

UPLOADED NOTES:
- saveUploadedNote(data)
- getNotesByTopic(topicId)
- updateNoteProcessingStatus(noteId, status)
- getNoteChunks(noteId)
- saveNoteChunks(noteId, chunks List)

Use proper error handling with try-catch on every method.
Return null on errors and print error messages.
Initialize Supabase in the service constructor.
Make this a singleton using factory constructor.
```

---

## ═══════════════════════════════════════
## PHASE 3 — MODELS
## ═══════════════════════════════════════

### PROMPT 3.1 — All Data Models

```
Create all model files in lib/models/ for StudyTrack.

Create one file per model with fromJson, toJson, and copyWith methods.

Models needed:
- user_model.dart (ProfileModel)
- module_model.dart (ModuleModel)
- topic_model.dart (TopicModel)
- topic_rating_history_model.dart
- class_slot_model.dart
- study_session_model.dart
- exam_model.dart
- study_group_model.dart
- group_member_model.dart
- group_message_model.dart
- uploaded_note_model.dart
- weekly_report_model.dart
- badge_model.dart

Each model must match the Supabase schema exactly.
Add helper getters where useful — for example:
- TopicModel.masteryLevel (returns "Needs Work"/"Learning"/"Good"/"Mastered"
  based on current_rating)
- TopicModel.ratingColor (returns Color based on rating range)
- ExamModel.daysUntilExam (returns int)
- ExamModel.isUrgent (returns true if exam is within 7 days)
- StudySessionModel.isOverdue (returns bool)
- ModuleModel.subjectColor (returns Color from AppColors subject map)

Show me each complete model file.
```

---

## ═══════════════════════════════════════
## PHASE 4 — AUTHENTICATION & ONBOARDING
## ═══════════════════════════════════════

### PROMPT 4.1 — Splash Screen

```
Create lib/features/auth/screens/splash_screen.dart

Design requirements:
- Full dark background (#0F0F1A)
- Centered app logo (use an SVG book with a brain icon inside,
  deep violet and cyan gradient)
- App name "StudyTrack" in Outfit font, bold, white, size 32
- Tagline "Study smarter. Know where you stand." in Inter,
  grey, size 14, below the name
- Smooth fade-in animation using flutter_animate
- Logo pulses subtly on load
- After 2.5 seconds, check if user is logged in:
  * If logged in → navigate to /home
  * If not logged in → navigate to /onboarding-welcome
- Use go_router for navigation

Show the complete splash_screen.dart file.
```

### PROMPT 4.2 — Auth Screens

```
Create the authentication screens for StudyTrack.

Create lib/features/auth/screens/login_screen.dart:
- Dark premium design matching app design system
- Email and password fields with custom styling
- "Login" button (primary gradient background)
- "Don't have an account? Sign up" link
- Forgot password link
- Show/hide password toggle
- Loading state on button while authenticating
- Error message display (snackbar)
- Navigate to /home on success
- Navigate to /signup on signup tap

Create lib/features/auth/screens/signup_screen.dart:
- Full name, email, password, confirm password fields
- Password strength indicator
- Terms and conditions checkbox
- "Create Account" button
- On success → navigate to /onboarding (NOT home)
  (new users must complete onboarding first)
- Error message display

Create lib/features/auth/controllers/auth_controller.dart:
- Uses ChangeNotifier
- Wraps SupabaseService auth methods
- Manages loading states
- Handles error messages

All screens: dark theme, gradient accents, smooth animations,
Outfit + Inter fonts, no default Flutter blue anywhere.
Show complete code for all three files.
```

### PROMPT 4.3 — Onboarding Wizard

```
Create the complete onboarding flow for StudyTrack.

Create lib/features/onboarding/screens/onboarding_screen.dart

This is a multi-step wizard with exactly 6 steps.
Use a PageView with smooth transitions between pages.
Show a progress indicator (dots) at the top.
Each page has a "Next" button and a skip option (except last page).
Last page has "Let's Go!" button that saves data and navigates to /home.

Step 1 — Welcome & Name:
- Large friendly greeting: "Welcome to StudyTrack 👋"
- Subtitle: "Let's set up your personal study companion"
- Single text field: "What's your name?"
- Lottie animation of a student studying (use placeholder)

Step 2 — Course:
- Question: "What are you studying?"
- Text field for course name (free text — not a dropdown)
- Examples shown as chips below: Pharmacy, MBBS, Physiotherapy,
  Nursing, Dentistry, Other
- Tapping a chip fills the text field

Step 3 — Year Level:
- Question: "What year are you in?"
- Large number selector (1 through 7) with tap selection
- Selected year highlighted with primary gradient

Step 4 — Prime Study Time:
- Question: "When do you study best?"
- Four large selectable cards with icons and labels:
  🌅 Morning (5am–12pm)
  ☀️ Afternoon (12pm–5pm)
  🌆 Evening (5pm–9pm)
  🌙 Night (9pm–late)
- Only one selectable at a time
- Selected card has gradient border and filled background

Step 5 — Daily Study Hours:
- Question: "How many hours can you study daily?"
- Horizontal slider from 1 to 12
- Large number display showing selected hours
- Below: "That's X hours per week" (calculated automatically)

Step 6 — Study Style:
- Question: "How do you prefer to study?"
- Two large cards:
  🎧 Alone — "I focus best by myself"
  👥 With others — "I learn better with friends"
- Then: "Almost ready! Here's what we set up for you:"
- Summary card showing all their choices
- "Let's Go!" button

On completion:
- Save all data to Supabase profiles table
- Store onboarding_complete = true in SharedPreferences
- Navigate to /home

Show the complete onboarding_screen.dart file.
```

---

## ═══════════════════════════════════════
## PHASE 5 — MAIN APP SHELL & NAVIGATION
## ═══════════════════════════════════════

### PROMPT 5.1 — App Router

```
Create lib/app.dart with complete go_router navigation for StudyTrack.

Routes needed:
/splash → SplashScreen
/login → LoginScreen
/signup → SignupScreen
/onboarding → OnboardingScreen
/home → MainShell (bottom nav wrapper)
  /home/timetable → TimetableScreen
  /home/modules → ModulesScreen
  /home/progress → ProgressScreen
  /home/groups → GroupsScreen
/modules/:moduleId → ModuleDetailScreen
/topics/:topicId → TopicDetailScreen
/topics/:topicId/ai-tutor → AiTutorScreen
/topics/:topicId/quiz → QuizScreen
/topics/:topicId/chat → TopicChatScreen
/study-session → StudySessionScreen
/exam-countdown → ExamCountdownScreen
/weekly-wrapped → WeeklyWrappedScreen
/group/:groupId → GroupDetailScreen
/group/:groupId/chat → GroupChatScreen
/profile → ProfileScreen
/settings → SettingsScreen

Add redirect logic:
- If not authenticated → redirect to /login
- If authenticated but onboarding not complete → redirect to /onboarding
- If authenticated and onboarding complete → allow all routes

Show the complete app.dart file.
```

### PROMPT 5.2 — Main Shell with Bottom Navigation

```
Create lib/features/home/screens/main_shell.dart

This is the persistent bottom navigation wrapper.

Bottom navigation bar (4 tabs):
1. 📅 Timetable
2. 📖 Modules
3. 📊 Progress
4. 👥 Group

Design requirements:
- Floating bottom nav bar (not edge-to-edge) — elevated, rounded corners 24px
- Dark surface color (#1A1A2E) with subtle shadow
- Active tab: icon + label in primary violet color with gradient underline dot
- Inactive tab: grey icon only (no label)
- Smooth tab switch animation
- Active tab icon scales up slightly (1.1x) with spring animation

Top of every main screen:
- No standard AppBar
- Custom floating header with:
  * App name "StudyTrack" top left (small, muted)
  * Screen title below it (large, white, Outfit bold)
  * Notification bell icon top right
  * Profile avatar top right (tappable → /profile)

Also add a persistent floating "Study Now" FAB that appears
on Timetable and Modules screens only:
- Violet gradient
- Opens StudySessionScreen

Show the complete main_shell.dart file.
```

---

## ═══════════════════════════════════════
## PHASE 6 — TIMETABLE FEATURE
## ═══════════════════════════════════════

### PROMPT 6.1 — Timetable Screen

```
Create the complete Timetable feature for StudyTrack.

Create lib/features/timetable/screens/timetable_screen.dart:

Layout:
- Top: horizontal day selector (Mon-Sun) — scrollable chips
  Selected day highlighted with gradient
- Below day selector: "Today's Schedule" or selected day name
- Two sections with expandable cards:
  1. 🎓 Classes (from class_timetable table)
  2. 📖 Study Sessions (from study_sessions table)
- Each class slot card shows:
  * Subject name with colored left border (subject color)
  * Time range
  * Room and lecturer
  * Swipe left to delete, swipe right to edit
- Each study session card shows:
  * Topic/module name
  * Time range
  * Status badge (planned/completed/missed)
  * Tap → opens that topic
- Empty state: friendly illustration + "Nothing scheduled. Add a class or study session."
- FAB bottom right: "+" that opens AddScheduleBottomSheet

AddScheduleBottomSheet:
- Two tabs: "Add Class" and "Add Study Session"
- Add Class form: subject, day, start time, end time, room, lecturer
- Add Study Session form: title, linked topic (dropdown), date, start/end time

Create lib/features/timetable/screens/study_session_screen.dart:
- Full screen focus mode
- Shows topic name being studied
- Large Pomodoro timer (25 min default, customizable)
- Timer ring animation (circular progress)
- "Take a break" button (5 min break timer)
- At the end: popup asking "How well do you understand this now?"
  with a 1-10 rating slider
- Saves session as completed with actual duration
- Updates topic rating
- Shows celebration confetti animation on completion

Show complete code for both screens.
```

---

## ═══════════════════════════════════════
## PHASE 7 — MODULES FEATURE (Core Feature)
## ═══════════════════════════════════════

### PROMPT 7.1 — Modules List Screen

```
Create lib/features/modules/screens/modules_screen.dart

This is the main modules screen showing all the student's modules.

Layout:
- Search bar at top (filter modules by name)
- "Add Module" button (gradient, full width or FAB)
- Grid of module cards (2 columns)
  Each card shows:
  * Module name (bold, Outfit font)
  * Subject color (gradient card background using that color)
  * Topics count: "12 topics"
  * Mastery progress bar: "% of topics rated 7+"
  * Small circular progress indicator
  * Topics studied count vs total
- Long press card → options: Edit name, Change color, Delete
- Tap card → ModuleDetailScreen

AddModuleBottomSheet:
- Text field: Module name
- Color picker: horizontal scroll of 10 color circles
  (predefined subject colors from AppColors)
- "Add Module" save button

Show complete modules_screen.dart.
```

### PROMPT 7.2 — Module Detail & Topics Screen

```
Create lib/features/modules/screens/module_detail_screen.dart

Header:
- Module name large (Outfit bold 28px)
- Module color as gradient background on header
- Stats row: X topics | X studied | Avg rating X.X/10

Topic List:
- Vertical list of topic cards
- Each topic card shows:
  * Topic name
  * Rating badge (colored by rating: red=1-4, amber=5-6, green=7-10)
  * Rating shown as "7/10" with star icon
  * Tick icon if studied (green checkmark)
  * "Due for review" badge if next_review_at is today or past
  * Swipe left: Delete topic
  * Tap: → TopicDetailScreen

Sort/Filter options (chips row):
- All | Studied | Not Studied | Needs Review | Mastered

"Add Topic" FAB:
- Simple bottom sheet with just a text field and save button

Show complete module_detail_screen.dart.
```

### PROMPT 7.3 — Topic Detail Screen (Most Important Screen)

```
Create lib/features/modules/screens/topic_detail_screen.dart

This is the most important and feature-rich screen.

Top Section — Topic Header:
- Topic name (large, Outfit bold)
- Module name below (small, muted)
- Current rating display: large "7/10" with colored background
- Mastery level label: "Good Understanding"
- Rating history mini line chart (last 5 ratings)
- "Studied X times" counter

Middle Section — Action Buttons Grid (2x3 grid of action cards):
1. 🤖 Explain This — Opens AI explanation
2. 📝 Test Me — Opens quiz generator
3. 🧠 Mnemonic — Generates memory trick
4. 📋 Summarize Notes — Summarizes uploaded notes
5. 🔍 Predict Questions — Exam question predictor
6. 💬 Topic Chat — Opens group chat for this topic

Below Actions — Notes Section:
- "My Notes" expandable section
- Plain text area for personal notes (auto-saves)
- Character counter

Below Notes — Uploaded Files Section:
- "Lecture Notes" section header with "Upload" button
- List of uploaded PDFs/PPTs with:
  * File name
  * File type badge (PDF/PPT)
  * Processing status (pending/ready)
  * Share with group toggle
  * Delete button
- Upload triggers file picker, then uploads to Azure

Bottom — Rate This Session:
- "How well do you understand this?" label
- Horizontal 1-10 rating row (tap to select)
- Each number is a circle, selected one fills with gradient
- "Save Rating" button → saves to Supabase, updates spaced repetition

Show complete topic_detail_screen.dart.
```

---

## ═══════════════════════════════════════
## PHASE 8 — AI INTEGRATION
## ═══════════════════════════════════════

### PROMPT 8.1 — Gemini Service

```
Create lib/core/services/gemini_service.dart

This service handles ALL AI features using the Gemini API.
Use the google_generative_ai Flutter package.
Make it a singleton.

Methods to implement:

1. explainTopic({
     required String topicName,
     required String moduleName,
     required String course,
     required int currentRating,
     String? notesContent,
   }) → Future<String>

   Build a prompt that:
   - Knows the student's course
   - Knows the topic and module
   - Knows they rated it X/10 (adjust explanation depth accordingly)
   - If notesContent provided, explains based on those notes first
   - Returns a clear, structured explanation under 400 words
   - Uses analogies where helpful
   - Ends with "Key point to remember:"

2. generateQuiz({
     required String topicName,
     required String course,
     String? notesContent,
   }) → Future<List<QuizQuestion>>

   Returns 5 multiple choice questions.
   Each QuizQuestion has: question, options (List<String> of 4),
   correctIndex (int), explanation (String).
   If notesContent provided, questions come from those notes.
   Response must be JSON parseable.

3. generateMnemonic({
     required String topicName,
     required String content,
   }) → Future<String>

   Returns a creative, memorable mnemonic device for the topic.

4. summarizeNotes({
     required String topicName,
     required String notesContent,
   }) → Future<String>

   Returns a clean, structured summary under 300 words.
   Use bullet points for key facts.

5. predictExamQuestions({
     required String topicName,
     required String moduleName,
     String? notesContent,
   }) → Future<String>

   Returns 5 likely exam questions with brief explanations
   of why each might appear.

6. generateWeeklyWrappedSummary({
     required String studentName,
     required int topicsStudied,
     required double averageRating,
     required String bestSubject,
     required String weakestSubject,
     required int streak,
     required int sessionsCompleted,
     required int sessionsMissed,
   }) → Future<String>

   Returns a personal, motivating 3-4 sentence paragraph.
   Tone: encouraging coach, not robotic report.
   Mentions the student by name.
   Acknowledges wins first, then gaps, then advice for next week.

7. getStudySuggestion({
     required String studentName,
     required List<String> weakTopics,
     required List<String> upcomingExams,
     required String primeStudyTime,
   }) → Future<String>

   Returns a short 2-line actionable suggestion for today.

8. chatWithTutor({
     required String message,
     required List<Map> conversationHistory,
     required String currentTopic,
     required String course,
     String? notesContext,
   }) → Future<String>

   Multi-turn study chat. Stays focused on academic topics.
   Uses conversation history for context.
   Refuses off-topic requests politely.

Add a QuizQuestion model class in the same file.
Add proper error handling — return error message strings on failure.
Show the complete gemini_service.dart.
```

### PROMPT 8.2 — AI Tutor Screen

```
Create lib/features/ai_tutor/screens/ai_tutor_screen.dart

This is the AI study chat screen opened from a specific topic.

Design:
- Dark chat interface similar to messaging apps but premium
- Header shows: topic name + "AI Tutor" subtitle + brain icon
- Message bubbles:
  * User messages: right aligned, violet gradient background
  * AI messages: left aligned, dark card (#16213E) with subtle border
  * AI messages support markdown rendering (bold, bullet points)
- Bottom input bar:
  * Text input with send button
  * Quick action chips above keyboard:
    "Explain this" | "Test me" | "Give a mnemonic" | "Predict questions"
  * Tapping a chip sends that request automatically
- Loading indicator: animated dots when AI is thinking
- "Based on your uploaded notes" badge if notes are loaded
- Empty state: "Ask me anything about [topic name]"
  with suggested starter questions

Quick action chips behavior:
- "Explain this" → calls explainTopic() and displays result
- "Test me" → navigates to QuizScreen
- "Give a mnemonic" → calls generateMnemonic() and displays result
- "Predict questions" → calls predictExamQuestions() and displays result

Show complete ai_tutor_screen.dart.
```

### PROMPT 8.3 — Quiz Screen

```
Create lib/features/ai_tutor/screens/quiz_screen.dart

Flow:
1. Loading screen: "Generating quiz from your notes..." with animation
2. Call Gemini generateQuiz()
3. Show questions one at a time (not all at once)

Question screen design:
- Question number: "Question 2 of 5"
- Progress bar showing quiz progress
- Question text (large, clear)
- 4 answer option cards (A, B, C, D)
  * Unselected: dark card with border
  * Selected: highlights in primary violet
  * After answering:
    - Correct: turns green with checkmark
    - Wrong: turns red, correct answer turns green
- Explanation text appears after answering (Gemini explanation)
- "Next Question" button appears after answering

Results screen (after all 5 questions):
- Score: large "4/5" display
- Score message:
  * 5/5: "Perfect! You've mastered this 🏆"
  * 4/5: "Excellent work! Almost there ⭐"
  * 3/5: "Good effort! A bit more practice 📚"
  * 1-2/5: "Keep studying — you'll get there 💪"
- Suggested rating based on score:
  * 5/5 → "We suggest rating this 9/10"
  * 4/5 → "We suggest rating this 7/10"
  * 3/5 → "We suggest rating this 5/10"
  * 1-2/5 → "We suggest rating this 3/10"
- "Update My Rating" button → saves suggested rating
- "Try Again" button → generates new quiz
- "Back to Topic" button

Show complete quiz_screen.dart.
```

---

## ═══════════════════════════════════════
## PHASE 9 — DOCUMENT PROCESSING BACKEND
## ═══════════════════════════════════════

### PROMPT 9.1 — Python FastAPI Backend

```
Create the complete Python FastAPI backend for document processing.
All files go in the backend/ folder.

Create backend/requirements.txt:
fastapi
uvicorn
python-multipart
pymupdf (for PDF reading — fitz)
python-pptx (for PowerPoint reading)
azure-storage-blob
supabase
python-dotenv
httpx

Create backend/main.py:
FastAPI app with these endpoints:

POST /process-document
- Receives: file (multipart), topic_id, user_id, is_shared (bool)
- Steps:
  1. Validate file is PDF or PPTX
  2. Upload original file to Azure Blob Storage
  3. Extract text from file
  4. Split text into chunks (500 words each, 50 word overlap)
  5. Save chunks to Supabase note_chunks table
  6. Update uploaded_notes processing_status to "ready"
  7. Return: {success: true, note_id, chunks_count, file_url}

GET /health
- Returns {status: "healthy", timestamp}

Create backend/document_processor.py:
Functions:
- extract_text_from_pdf(file_bytes) → str
  Uses PyMuPDF (fitz) to extract all text from all pages
  Cleans whitespace and formatting artifacts

- extract_text_from_pptx(file_bytes) → str
  Uses python-pptx to extract text from all slides
  Includes slide titles and body text
  Separates slides with "--- Slide X ---" markers

- get_relevant_chunks(topic_name, all_chunks, max_chunks=5) → List[str]
  Simple keyword matching to find most relevant chunks
  Returns top N chunks most relevant to the topic

Create backend/chunker.py:
- split_into_chunks(text, chunk_size=500, overlap=50) → List[str]
  Splits text by words, not characters
  Maintains overlap between chunks for context continuity
  Returns list of chunk strings

Create backend/azure_storage.py:
- upload_file(file_bytes, filename, content_type) → str (blob URL)
  Uploads to Azure Blob Storage
  Returns public URL of uploaded file
- delete_file(blob_name) → bool

Create backend/Dockerfile:
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

Create backend/.env.example:
AZURE_STORAGE_CONNECTION_STRING=
AZURE_CONTAINER_NAME=studytrack-notes
SUPABASE_URL=
SUPABASE_SERVICE_KEY=

Show the complete content of all backend files.
```

### PROMPT 9.2 — Storage Service in Flutter

```
Create lib/core/services/storage_service.dart

This service handles file upload from Flutter to the Python backend.

Methods:

1. uploadNoteFile({
     required File file,
     required String topicId,
     required String userId,
     required bool isSharedWithGroup,
   }) → Future<UploadResult?>

   - Shows upload progress
   - Sends multipart POST to Azure backend /process-document
   - Polls processing status every 3 seconds until "ready"
   - Returns UploadResult with noteId and fileUrl on success
   - Returns null on failure

2. getNoteContext({
     required String topicId,
     required String searchQuery,
   }) → Future<String>

   - Gets all note_chunks for the topic from Supabase
   - Filters chunks most relevant to searchQuery (keyword match)
   - Returns combined text of top 5 most relevant chunks
   - This is what gets passed to Gemini as context

Create a UploadResult model class with: noteId, fileUrl, chunksCount.

Show complete storage_service.dart.
```

---

## ═══════════════════════════════════════
## PHASE 10 — PROGRESS & ANALYTICS
## ═══════════════════════════════════════

### PROMPT 10.1 — Progress Screen with Charts

```
Create lib/features/progress/screens/progress_screen.dart

This screen shows all analytics and charts.

Section 1 — Quick Stats Row (4 cards):
- Topics Mastered (rated 7+)
- Current Streak 🔥
- This Week's Sessions
- Average Rating

Section 2 — Weekly Performance Bar Chart:
- 7 bars (Mon-Sun)
- Height = number of topics studied that day
- Color: gradient from violet to cyan
- Selected bar shows tooltip with exact count
- Use fl_chart BarChart

Section 3 — Subject Radar Chart:
- Spider/web chart
- Each axis = one module
- Value = average rating for that module
- Filled area: semi-transparent violet
- Border: cyan
- Use fl_chart RadarChart

Section 4 — Study Consistency Heatmap:
- 12 weeks × 7 days grid
- Each square = one day
- Colors: grey (no study), light violet (some), deep violet (a lot)
- Small enough to show all 12 weeks
- Label months above

Section 5 — Topic Rating History (Line Chart):
- Dropdown to select any topic
- Line chart showing rating over time
- Dots at each rating point
- Smooth curved line
- Shows improvement trend

Section 6 — Module Progress Donut Charts:
- Horizontal scroll of module donut charts
- Each donut: % of topics rated 7+
- Center text: percentage
- Module name below

At the top right: "See Wrapped" button → WeeklyWrappedScreen

Show complete progress_screen.dart.
```

### PROMPT 10.2 — Weekly Wrapped Screen

```
Create lib/features/progress/screens/weekly_wrapped_screen.dart

This is the Spotify Wrapped style full screen swipeable experience.
Triggered every Sunday or manually from progress screen.

Uses PageView with vertical swipe (or horizontal — choose best UX).
Each page fills the entire screen — no app bar, no bottom nav.
Add smooth page transitions with scale + fade animation.

Page 1 — Intro Page:
- Gradient background (deep violet to dark)
- Animated sparkle particles (use flutter_animate)
- Large text: "Your Week in Review"
- Week date range below
- Student name
- "Swipe up to see ↑" hint at bottom

Page 2 — Topics Count:
- Bold single color background (deep cyan)
- Large animated number counting up to X (topics studied)
- Label: "topics covered"
- "this week" subtitle
- Comparison: "▲ 3 more than last week" or "▼ 2 fewer"
  (green if up, red if down)

Page 3 — Best Subject:
- Purple gradient background
- Trophy emoji large
- "Your strongest subject"
- Subject name (large, bold, Outfit)
- Average rating with stars
- Animated progress bar filling up

Page 4 — Needs Attention:
- Amber/orange gradient
- Warning emoji
- "Needs more love"
- Weakest subject name
- Average rating
- "You've got this 💪"

Page 5 — Study Streak:
- Dark background with animated fire
- Large streak number with flame emoji
- "day streak" label
- Motivational message based on streak length:
  * 1-3: "You're getting started!"
  * 4-7: "Building momentum 🔥"
  * 8-14: "You're on fire! 🔥🔥"
  * 15+: "Unstoppable! 🔥🔥🔥"

Page 6 — Sessions Stats:
- Dark teal background
- "X of Y sessions completed" large text
- Circular completion rate indicator
- Sessions missed count (shown gently, not harshly)

Page 7 — AI Summary Page:
- Dark premium background
- Brain/AI icon
- Large quote marks
- AI-generated personal paragraph (from Gemini)
- Animate text appearing word by word

Page 8 — Final Share Card:
- This is the shareable image
- Compact summary of the whole week
- Student name + week date
- 4 key stats in a grid
- App name and logo subtle at bottom
- Two buttons:
  * "Share to WhatsApp" (uses share_plus)
  * "Save to Gallery" (uses image_gallery_saver)
- Use Screenshot widget to capture this page as image

Generate button at top right of page 1 to generate fresh wrapped
if it hasn't been generated yet this week (calls Gemini).

Show complete weekly_wrapped_screen.dart.
```

---

## ═══════════════════════════════════════
## PHASE 11 — STUDY GROUPS & CHAT
## ═══════════════════════════════════════

### PROMPT 11.1 — Groups Screen

```
Create lib/features/groups/screens/groups_screen.dart

Shows the student's study groups.

Layout:
- If no groups: empty state with illustration
  "No study groups yet"
  Two buttons: "Create Group" and "Join Group"
- If has groups: list of group cards
  Each card: group name, member count, last activity time,
  group avatar (auto-generated from group name initials)
- FAB: "+" opens bottom sheet to create or join

CreateGroupBottomSheet:
- Group name field
- Description field (optional)
- "Create" button → creates group, auto-generates invite code
- After creation: shows invite code prominently
  "Share this code with friends: ABCD1234"
  Copy button copies to clipboard

JoinGroupBottomSheet:
- Single text field: "Enter invite code"
- "Join Group" button
- Shows error if code not found

Create lib/features/groups/screens/group_detail_screen.dart:
- Header: group name, member count
- Tabs:
  1. Members — list of member cards with name, course, year
     Admin badge if admin
     Admin can remove members
  2. Shared Notes — list of notes shared to group
     Organized by topic
     Can open notes or save locally
  3. Sessions — shared study sessions
     Members can RSVP to sessions
  4. Chat — group general chat

All group realtime chat uses Supabase Realtime.

Show complete code for both screens.
```

### PROMPT 11.2 — Topic Chat Screen

```
Create lib/features/groups/screens/topic_chat_screen.dart

A focused chat screen for discussing a specific topic with study group.

Design:
- Chat header: topic name + module name + group name
- Message list (Supabase Realtime — live updates)
- Each message shows:
  * Sender avatar (initials circle, colored by user)
  * Sender name + course + year
  * Message content
  * Timestamp
  * Own messages on right, others on left
- Input bar with:
  * Text field
  * Send button
  * Quick starter prompts (chips): "Anyone struggling with this?" |
    "Can someone explain?" | "Exam question tip 💡"
- Anonymous flag button: flags the topic as "I'm struggling with this"
  anonymously. If 3+ members flag it → shows banner:
  "Multiple people are struggling with this topic"

Show complete topic_chat_screen.dart.
```

---

## ═══════════════════════════════════════
## PHASE 12 — NOTIFICATIONS
## ═══════════════════════════════════════

### PROMPT 12.1 — Notification Service

```
Create lib/core/services/notification_service.dart

Complete notification setup using flutter_local_notifications.

Notification channels:
1. daily_briefing — Morning daily briefing
2. study_reminders — Study session reminders
3. weekly_report — Sunday weekly report
4. spaced_repetition — Topic review reminders
5. exam_countdown — Exam warnings

Methods:

1. initialize() — Sets up notification channels and permissions

2. scheduleDailyBriefing({
     required TimeOfDay time,
     required String studentName,
   })
   Schedules daily notification at student's prime study time.
   Content: "Good [morning/evening] [name]! Here's your day:
   [X classes + Y study sessions]. Tap to see your schedule."

3. scheduleWeeklyReport()
   Schedules every Sunday at 8pm.
   Content: "Your weekly wrapped is ready 📊
   See how your week went!"

4. scheduleStudySession({
     required StudySessionModel session,
   })
   Fires 15 minutes before session.
   Content: "Study session starting soon: [topic name]"

5. scheduleSpacedRepetitionReminder({
     required TopicModel topic,
   })
   Fires on next_review_at date.
   Content: "Time to review [topic name]!
   You rated it [X/10] — keeping it fresh 🧠"

6. scheduleExamCountdown({
     required ExamModel exam,
   })
   Fires at: 7 days, 3 days, 1 day, morning of exam
   Content: "[X] days until [exam name]!
   [weak topic] still needs attention."

7. cancelAll() — Cancels all scheduled notifications

Show complete notification_service.dart.
```

---

## ═══════════════════════════════════════
## PHASE 13 — SHAREABLE CARDS GENERATOR
## ═══════════════════════════════════════

### PROMPT 13.1 — Cards Generator

```
Create lib/features/progress/widgets/shareable_cards.dart

These are Flutter widgets that generate shareable image cards.
Each card is captured using the Screenshot package as an image
and saved to gallery or shared via share_plus.

Create these shareable card widgets:

1. WeeklyReportCard({
     required String studentName,
     required String course,
     required int weekNumber,
     required int topicsStudied,
     required double averageRating,
     required int streak,
     required String bestSubject,
   })
   Design: Dark background, violet gradient header
   Student name large at top
   Stats in clean 2x2 grid
   App logo bottom right

2. TopicMasteredCard({
     required String topicName,
     required String moduleName,
     required int rating,
     required int studyCount,
     required int previousRating,
   })
   Design: Emerald/green gradient
   Trophy emoji large
   Topic name large
   Rating journey: "4/10 → 9/10"

3. ExamCountdownCard({
     required String examName,
     required int daysRemaining,
     required double readinessPercent,
   })
   Design: Amber gradient (urgent) or violet (normal)
   Large countdown number
   Readiness progress bar
   Motivational message

4. StreakCard({
     required String studentName,
     required int streakCount,
   })
   Design: Dark with fire gradient
   Huge streak number
   Fire emoji animated if possible

5. MonthlyWrappedCard({
     required String studentName,
     required String month,
     required int topicsCovered,
     required double hoursStudied,
     required String strongestSubject,
     required String weakestSubject,
   })
   Design: Full dark premium — mimics Spotify Wrapped aesthetic
   Month name large at top
   Stats listed below with icons
   App branding at bottom

Each card:
- Fixed size: 1080x1080px (scaled down for display)
- Uses GlobalKey for Screenshot capture
- Has a static create() method that shows a preview dialog
  with "Save to Gallery" and "Share" buttons

Create lib/features/progress/controllers/share_controller.dart:
- captureAndShare(GlobalKey key) → shares card image
- captureAndSave(GlobalKey key) → saves to gallery
- Handles permissions for storage access

Show complete shareable_cards.dart and share_controller.dart.
```

---

## ═══════════════════════════════════════
## PHASE 14 — PROFILE & SETTINGS
## ═══════════════════════════════════════

### PROMPT 14.1 — Profile Screen

```
Create lib/features/profile/screens/profile_screen.dart

Layout:
Top section:
- Avatar (initials circle, large, gradient background)
- Edit avatar option
- Student name (large)
- Course + Year level
- "Joined [date]" subtitle

Stats row (3 cards):
- Total Topics: X
- Total Mastered: X
- Longest Streak: X days

Badges section:
- Grid of earned badges (colored) and locked badges (grey)
- Badges:
  * 🌱 First Step — Added first topic
  * 🔥 Week Warrior — 7-day streak
  * 🏆 Perfectionist — First 10/10 rating
  * 📚 Bookworm — 50 topics studied
  * 🌟 Master — 10 topics rated 8+
  * 🦉 Night Owl — Studied after 11pm 5 times
  * ⚡ Speed Runner — Completed 5 sessions in one day
  * 💪 Comeback Kid — Studied after 3+ day break
  * 🎯 Sharp Shooter — Got 5/5 on a quiz
  * 👥 Team Player — Joined a study group
- Locked badges show "???" name and grey icon
- Tap earned badge → shows earned date and description

Export section:
- "Export Weekly Report" → generates PDF of last week's data
- "Backup to Google Drive" → one tap backup

Show complete profile_screen.dart.
```

### PROMPT 14.2 — Settings Screen

```
Create lib/features/settings/screens/settings_screen.dart

Sections:

Study Preferences:
- Prime study time (time picker)
- Daily study goal (hours slider)
- Pomodoro duration (minutes selector: 15, 20, 25, 30, 45)

Notifications:
- Daily briefing toggle + time picker
- Study session reminders toggle
- Exam countdown alerts toggle
- Spaced repetition reminders toggle
- Weekly wrapped reminder toggle

Appearance:
- Dark/Light mode toggle (dark default)
- App language (English only for now — future feature)

Account:
- Edit profile button
- Change password button
- Backup data (Google Drive)
- Export all data (JSON download)
- Delete account (with confirmation dialog)

About:
- App version
- "Made with ❤️ for health sciences students"
- Contact/feedback link

Show complete settings_screen.dart.
```

---

## ═══════════════════════════════════════
## PHASE 15 — GITHUB ACTIONS CI/CD
## ═══════════════════════════════════════

### PROMPT 15.1 — APK Build Workflow

```
Create .github/workflows/build_apk.yml

This workflow automatically builds the Flutter APK whenever
I push to the main branch.

Requirements:
- Trigger: push to main branch AND pull requests to main
- Runner: ubuntu-latest
- Steps in order:
  1. Checkout code
  2. Set up Java 17 (required for Flutter Android builds)
  3. Set up Flutter (latest stable channel)
  4. Cache Flutter dependencies (speeds up builds)
  5. Run: flutter pub get
  6. Create .env file from GitHub Secrets:
     SUPABASE_URL, SUPABASE_ANON_KEY, GEMINI_API_KEY, BACKEND_URL
  7. Run: flutter analyze (check for errors)
  8. Run: flutter build apk --release --split-per-abi
     (generates smaller APKs for different architectures)
  9. Upload APK artifacts:
     - app-arm64-v8a-release.apk (main one — modern phones)
     - app-armeabi-v7a-release.apk (older phones)
  10. Create a GitHub Release automatically with:
      - Release name: "StudyTrack v[date]-[commit short sha]"
      - Attach both APKs to the release
      - Auto-generate release notes from commit messages

Also add:
- Build status badge generation
- Notification on build failure (to commit author)
- Build takes less than 10 minutes (use caching aggressively)

Show the complete build_apk.yml file.
```

### PROMPT 15.2 — Backend Deploy Workflow

```
Create .github/workflows/deploy_backend.yml

This workflow automatically deploys the Python FastAPI backend
to Azure Container Apps whenever I push changes to the backend/ folder.

Requirements:
- Trigger: push to main, only when files in backend/ change
- Runner: ubuntu-latest
- Steps:
  1. Checkout code
  2. Login to Azure using service principal credentials
     (stored as GitHub Secrets: AZURE_CREDENTIALS)
  3. Login to Azure Container Registry
  4. Build Docker image from backend/Dockerfile
  5. Tag image: studytrack-backend:latest and :commit-sha
  6. Push image to Azure Container Registry
  7. Deploy to Azure Container Apps:
     - Container app name: studytrack-backend
     - Set environment variables from GitHub Secrets:
       AZURE_STORAGE_CONNECTION_STRING
       SUPABASE_URL
       SUPABASE_SERVICE_KEY
       AZURE_CONTAINER_NAME
  8. Get the deployed URL and log it
  9. Health check: curl /health endpoint

Also create azure-setup-instructions.md explaining:
- How to create the Azure Container Registry
- How to create the Azure Container App
- How to generate AZURE_CREDENTIALS service principal
- How to add all GitHub Secrets
- All using Azure Student credits (within free tier)

Show complete deploy_backend.yml and azure-setup-instructions.md.
```

---

## ═══════════════════════════════════════
## PHASE 16 — ANDROID CONFIGURATION
## ═══════════════════════════════════════

### PROMPT 16.1 — Android Setup

```
Configure the Android project for StudyTrack production release.

1. Update android/app/build.gradle:
   - applicationId: "com.studytrack.app"
   - minSdkVersion: 21 (Android 5.0 — covers 99% of devices)
   - targetSdkVersion: 34
   - compileSdkVersion: 34
   - versionCode: 1
   - versionName: "1.0.0"
   - Enable multidex
   - Add signing config for release builds

2. Update android/app/src/main/AndroidManifest.xml:
   Add all required permissions:
   - INTERNET
   - READ_EXTERNAL_STORAGE
   - WRITE_EXTERNAL_STORAGE
   - READ_MEDIA_IMAGES (Android 13+)
   - NOTIFICATIONS
   - VIBRATE
   - RECEIVE_BOOT_COMPLETED (for notification persistence)
   Add FileProvider for sharing generated images
   Set app name to "StudyTrack"
   Set correct launch icon reference

3. Create app icons:
   Write instructions for generating app icon from this description:
   "A book with a glowing brain emerging from it, deep violet and
   cyan gradient, dark background, minimal and modern"
   Using flutter_launcher_icons package.

4. Create android/key.properties template:
   storePassword=
   keyPassword=
   keyAlias=studytrack
   storeFile=../keystore/studytrack.jks
   (Add instructions for generating keystore)

5. Update android/gradle.properties:
   - Enable R8 code shrinking
   - Enable resource shrinking
   - Set correct Gradle memory settings

Show all updated files and clear instructions for each step.
```

---

## ═══════════════════════════════════════
## PHASE 17 — FINAL INTEGRATION & POLISH
## ═══════════════════════════════════════

### PROMPT 17.1 — State Management Setup

```
Set up complete Provider state management for StudyTrack.

Create a provider for each feature:

lib/features/auth/controllers/auth_provider.dart
- currentUser (ProfileModel?)
- isLoading (bool)
- errorMessage (String?)
- login(), logout(), register()

lib/features/modules/controllers/modules_provider.dart
- modules (List<ModuleModel>)
- isLoading
- loadModules(userId)
- addModule(), updateModule(), deleteModule()
- selectedModule (ModuleModel?)

lib/features/timetable/controllers/timetable_provider.dart
- classSlots (List<ClassSlotModel>)
- studySessions (List<StudySessionModel>)
- selectedDate (DateTime)
- loadTimetable(), addClassSlot(), addStudySession()
- completeSession(), missSession()

lib/features/progress/controllers/progress_provider.dart
- weeklyReport (WeeklyReportModel?)
- isGeneratingWrapped (bool)
- generateWeeklyReport(userId)
- loadChartData(userId)

lib/features/groups/controllers/groups_provider.dart
- myGroups (List<StudyGroupModel>)
- selectedGroup (StudyGroupModel?)
- messages (List<GroupMessageModel>)
- loadGroups(), createGroup(), joinGroup()
- sendMessage(), subscribeToMessages()

Register all providers in main.dart using MultiProvider.
Show how to wire everything together in main.dart.
Show all provider files.
```

### PROMPT 17.2 — Error Handling & Loading States

```
Create a consistent error handling and loading system for StudyTrack.

Create lib/core/widgets/loading_widget.dart:
- Shimmer loading cards that match the actual content shape
- Full screen loading with app logo pulsing
- Inline loading for smaller sections

Create lib/core/widgets/error_widget.dart:
- Friendly error states (not crash screens)
- "Something went wrong" with retry button
- Different messages for: no internet, server error, auth error

Create lib/core/widgets/empty_state_widget.dart:
- Pass: title, subtitle, illustration name, action button
- Reusable across all screens
- Uses Lottie animations for illustrations

Create lib/core/utils/helpers.dart:
- showSuccessSnackbar(context, message)
- showErrorSnackbar(context, message)
- showLoadingDialog(context)
- hideLoadingDialog(context)
- formatDate(DateTime) → "Mon, 14 Apr"
- formatTime(TimeOfDay) → "07:30 PM"
- getGreeting() → "Good morning" / "Good afternoon" etc.
- calculateReadinessScore(List<TopicModel> topics) → double (0-100)
- getSpacedRepetitionDate(int rating) → DateTime
  * rating 1-3: review in 1 day
  * rating 4-5: review in 3 days
  * rating 6-7: review in 7 days
  * rating 8-9: review in 14 days
  * rating 10: review in 30 days

Show all complete files.
```

### PROMPT 17.3 — Streak & Badge System

```
Create the streak and badge system for StudyTrack.

Create lib/core/services/achievement_service.dart:

Streak logic:
- checkAndUpdateStreak(userId):
  * Get last_study_date from profile
  * If last_study_date is yesterday → increment streak
  * If last_study_date is today → no change
  * If last_study_date is before yesterday → reset to 1
  * Save updated streak to Supabase
  * Return StreakUpdateResult with: newStreak, streakBroken (bool)

Badge checking logic:
- checkAllBadges(userId):
  Checks every badge condition and awards any not yet earned.
  Call this after every significant user action.

Badge conditions:
- first_step: added first topic
- week_warrior: streak >= 7
- perfectionist: any topic rated 10
- bookworm: total topics studied >= 50
- master: topics rated 8+ count >= 10
- night_owl: studied after 23:00 on 5 different days
- speed_runner: 5 sessions completed in one day
- comeback_kid: resumed after 3+ day break
- sharp_shooter: got 5/5 on any quiz
- team_player: joined first study group
- century: 100 topics covered total
- month_streak: 30-day streak

- awardBadge(userId, badgeType):
  Saves to badges table in Supabase
  Triggers a celebration animation in UI

Create a BadgeCelebrationOverlay widget:
- Full screen overlay with confetti animation
- Shows badge icon + name + description
- "Awesome! You earned a badge 🏆"
- Auto-dismisses after 3 seconds or tap to dismiss

Show complete achievement_service.dart and badge_celebration_overlay.dart.
```

---

## ═══════════════════════════════════════
## PHASE 18 — TESTING & APK GENERATION
## ═══════════════════════════════════════

### PROMPT 18.1 — Pre-Build Checklist

```
Create a pre-build checklist script for StudyTrack.

Create scripts/pre_build_check.sh:
A bash script that runs before generating the final APK.
It checks:
1. flutter analyze — no errors
2. All environment variables are set (.env file exists)
3. Supabase connection works
4. Gemini API key is valid
5. Android signing keystore exists
6. All required permissions in AndroidManifest.xml
7. App icons are generated (check if mipmap folders have files)
8. pubspec.yaml version is set correctly
9. Backend Dockerfile exists
10. GitHub Actions workflow files exist

Print green checkmark for pass, red X for fail.
Print final summary: "X/10 checks passed. Ready to build: YES/NO"

Also create scripts/generate_release_apk.sh:
Script that:
1. Runs pre_build_check.sh first
2. Cleans build: flutter clean
3. Gets dependencies: flutter pub get
4. Builds release APK: flutter build apk --release --split-per-abi
5. Copies APKs to a release/ folder in project root
6. Prints APK file paths and sizes
7. Prints: "APK ready! Share app-arm64-v8a-release.apk with friends"

Show both complete scripts.
```

### PROMPT 18.2 — Final Build Command

```
Give me the exact sequence of final commands to:

1. Commit all code to GitHub from Codespaces
2. Push to main branch
3. Monitor the GitHub Actions APK build
4. Download the completed APK from GitHub Releases
5. Install on my Android phone for testing

Also give me:
- The exact git commands for initial push
- How to add all GitHub Secrets (list every secret needed and where to get the value)
- How to find the APK download link after build completes
- How to install APK on Android (enable unknown sources steps)
- How to share the APK with friends via WhatsApp

Make all commands copy-paste ready.
```

---

## ═══════════════════════════════════════
## REFERENCE — ALL ENVIRONMENT VARIABLES
## ═══════════════════════════════════════

```
Create a .env.example file in the project root with ALL variables:

# Flutter App (.env in lib/)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GEMINI_API_KEY=your-gemini-api-key
BACKEND_URL=https://your-azure-container-app.azurecontainerapps.io

# GitHub Secrets (set in repo Settings → Secrets)
SUPABASE_URL=
SUPABASE_ANON_KEY=
GEMINI_API_KEY=
BACKEND_URL=
AZURE_CREDENTIALS=         # JSON from az ad sp create-for-rbac
AZURE_REGISTRY_NAME=       # Your ACR name
AZURE_CONTAINER_APP_NAME=studytrack-backend
AZURE_RESOURCE_GROUP=studytrack-rg
KEY_STORE_PASSWORD=        # Your keystore password
KEY_PASSWORD=              # Your key password
KEY_ALIAS=studytrack
KEY_STORE_BASE64=          # base64 encoded keystore file

# Backend (.env in backend/)
AZURE_STORAGE_CONNECTION_STRING=
AZURE_CONTAINER_NAME=studytrack-notes
SUPABASE_URL=
SUPABASE_SERVICE_KEY=      # Service role key (not anon key)
```

---

## ═══════════════════════════════════════
## QUICK REFERENCE — APP SCREENS SUMMARY
## ═══════════════════════════════════════

```
Total screens: 24

Auth & Setup (4):
/splash → SplashScreen
/login → LoginScreen
/signup → SignupScreen
/onboarding → OnboardingScreen (6 steps)

Main (4):
/home/timetable → TimetableScreen
/home/modules → ModulesScreen
/home/progress → ProgressScreen
/home/groups → GroupsScreen

Modules & Topics (3):
/modules/:id → ModuleDetailScreen
/topics/:id → TopicDetailScreen
/topics/:id/ai-tutor → AiTutorScreen

Study (2):
/study-session → StudySessionScreen (Pomodoro timer)
/topics/:id/quiz → QuizScreen

Progress (2):
/weekly-wrapped → WeeklyWrappedScreen
/exam-countdown → ExamCountdownScreen

Groups (3):
/group/:id → GroupDetailScreen
/group/:id/chat → GroupChatScreen
/topics/:id/chat → TopicChatScreen

User (3):
/profile → ProfileScreen
/settings → SettingsScreen
/notifications → NotificationsScreen (list of all past alerts)

Total features: 47
AI-powered features: 8
Shareable card types: 5
Chart types: 5
Badge types: 12
```

---

*StudyTrack Master Prompt — Complete*
*Built for health sciences students across Africa*
*Stack: Flutter + Supabase + Gemini + Azure + GitHub Actions*
*Cost to build and run: $0*
 StudyTrack Master Prompt Upload

Paste the latest master prompt here.

This file is the staging copy for the blueprint prompt that governs the phases and build rules.

When you update this file, keep the phase structure intact so Copilot can use it consistently as the project blueprint.

## Notes

- Keep the full prompt content here.
- Do not remove phase headings.
- If this file changes, I will treat it as the active blueprint source during implementation.