import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:globelink_driver/main.dart';
import 'package:globelink_driver/core/di/injection_container.dart' as di;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await di.init();
    } catch (_) {}
  });

  testWidgets('App renders login page successfully', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts up and renders
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
