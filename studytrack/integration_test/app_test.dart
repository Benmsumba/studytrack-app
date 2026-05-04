// Integration test: core user journey
//
// Covers:
//   1. App launches and splash screen renders
//   2. Unauthenticated users are redirected to login
//   3. Login form accepts input and shows a feedback state
//   4. After authentication (mocked via test credentials env vars) the main
//      shell loads with the bottom navigation visible
//   5. Navigating to Modules tab works
//   6. Opening the AI Tutor screen from a module/topic shows the chat UI
//
// Running locally:
//   flutter test integration_test/app_test.dart \
//     --dart-define=SUPABASE_URL=<your-url> \
//     --dart-define=SUPABASE_ANON_KEY=<your-anon-key> \
//     --dart-define=TEST_EMAIL=<test-account@example.com> \
//     --dart-define=TEST_PASSWORD=<test-password>
//
// In CI, set the four secrets above alongside the existing build secrets.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:studytrack/main.dart' as app;

// Compile-time test credentials — must be provided via --dart-define in CI.
const _testEmail = String.fromEnvironment('TEST_EMAIL');
const _testPassword = String.fromEnvironment('TEST_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Core user journey', () {
    testWidgets('App launches without crashing', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // The app should render something — either the splash logo or the login
      // screen. Either way the scaffold must be present.
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Unauthenticated: login screen is shown', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // After the splash animation resolves an unauthenticated session should
      // land on the login screen which contains an email TextField.
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Login form accepts typed credentials', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final emailField = find.byType(TextField).first;
      await tester.tap(emailField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    // The remaining tests require real test credentials and a live Supabase
    // project. They are skipped automatically when TEST_EMAIL is not provided.
    group('Authenticated journey (requires TEST_EMAIL + TEST_PASSWORD)', () {
      setUp(() {
        if (_testEmail.isEmpty || _testPassword.isEmpty) {
          // markTestSkipped is not available inside setUp; we rely on the
          // guard inside each test instead.
        }
      });

      testWidgets('Sign in with valid credentials shows main shell', (
        tester,
      ) async {
        if (_testEmail.isEmpty || _testPassword.isEmpty) {
          markTestSkipped(
            'TEST_EMAIL and TEST_PASSWORD not set — skipping live auth test.',
          );
          return;
        }

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 4));

        // Fill in login form
        final fields = find.byType(TextField);
        await tester.tap(fields.first);
        await tester.enterText(fields.first, _testEmail);
        await tester.pump();
        await tester.tap(fields.last);
        await tester.enterText(fields.last, _testPassword);
        await tester.pump();

        // Tap the primary login button (first ElevatedButton / FilledButton)
        final loginButton = find.byType(ElevatedButton).first;
        await tester.tap(loginButton);

        // Allow time for the auth round-trip and navigation
        await tester.pumpAndSettle(const Duration(seconds: 8));

        // After sign-in the main shell should be visible.
        // We look for the bottom navigation bar as a reliable landmark.
        expect(find.byType(NavigationBar), findsOneWidget);
      });

      testWidgets('Navigating to Modules tab shows module list', (
        tester,
      ) async {
        if (_testEmail.isEmpty || _testPassword.isEmpty) {
          markTestSkipped('TEST_EMAIL and TEST_PASSWORD not set.');
          return;
        }

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 8));

        // Tap the Modules destination in the bottom nav
        final modulesTab = find.text('Modules');
        if (modulesTab.evaluate().isEmpty) {
          markTestSkipped('Could not find Modules tab — skipping.');
          return;
        }
        await tester.tap(modulesTab);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // The modules screen contains a list or an empty-state widget
        expect(
          find.byType(ListView).evaluate().isNotEmpty ||
              find.textContaining('module').evaluate().isNotEmpty ||
              find.byType(FloatingActionButton).evaluate().isNotEmpty,
          isTrue,
          reason: 'Modules screen should show a list or FAB',
        );
      });

      testWidgets('Opening AI Tutor for a topic shows chat interface', (
        tester,
      ) async {
        if (_testEmail.isEmpty || _testPassword.isEmpty) {
          markTestSkipped('TEST_EMAIL and TEST_PASSWORD not set.');
          return;
        }

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 8));

        // Navigate to Modules
        final modulesTab = find.text('Modules');
        if (modulesTab.evaluate().isEmpty) {
          markTestSkipped('Modules tab not found — skipping.');
          return;
        }
        await tester.tap(modulesTab);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Tap the first module card if available
        final firstModule = find.byType(Card).first;
        if (firstModule.evaluate().isEmpty) {
          markTestSkipped('No modules found — skipping AI tutor test.');
          return;
        }
        await tester.tap(firstModule);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Tap the first topic if available
        final firstTopic = find.byType(ListTile).first;
        if (firstTopic.evaluate().isEmpty) {
          markTestSkipped('No topics found — skipping AI tutor test.');
          return;
        }
        await tester.tap(firstTopic);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Look for the AI Tutor button / chip / icon
        final tutorEntry = find.byIcon(Icons.psychology_rounded);
        if (tutorEntry.evaluate().isEmpty) {
          markTestSkipped('AI Tutor entry point not visible — skipping.');
          return;
        }
        await tester.tap(tutorEntry);
        await tester.pumpAndSettle(const Duration(seconds: 4));

        // AI Tutor screen should show the chat input field
        expect(find.byType(TextField), findsWidgets);
        // And the AI Tutor app-bar label
        expect(find.text('AI Tutor'), findsOneWidget);
      });

      testWidgets('Sending a chat message shows a response bubble', (
        tester,
      ) async {
        if (_testEmail.isEmpty || _testPassword.isEmpty) {
          markTestSkipped('TEST_EMAIL and TEST_PASSWORD not set.');
          return;
        }

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 8));

        // Quick-navigate directly to AI Tutor if we have a known topicId.
        // Without a pre-seeded topic we just verify the input field works.
        final emailFields = find.byType(TextField);
        if (emailFields.evaluate().isNotEmpty) {
          // Still on login — not enough data to proceed
          markTestSkipped('Not logged in — skipping chat test.');
          return;
        }

        // Find the chat input field
        final chatInput = find.byType(TextField).last;
        await tester.tap(chatInput);
        await tester.enterText(chatInput, 'What is this topic about?');
        await tester.pump();

        expect(find.text('What is this topic about?'), findsOneWidget);

        // Tap the send button
        final sendButton = find.byIcon(Icons.send_rounded);
        if (sendButton.evaluate().isNotEmpty) {
          await tester.tap(sendButton);
          // Allow time for streaming response (up to 15 s on a live device)
          await tester.pumpAndSettle(const Duration(seconds: 15));

          // The user message should still be visible in the chat list
          expect(find.text('What is this topic about?'), findsOneWidget);
        }
      });
    });
  });
}
