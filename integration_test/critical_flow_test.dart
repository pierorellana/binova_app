import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:binova_app/core/design_system/binova_widgets.dart';
import 'package:binova_app/features/transactions/presentation/widgets/transaction_ui.dart';
import 'package:binova_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login to transaction detail critical flow', (tester) async {
    await app.main();
    await tester.pump(const Duration(milliseconds: 500));
    await _prepareLogin(tester);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'demo@binova.local');
    await tester.enterText(fields.at(1), 'Demo1234!');
    await tester.tap(find.bySemanticsLabel('Ingresar'));

    await _waitForAny(tester, [
      find.text('Pierre'),
      find.text('No pudimos iniciar sesión. Inténtalo de nuevo.'),
      find.text('El usuario o la contraseña no son válidos.'),
    ]);
    expect(find.text('Pierre'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Productos'));
    await _waitFor(tester, find.text('Saldo consolidado'));
    await _waitFor(
        tester, find.bySemanticsLabel(RegExp(r'^Cuenta de ahorros')));

    final accountCard = find.bySemanticsLabel(RegExp(r'^Cuenta de ahorros'));
    await tester.ensureVisible(accountCard);
    await tester.tap(accountCard);
    await tester.pump(const Duration(milliseconds: 500));
    final accountDetailReady = await _waitForAny(tester, [
      find.text('Ver movimientos'),
      find.text('No pudimos cargar el detalle de la cuenta.'),
      find.text('Producto no encontrado.'),
    ]);
    if (!accountDetailReady) {
      final textNodes = find
          .byType(Text)
          .evaluate()
          .map((element) => (element.widget as Text).data)
          .whereType<String>()
          .where((text) => text.trim().isNotEmpty)
          .toSet();
      await binding.takeScreenshot('critical-flow-account-detail-timeout');
      fail(
        'La pantalla de detalle de cuenta no apareció después de tocar la cuenta. '
        'Textos visibles: ${textNodes.join(' | ')}',
      );
    }
    final movementsLabel = find.text('Ver movimientos');
    if (movementsLabel.evaluate().isEmpty) {
      await binding.takeScreenshot('critical-flow-account-detail-error');
      fail('La cuenta no cargó su detalle correctamente.');
    }
    final movementsAction = find.ancestor(
      of: movementsLabel,
      matching: find.byType(BnPressable),
    );
    await tester.ensureVisible(movementsAction);
    await tester.tap(movementsAction);

    await _waitFor(tester, find.text('Movimientos'));
    await _waitForAny(tester, [find.byType(TransactionRow)]);
    final firstTransaction = find.byType(TransactionRow).first;
    await tester.ensureVisible(firstTransaction);
    final firstTransactionAction = find.descendant(
      of: firstTransaction,
      matching: find.byType(BnRowPressable),
    );
    await tester.tap(firstTransactionAction);

    await _waitFor(tester, find.byType(TransactionDetailContent));
    expect(find.byType(TransactionDetailContent), findsOneWidget);
    await binding.takeScreenshot('critical-flow-transaction-detail');
  });
}

Future<void> _prepareLogin(WidgetTester tester) async {
  await _waitForAny(tester, [
    find.text('Omitir'),
    find.text('Hola de nuevo'),
    find.text('Usar contraseña'),
    find.bySemanticsLabel('Perfil'),
  ]);

  if (find.text('Omitir').evaluate().isNotEmpty) {
    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();
  }

  if (find.text('Usar contraseña').evaluate().isNotEmpty) {
    await tester.tap(find.text('Usar contraseña'));
    await tester.pumpAndSettle();
  }

  if (find.bySemanticsLabel('Perfil').evaluate().isNotEmpty) {
    await tester.tap(find.bySemanticsLabel('Perfil'));
    await _waitUntil(
        tester, () => find.text('Cerrar sesión').evaluate().isNotEmpty);
    await tester.tap(find.text('Cerrar sesión').first);
    await tester.pumpAndSettle();
    await _waitUntil(
        tester, () => find.text('Cerrar sesión').evaluate().length > 1);
    await tester.tap(find.text('Cerrar sesión').last);
    await tester.pumpAndSettle();
  }

  await _waitFor(tester, find.text('Hola de nuevo'));
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(finder, findsOneWidget);
}

Future<bool> _waitForAny(WidgetTester tester, List<Finder> finders) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(deadline)) {
    if (finders.any((finder) => finder.evaluate().isNotEmpty)) return true;
    await tester.pump(const Duration(milliseconds: 250));
  }
  return false;
}

Future<void> _waitUntil(WidgetTester tester, bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(condition(), isTrue);
}
