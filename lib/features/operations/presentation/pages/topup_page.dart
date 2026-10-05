import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/binova_widgets.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/domain/entities/money.dart';
import '../../../accounts/presentation/providers/accounts_controller.dart';
import '../../domain/repositories/operations_repository.dart';
import '../providers/operation_flow_controller.dart';
import '../widgets/operation_copy.dart';
import '../widgets/operation_flow_view.dart';
import '../widgets/operation_motion.dart';
import '../widgets/operation_parts.dart';

/// Recargar: número → monto (chips) → confirmación → Face ID → resultado.
class TopupPage extends StatefulWidget {
  const TopupPage({super.key});

  @override
  State<TopupPage> createState() => _TopupPageState();
}

/// A saved phone line. There is no saved-lines endpoint yet, so the list
/// mirrors the prototype.
class _Line {
  const _Line(this.operatorId, this.lineNumber, this.target);

  final String operatorId;
  final String lineNumber;
  final OperationTarget target;
}

final _lines = [
  _Line(
    'claro',
    '0990004521',
    OperationTarget(
      id: '0990004521',
      name: 'Mi línea',
      subtitle: '099 *** 4521',
      icon: OpGlyphs.phone,
      background: BnColors.grafito,
      foreground: BnColors.blancoCalido,
    ),
  ),
  const _Line(
    'movistar',
    '0980001180',
    OperationTarget(
      id: '0980001180',
      name: 'Carmen Orellana',
      subtitle: '098 *** 1180',
      initials: 'CO',
      compactLabel: 'CO',
      background: BnColors.brandNaranjaTinte,
      foreground: BnColors.brandNaranjaTexto,
    ),
  ),
];

const _amounts = [3, 5, 10, 15, 20, 30];

class _TopupPageState extends State<TopupPage> {
  _Line? _selected;
  int _chip = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final accounts = context.read<AccountsController>();
      if (accounts.accounts.isEmpty) accounts.load();
    });
  }

  void _select(OperationTarget target) {
    if (_selected?.target.id == target.id) return;
    setState(() {
      _selected = _lines.firstWhere((l) => l.target.id == target.id);
      _chip = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsController>();
    final source = operationSource(accounts.accounts);
    final line = _selected;
    final amount = _chip >= 0 ? _amounts[_chip].toDouble() : 0.0;

    return OperationFlowView(
      copy: OperationCopy.topup,
      targets: [for (final l in _lines) l.target],
      targetsLoading: false,
      selected: line?.target,
      onSelect: _select,
      amountBody: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Elige el monto', style: opStyle(15, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            Semantics(
              container: true,
              label: 'Monto de recarga',
              child: _AmountChips(
                selected: _chip,
                onSelect: (i) {
                  BnHaptics.tap();
                  setState(() => _chip = i);
                },
              ),
            ),
          ],
        ),
      ),
      source: source,
      sourceLoading: accounts.status == AccountsStatus.loading || accounts.status == AccountsStatus.idle,
      sourceError: accounts.errorMessage,
      canContinue: source != null && amount > 0 && amount <= accountAvailable(source),
      amount: amount,
      confirmRows: [
        if (line != null) ...[('Línea', line.target.subtitle), ('Titular', line.target.name)],
        if (source != null) ('Desde', accountLabel(source)),
        ('Comisión', BnFormat.money(0)),
      ],
      onSubmit: () => _submit(source!, line!, amount),
      onReset: () => setState(() {
        _selected = null;
        _chip = -1;
      }),
    );
  }

  Future<void> _submit(Account source, _Line line, double amount) => context.read<OperationFlowController>().submit(
        (idempotencyKey) => context.read<OperationsRepository>().createTopup(
              operatorId: line.operatorId,
              lineNumber: line.lineNumber,
              sourceAccountId: source.id,
              amount: Money(amount: amount.toStringAsFixed(2), currency: source.currency),
              idempotencyKey: idempotencyKey,
            ),
      );
}

/// 3-column radio grid of 64 pt chips (`.chip`: scale .96 while pressed).
class _AmountChips extends StatelessWidget {
  const _AmountChips({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: 10),
            Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: 10),
                  Expanded(child: _chip(row * 3 + col)),
                ],
              ],
            ),
          ],
        ],
      );

  Widget _chip(int i) {
    final on = i == selected;
    return rise(
      PressScale(
        onTap: () => onSelect(i),
        scale: .96,
        duration: BnMotion.press,
        selected: on,
        semanticLabel: '\$${_amounts[i]}',
        builder: (context, _) => AnimatedContainer(
          duration: BnMotion.press,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? BnColors.carbon : BnColors.superficie,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: on ? BnColors.carbon : BnColors.hairline),
          ),
          child: AnimatedDefaultTextStyle(
            duration: BnMotion.press,
            style: opStyle(20, weight: FontWeight.w600, color: on ? BnColors.superficie : BnColors.carbon, tabular: true),
            child: Text('\$${_amounts[i]}'),
          ),
        ),
      ),
      i * 30,
    );
  }
}
