import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homesure_ai/screens/assessment/surebot_screen.dart';

void main() {
  testWidgets('SureBot can switch its welcome screen to Kannada', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SureBotScreen()));
    await tester.pumpAndSettle();

    expect(find.text("I'm SureBot"), findsOneWidget);
    expect(find.text("Let's Begin"), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ಕನ್ನಡ').last);
    await tester.pumpAndSettle();

    expect(find.text('ನಾನು SureBot'), findsOneWidget);
    expect(find.text('ಪ್ರಾರಂಭಿಸೋಣ'), findsOneWidget);
    expect(find.text('ನಮಸ್ಕಾರ 👋'), findsOneWidget);
  });
}
