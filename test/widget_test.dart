import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:earnkit/main.dart';

void main() {
  testWidgets('App starts and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const EarnkitApp());

    // Splash screen shows "Earnkit" text initially
    expect(find.text('Earnkit'), findsOneWidget);
  });
}