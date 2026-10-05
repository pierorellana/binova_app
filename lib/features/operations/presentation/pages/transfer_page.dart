import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/binova_widgets.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/domain/entities/money.dart';
import '../../../accounts/presentation/providers/accounts_controller.dart';
import '../../domain/entities/beneficiary.dart';
import '../../domain/repositories/operations_repository.dart';
import '../providers/operation_flow_controller.dart';
import '../widgets/amount_keypad.dart';
import '../widgets/operation_copy.dart';
import '../widgets/operation_flow_view.dart';
import '../widgets/operation_parts.dart';

/// Transferir: contacto → monto con teclado → confirmación → Face ID → resultado.
class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _note = TextEditingController();
  List<Beneficiary> _beneficiaries = const [];
  bool _loading = true;
  String? _loadError;
  Beneficiary? _selected;
  String _amount = '';
  int _presses = 0;
  int _nudge = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final accounts = context.read<AccountsController>();
      if (accounts.accounts.isEmpty) accounts.load();
      _loadBeneficiaries();
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadBeneficiaries() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final values = await context.read<OperationsRepository>().listBeneficiaries();
      if (mounted) {
        setState(() {
          _beneficiaries = values.where((b) => b.status == BeneficiaryStatus.active).toList();
          _loading = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'No pudimos cargar tus beneficiarios.';
        });
      }
    }
  }

  List<OperationTarget> get _targets => [
        for (var i = 0; i < _beneficiaries.length; i++) _target(_beneficiaries[i], i),
      ];

  OperationTarget _target(Beneficiary b, int index) {
    final (bg, fg) = OperationTarget.paletteAt(index);
    final initials = BnFormat.initials(b.displayName);
    return OperationTarget(
      id: b.id,
      name: b.displayName,
      subtitle: '${b.bankName} · ${b.maskedAccountNumber}',
      initials: initials,
      compactLabel: initials,
      background: bg,
      foreground: fg,
    );
  }

  void _select(OperationTarget target) {
    if (_selected?.id == target.id) return;
    setState(() {
      _selected = _beneficiaries.firstWhere((b) => b.id == target.id);
      _amount = '';
    });
  }

  void _press(String key) {
    final (next, result) = AmountInput.press(_amount, key);
    switch (result) {
      case AmountKeyResult.accepted:
        BnHaptics.tap();
        setState(() {
          _amount = next;
          _presses++;
        });
      case AmountKeyResult.rejectedWithHaptic:
        BnHaptics.light();
        setState(() => _nudge++);
      case AmountKeyResult.rejected:
        setState(() => _nudge++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsController>();
    final source = operationSource(accounts.accounts);
    final selected = _selected;
    final value = AmountInput.parse(_amount);
    final over = source != null && value > accountAvailable(source);
    final selectedIndex = selected == null ? -1 : _beneficiaries.indexOf(selected);

    return OperationFlowView(
      copy: OperationCopy.transfer,
      targets: _targets,
      targetsLoading: _loading,
      targetsError: _loadError,
      onReloadTargets: _loadBeneficiaries,
      selected: selected == null ? null : _target(selected, selectedIndex),
      onSelect: _select,
      amountBody: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AmountDisplay(value: _amount, presses: _presses, nudge: _nudge, over: over),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 22),
              child: Text(
                over ? 'Supera tu saldo disponible' : 'Sin comisión entre cuentas BI',
                style: opStyle(14, color: over ? BnColors.critico : BnColors.texto3),
              ),
            ),
          ],
        ),
      ),
      keypad: AmountKeypad(onKey: _press),
      source: source,
      sourceLoading: accounts.status == AccountsStatus.loading || accounts.status == AccountsStatus.idle,
      sourceError: accounts.errorMessage,
      canContinue: source != null && value > 0 && !over,
      amount: value,
      confirmRows: [
        if (selected != null) ...[
          ('Para', selected.displayName),
          ('Banco destino', selected.bankName),
          ('Cuenta destino', selected.maskedAccountNumber),
        ],
        if (source != null) ('Desde', accountLabel(source)),
        ('Comisión', BnFormat.money(0)),
      ],
      noteController: _note,
      onSubmit: () => _submit(source!, selected!, value),
      onReset: () => setState(() {
        _selected = null;
        _amount = '';
        _note.clear();
      }),
    );
  }

  Future<void> _submit(Account source, Beneficiary beneficiary, double value) {
    final note = _note.text.trim();
    return context.read<OperationFlowController>().submit(
          (idempotencyKey) => context.read<OperationsRepository>().createTransfer(
                sourceAccountId: source.id,
                beneficiaryId: beneficiary.id,
                amount: Money(amount: value.toStringAsFixed(2), currency: source.currency),
                note: note.isEmpty ? null : note,
                idempotencyKey: idempotencyKey,
              ),
        );
  }
}
