import 'package:flutter/material.dart';

import '../../../../core/design_system/binova_widgets.dart';
import '../../../accounts/presentation/widgets/account_ui.dart';
import '../../domain/entities/transaction.dart';

bool isIncome(Transaction t) => t.kind == TransactionKind.income;

String transactionTitle(Transaction t) => t.merchant ?? t.description;

BnCategory transactionCategory(Transaction t) => BnCategory.of(t.category, incoming: isIncome(t));

/// `−$8.50` / `+$150.00` (U+2212 minus), as `fmt()` in Movimientos.
String transactionAmount(Transaction t) {
  final value = parseAmount(t.amount.amount).abs();
  return BnFormat.money(
    isIncome(t) ? value : -value,
    symbol: BnFormat.currencySymbol(t.amount.currency),
    signed: true,
  );
}

Color transactionAmountColor(Transaction t) => isIncome(t) ? BnColors.positivo : BnColors.carbon;

final _outArrow = bnLine('<path d="M7 17 17 7"/><path d="M9 7h8v8"/>', stroke: 1.7);
final _clock = bnLine('<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>', stroke: 2.2);
final _exclamation = bnLine('<path d="M12 6v8M12 18h.01"/>', stroke: 2.4);

(String, Color, String) _statusVisual(TransactionStatus status) => switch (status) {
      TransactionStatus.succeeded => ('Completado', BnColors.positivo, AccountGlyphs.check),
      TransactionStatus.pending => ('Pendiente', BnColors.precaucion, _clock),
      TransactionStatus.processing => ('En proceso', BnColors.precaucion, _clock),
      TransactionStatus.failed => ('Fallido', BnColors.critico, _exclamation),
    };

/// Movement row (`.row`): round category glyph, name, "Categoría · Hoy, 08:43"
/// and the signed amount. [compact] is the Cuenta variant (40 pt glyph,
/// 64 pt row, `#F1EFEB` press); the default is Movimientos (42 / 68 / `#EFEDE9`).
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    required this.transaction,
    required this.onTap,
    this.compact = false,
    this.divider = true,
    super.key,
  });

  final Transaction transaction;
  final VoidCallback onTap;
  final bool compact;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final income = isIncome(t);
    final category = transactionCategory(t);
    final glyph = compact ? 40.0 : 42.0;
    return BnRowPressable(
      onTap: onTap,
      pressedColor: compact ? BnColors.rowPressed : BnColors.relleno,
      semanticLabel: '${transactionTitle(t)}, ${transactionAmount(t)}',
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 64 : 68),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: divider ? const Border(bottom: BorderSide(color: BnColors.divisorSuave)) : null,
        ),
        child: Row(
          children: [
            BnIconTile(
              svg: category.svg,
              size: glyph,
              iconSize: 19,
              circle: true,
              background: income ? BnColors.positivoFondo : BnColors.relleno,
              color: income ? BnColors.positivo : BnColors.carbon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transactionTitle(t), maxLines: 1, overflow: TextOverflow.ellipsis, style: BnType.body),
                  Text(
                    '${category.label} · ${BnFormat.relativeDay(t.occurredAt.toLocal())}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BnType.footnote,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              transactionAmount(t),
              style: TextStyle(
                fontFamily: BnType.family,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: transactionAmountColor(t),
                fontFeatures: BnType.tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TransactionDetailAction { report, share }

String transactionActionMessage(TransactionDetailAction action) => switch (action) {
      TransactionDetailAction.report => 'Recibimos tu reporte. Te contactaremos en 24 h.',
      TransactionDetailAction.share => 'Comprobante listo para compartir',
    };

/// Opens the movement detail as the prototype's sheet over the list.
Future<TransactionDetailAction?> showTransactionDetailSheet(
  BuildContext context,
  Transaction transaction, {
  String? accountLabel,
}) =>
    showBnSheet<TransactionDetailAction>(
      context,
      builder: (sheet) => SingleChildScrollView(
        physics: bnScrollPhysics,
        child: TransactionDetailContent(
          transaction: transaction,
          accountLabel: accountLabel,
          onClose: () => Navigator.of(sheet).pop(),
          onAction: (action) => Navigator.of(sheet).pop(action),
        ),
      ),
    );

/// Body of the "Detalle del movimiento" sheet (Movimientos.dc.html).
class TransactionDetailContent extends StatelessWidget {
  const TransactionDetailContent({
    required this.transaction,
    required this.onClose,
    required this.onAction,
    this.accountLabel,
    super.key,
  });

  final Transaction transaction;
  final String? accountLabel;
  final VoidCallback onClose;
  final ValueChanged<TransactionDetailAction> onAction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final income = isIncome(t);
    final (statusLabel, statusColor, statusSvg) = _statusVisual(t.status);
    final rows = <(String, String, bool)>[
      ('Fecha', BnFormat.dateTime(t.occurredAt.toLocal()), false),
      ('Categoría', transactionCategory(t).label, false),
      if (accountLabel != null) (income ? 'Cuenta destino' : 'Cuenta origen', accountLabel!, true),
      ('Estado', statusLabel, false),
      ('Referencia', t.reference, true),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Align(alignment: Alignment.centerRight, child: BnCloseButton(onTap: onClose)),
        Center(
          child: BnIconTile(
            svg: income ? BnGlyphs.income : _outArrow,
            size: 56,
            iconSize: 24,
            circle: true,
            background: income ? BnColors.positivoFondo : BnColors.relleno,
            color: income ? BnColors.positivo : BnColors.carbon,
          ),
        ),
        const SizedBox(height: 12),
        Text(transactionTitle(t), textAlign: TextAlign.center, style: BnType.headline),
        const SizedBox(height: 4),
        Text(
          transactionAmount(t),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: BnType.family,
            fontSize: 36,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.08,
            color: transactionAmountColor(t),
            fontFeatures: BnType.tabular,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BnSvg(statusSvg, size: 15, color: statusColor),
            const SizedBox(width: 6),
            Text(statusLabel, style: TextStyle(fontFamily: BnType.family, fontSize: 14, fontWeight: FontWeight.w500, color: statusColor)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: BnColors.blancoCalido, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                Container(
                  constraints: const BoxConstraints(minHeight: 46),
                  decoration: BoxDecoration(
                    border: i < rows.length - 1 ? const Border(bottom: BorderSide(color: BnColors.divisorSuave)) : null,
                  ),
                  child: Row(
                    children: [
                      Text(rows[i].$1, style: const TextStyle(fontFamily: BnType.family, fontSize: 15, color: BnColors.texto2)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rows[i].$2,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontFamily: BnType.family,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: BnColors.carbon,
                            fontFeatures: rows[i].$3 ? BnType.tabular : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: BnButton(
                label: 'Reportar',
                height: 52,
                variant: BnButtonVariant.secondary,
                onTap: () => onAction(TransactionDetailAction.report),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BnButton(label: 'Compartir', height: 52, onTap: () => onAction(TransactionDetailAction.share)),
            ),
          ],
        ),
      ],
    );
  }
}
