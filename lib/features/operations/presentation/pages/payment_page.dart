import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/binova_widgets.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/accounts_controller.dart';
import '../../domain/entities/debt.dart';
import '../../domain/repositories/operations_repository.dart';
import '../providers/operation_flow_controller.dart';
import '../widgets/operation_copy.dart';
import '../widgets/operation_flow_view.dart';
import '../widgets/operation_motion.dart';
import '../widgets/operation_parts.dart';

/// Pagar servicios: servicio → consulta de planilla → confirmación → Face ID → resultado.
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

/// A saved service. The API has no "my services" endpoint yet, so the list
/// mirrors the prototype; the bill itself comes from `getDebt`.
class _Service {
  const _Service(this.providerId, this.name, this.subtitle, this.accountReference, this.icon);

  final String providerId;
  final String name;
  final String subtitle;
  final String accountReference;
  final String icon;

  OperationTarget get target => OperationTarget(
        id: providerId,
        name: name,
        subtitle: subtitle,
        icon: icon,
        compactLabel: name.characters.first,
      );
}

final _services = [
  _Service('luz-electrica', 'Luz eléctrica', 'Contrato 0042-118', '0042-118', OpGlyphs.bolt),
  _Service('agua-potable', 'Agua potable', 'Cuenta 88213', '88213', OpGlyphs.drop),
  _Service('internet-hogar', 'Internet hogar', 'Cliente 55190', '55190', OpGlyphs.wifi),
  _Service('telefonia-movil', 'Telefonía móvil', 'Plan 099 *** 4521', '0990004521', OpGlyphs.phone),
];

class _PaymentPageState extends State<PaymentPage> {
  _Service? _selected;
  Debt? _debt;
  String? _debtError;
  bool _debtLoading = false;
  int _query = 0;

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
    setState(() => _selected = _services.firstWhere((s) => s.providerId == target.id));
    _queryDebt();
  }

  Future<void> _queryDebt() async {
    final service = _selected;
    if (service == null) return;
    final query = ++_query;
    setState(() {
      _debtLoading = true;
      _debtError = null;
      _debt = null;
    });
    try {
      final (debt, _) = await (
        context.read<OperationsRepository>().getDebt(
              providerId: service.providerId,
              accountReference: service.accountReference,
            ),
        // The prototype keeps the bill skeleton for 1 s.
        Future<void>.delayed(const Duration(milliseconds: 1000)),
      ).wait;
      if (mounted && query == _query) setState(() => _debt = debt);
    } on Object {
      if (mounted && query == _query) setState(() => _debtError = 'No pudimos consultar tu planilla.');
    } finally {
      if (mounted && query == _query) setState(() => _debtLoading = false);
    }
  }

  static String _monthYear(DateTime d) {
    final m = BnFormat.months[d.month - 1];
    return '${m[0].toUpperCase()}${m.substring(1)} ${d.year}';
  }

  /// Billing period: the month before the due date.
  static String _period(Debt debt) {
    final due = debt.dueDate ?? DateTime.now();
    return _monthYear(DateTime(due.year, due.month - 1));
  }

  static String _date(DateTime d) => '${d.day} ${BnFormat.monthsShort[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountsController>();
    final source = operationSource(accounts.accounts);
    final service = _selected;
    final debt = _debt;
    final amount = debt == null ? 0.0 : double.tryParse(debt.amount.amount) ?? 0;
    final payable = debt != null && debt.status == 'payable' && debt.debtReference != null;

    return OperationFlowView(
      copy: OperationCopy.pay,
      targets: [for (final s in _services) s.target],
      targetsLoading: false,
      selected: service?.target,
      onSelect: _select,
      amountBody: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Align(
          alignment: Alignment.topCenter,
          child: _BillCard(
            loading: _debtLoading,
            error: _debtError,
            onRetry: _queryDebt,
            amount: amount,
            debt: debt,
            period: debt == null ? '' : _period(debt),
            due: debt?.dueDate == null ? null : _date(debt!.dueDate!),
          ),
        ),
      ),
      source: source,
      sourceLoading: accounts.status == AccountsStatus.loading || accounts.status == AccountsStatus.idle,
      sourceError: accounts.errorMessage,
      canContinue: source != null && payable && amount > 0 && amount <= accountAvailable(source),
      amount: amount,
      confirmRows: [
        if (service != null) ...[('Servicio', service.name), ('Referencia', service.subtitle)],
        if (debt != null) ('Período', _period(debt)),
        if (source != null) ('Desde', accountLabel(source)),
        ('Comisión', BnFormat.money(0)),
      ],
      onSubmit: () => _submit(source!, debt!),
      onReset: () => setState(() {
        _selected = null;
        _debt = null;
        _debtError = null;
      }),
    );
  }

  Future<void> _submit(Account source, Debt debt) => context.read<OperationFlowController>().submit(
        (idempotencyKey) => context.read<OperationsRepository>().createPayment(
              providerId: debt.providerId,
              accountReference: debt.accountReference,
              sourceAccountId: source.id,
              amount: debt.amount,
              debtReference: debt.debtReference!,
              idempotencyKey: idempotencyKey,
            ),
      );
}

/// "Consultando tu planilla…" skeleton → "Valor a pagar" card.
class _BillCard extends StatelessWidget {
  const _BillCard({
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.amount,
    required this.debt,
    required this.period,
    required this.due,
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final double amount;
  final Debt? debt;
  final String period;
  final String? due;

  static final _decoration = BoxDecoration(
    color: BnColors.superficie,
    border: Border.all(color: BnColors.hairline),
    borderRadius: BorderRadius.circular(20),
  );

  Widget _row(String k, String v) => Container(
        constraints: const BoxConstraints(minHeight: 40),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: BnColors.relleno))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: opStyle(15, color: BnColors.texto2)),
            Text(v, style: opStyle(15, weight: FontWeight.w500)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (loading || (debt == null && error == null)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _decoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const OperationMiniTrace(),
                const SizedBox(width: 10),
                Text('Consultando tu planilla…', style: opStyle(14, color: BnColors.texto2)),
              ],
            ),
            const SizedBox(height: 20),
            const BnSkeleton(width: 160, height: 36, radius: 10),
            const SizedBox(height: 16),
            const BnSkeleton(width: double.infinity, height: 12),
            const SizedBox(height: 10),
            const FractionallySizedBox(widthFactor: .7, child: BnSkeleton(width: double.infinity, height: 12)),
          ],
        ),
      );
    }
    if (error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _decoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error!, style: opStyle(15, weight: FontWeight.w500)),
            const SizedBox(height: 12),
            BnButton(label: 'Reintentar', onTap: onRetry, variant: BnButtonVariant.secondary, height: 50),
          ],
        ),
      );
    }
    final value = debt!;
    return rise(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _decoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valor a pagar', style: opStyle(14, color: BnColors.texto2)),
            const SizedBox(height: 4),
            Text(BnFormat.money(amount), style: opStyle(44, weight: FontWeight.w600, letterSpacing: -1.76, tabular: true)),
            const SizedBox(height: 16),
            _row('Período', period),
            if (due != null) _row('Vence', due!),
            if (value.status != 'payable')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Esta planilla no tiene valores pendientes.', style: opStyle(14, color: BnColors.texto3)),
              ),
          ],
        ),
      ),
    );
  }
}
