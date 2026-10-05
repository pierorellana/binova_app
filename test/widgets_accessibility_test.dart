import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binova_app/core/design_system/binova_widgets.dart';
import 'package:binova_app/features/home/presentation/widgets/home_balance_card.dart';
import 'package:binova_app/features/home/presentation/widgets/home_data.dart';
import 'package:binova_app/features/home/presentation/widgets/home_header.dart';

void main() {
  testWidgets('balance card toggles its value and exposes accessible labels',
      (tester) async {
    var toggleCalls = 0;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => HomeBalanceCard(
            data: _homeData(),
            hidden: toggleCalls > 0,
            onToggle: () {
              toggleCalls++;
              setState(() {});
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp('Saldo total')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Ocultar saldo')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Mostrar saldo')), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'\$3,313.65')), findsOneWidget);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

    await tester.tap(find.byType(BnPressable));
    await tester.pumpAndSettle();

    expect(toggleCalls, 1);
    expect(find.bySemanticsLabel(RegExp('Mostrar saldo')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Saldo oculto')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'\$3,313.65')), findsNothing);

    semantics.dispose();
  });

  testWidgets('home header exposes labeled profile and notification actions',
      (tester) async {
    var profileCalls = 0;
    var notificationCalls = 0;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        HomeHeader(
          displayName: 'Pierre Orellana',
          onAvatar: () => profileCalls++,
          onBell: () => notificationCalls++,
          hasUnread: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final profile = find.bySemanticsLabel(RegExp('Perfil de Pierre'));
    final notifications =
        find.bySemanticsLabel(RegExp('Notificaciones, sin leer'));
    expect(profile, findsOneWidget);
    expect(notifications, findsOneWidget);

    await tester.tap(profile);
    await tester.tap(notifications);
    await tester.pump();

    expect(profileCalls, 1);
    expect(notificationCalls, 1);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

    semantics.dispose();
  });
}

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

HomeData _homeData() => HomeData(
      symbol: r'$',
      balance: 3313.65,
      income: 1200,
      expense: 350,
      accounts: const [],
      movements: const [],
      fetchedAt: DateTime(2026, 10, 5, 10),
    );
