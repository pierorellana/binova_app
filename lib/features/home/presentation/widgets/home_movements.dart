import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';
import '../../../transactions/domain/entities/transaction.dart';
import 'home_data.dart';

/// "Movimientos": the three latest movements of the main account.
class HomeMovements extends StatelessWidget {
  const HomeMovements({
    required this.data,
    required this.onOpen,
    required this.onSeeAll,
    super.key,
  });

  final HomeData data;
  final ValueChanged<Transaction> onOpen;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final items = data.movements;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: BnSectionHeader('Movimientos', action: 'Ver todos', onAction: onSeeAll),
          ),
          for (var i = 0; i < items.length; i++)
            _Row(
              transaction: items[i],
              last: i == items.length - 1,
              onTap: () => onOpen(items[i]),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.transaction,
    required this.last,
    required this.onTap,
  });

  final Transaction transaction;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final incoming = transaction.kind == TransactionKind.income;
    final category = BnCategory.of(transaction.category, incoming: incoming);
    final value = homeAmount(transaction.amount.amount).abs();
    final amount = BnFormat.money(
      incoming ? value : -value,
      symbol: BnFormat.currencySymbol(transaction.amount.currency),
      signed: true,
    );
    return BnRowPressable(
      semanticLabel: transaction.merchant ?? transaction.description,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: last ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: BnColors.divisorSuave))),
        child: Row(
          children: [
            BnIconTile(
              svg: category.svg,
              iconSize: 19,
              circle: true,
              background: incoming ? BnColors.positivoFondo : BnColors.relleno,
              color: incoming ? BnColors.positivo : BnColors.carbon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.merchant ?? transaction.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BnType.body.copyWith(height: 1.2),
                  ),
                  Text(
                    '${category.label} · ${BnFormat.relativeDay(transaction.occurredAt.toLocal())}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BnType.footnote.copyWith(height: 1.2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amount,
              style: TextStyle(
                fontFamily: BnType.family,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: incoming ? BnColors.positivo : BnColors.carbon,
                fontFeatures: BnType.tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
