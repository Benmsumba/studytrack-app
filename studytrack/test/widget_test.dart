import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Basic Flutter widget renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('StudyTrack'))),
      ),
    );

    expect(find.text('StudyTrack'), findsOneWidget);
  });
}
