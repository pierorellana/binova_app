import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';
import '../../../accounts/domain/entities/account.dart';
import 'home_data.dart';

/// Tapped product row with its global rect (for the shared-element expansion).
typedef HomeProductTap = void Function(Account account, Rect rowRect);

/// "Mis productos" card. [onTap] null renders the offline variant
/// (no "Ver todos", no chevrons, rows not tappable).
class HomeProductsCard extends StatelessWidget {
  const HomeProductsCard({
    required this.data,
    required this.hidden,
    this.onTap,
    this.onSeeAll,
    super.key,
  });

  final HomeData data;
  final bool hidden;
  final HomeProductTap? onTap;
  final VoidCallback? onSeeAll;

  bool get _offline => onTap == null;

  @override
  Widget build(BuildContext context) {
    final accounts = data.accounts;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, _offline ? 24 : 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_offline)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Semantics(header: true, child: const Text('Mis productos', style: BnType.tituloSeccion)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BnSectionHeader('Mis productos', action: 'Ver todos', onAction: onSeeAll),
            ),
          BnCard(
            padding: _offline ? const EdgeInsets.symmetric(horizontal: 16) : null,
            child: accounts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Tus productos aparecerán aquí.', style: BnType.footnote),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < accounts.length; i++) ...[
                        if (i > 0 && !_offline) const BnDivider(indent: 68),
                        _offline
                            ? _OfflineRow(
                                account: accounts[i], data: data, hidden: hidden, last: i == accounts.length - 1)
                            : _Row(account: accounts[i], data: data, hidden: hidden, onTap: onTap!),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

String _glyph(Account a) => a.type == AccountType.credit ? BnGlyphs.card : BnGlyphs.bank;

String _amount(Account a, HomeData data, bool hidden) => hidden
    ? homeMask
    : BnFormat.money(homeAmount(a.availableBalance.amount), symbol: BnFormat.currencySymbol(a.currency));

const _name = TextStyle(
    fontFamily: BnType.family, fontSize: 16, height: 1.2, fontWeight: FontWeight.w500, color: BnColors.carbon);
const _amountStyle = TextStyle(
  fontFamily: BnType.family,
  fontSize: 16,
  height: 1.2,
  fontWeight: FontWeight.w600,
  color: BnColors.carbon,
  fontFeatures: BnType.tabular,
);

class _Identity extends StatelessWidget {
  const _Identity({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(account.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _name),
          Text(
            account.maskedNumber,
            style: BnType.footnote.copyWith(height: 1.2, fontFeatures: BnType.tabular),
          ),
        ],
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.account, required this.data, required this.hidden, required this.onTap});

  final Account account;
  final HomeData data;
  final bool hidden;
  final HomeProductTap onTap;

  @override
  Widget build(BuildContext context) => BnRowPressable(
        semanticLabel: account.name,
        onTap: () {
          final box = context.findRenderObject()! as RenderBox;
          onTap(account, box.localToGlobal(Offset.zero) & box.size);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                BnIconTile(svg: _glyph(account)),
                const SizedBox(width: 12),
                Expanded(child: _Identity(account: account)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_amount(account, data, hidden), style: _amountStyle),
                    Text('Disponible', style: BnType.caption.copyWith(fontWeight: FontWeight.w400, height: 1.2)),
                  ],
                ),
                const SizedBox(width: 12),
                BnSvg(BnGlyphs.chevronRight, size: 16, color: BnColors.texto5),
              ],
            ),
          ),
        ),
      );
}

class _OfflineRow extends StatelessWidget {
  const _OfflineRow({required this.account, required this.data, required this.hidden, required this.last});

  final Account account;
  final HomeData data;
  final bool hidden;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 72),
        decoration: last ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: BnColors.relleno))),
        child: Row(
          children: [
            BnIconTile(svg: _glyph(account)),
            const SizedBox(width: 12),
            Expanded(child: _Identity(account: account)),
            const SizedBox(width: 12),
            Text(_amount(account, data, hidden), style: _amountStyle),
          ],
        ),
      );
}
