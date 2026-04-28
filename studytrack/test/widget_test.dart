// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:studytrack/app.dart';
import 'package:studytrack/core/services/offline_sync_service.dart';

void main() {
  testWidgets('StudyTrack app renders', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    await tester.pumpWidget(
      ChangeNotifierProvider<OfflineSyncService>.value(
        value: OfflineSyncService.instance,
        child: const StudyTrackApp(),
      ),
    );

    expect(find.byType(StudyTrackApp), findsOneWidget);
  });
}
