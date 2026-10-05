import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binova_app/core/design_system/binova_tokens.dart';
import 'package:binova_app/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  testWidgets('onboarding shows the first product message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: BinovaColors.carbon),
        ),
        home: const OnboardingPage(),
      ),
    );

    expect(find.text('Todo tu banco, en un solo lugar.'), findsOneWidget);
    expect(find.text('Omitir'), findsOneWidget);
  });
}
