import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/routing/app_router.dart';
import '../../../../core/design_system/binova_widgets.dart';
import '../../../cards/domain/entities/card.dart' as cards;
import '../../../cards/presentation/providers/cards_controller.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart' show TransactionRepository;
import '../../../transactions/presentation/pages/transactions_page.dart';
import '../../../transactions/presentation/providers/transactions_controller.dart';
import '../../../transactions/presentation/widgets/transaction_ui.dart';
import '../../domain/entities/account.dart';
import '../providers/accounts_controller.dart';
import '../widgets/account_ui.dart';

const _sectionTitle = TextStyle(fontFamily: BnType.family, fontSize: 15, fontWeight: FontWeight.w600, color: BnColors.texto2);
const _cardTitle = TextStyle(fontFamily: BnType.family, fontSize: 16, fontWeight: FontWeight.w500, color: BnColors.carbon);
const _cardMeta = TextStyle(fontFamily: BnType.family, fontSize: 13, color: BnColors.texto3, fontFeatures: BnType.tabular);
const _cardAmount = TextStyle(
  fontFamily: BnType.family,
  fontSize: 24,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.6,
  color: BnColors.carbon,
  fontFeatures: BnType.tabular,
);

// ---------------------------------------------------------------------------
// Productos (Productos.dc.html)
// ---------------------------------------------------------------------------

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsController>().load();
      final cardsController = context.read<CardsController>();
      if (cardsController.status == CardsStatus.idle) cardsController.load();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([context.read<AccountsController>().load(), context.read<CardsController>().load()]);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AccountsController>();
    final cardsController = context.watch<CardsController>();
    final loading = (controller.status == AccountsStatus.idle || controller.status == AccountsStatus.loading) &&
        controller.accounts.isEmpty;
    final failed = controller.status == AccountsStatus.error && controller.accounts.isEmpty;
    final accounts = controller.accounts.where((a) => a.type != AccountType.credit).toList(growable: false);
    final creditAccount = controller.accounts.where((a) => a.type == AccountType.credit).firstOrNull;
    final total = accounts.fold<double>(0, (sum, a) => sum + parseAmount(a.availableBalance.amount));
    final currency = accounts.isEmpty ? 'USD' : accounts.first.currency;

    return BnTabScaffold(
      tab: BnTab.products,
      onRefresh: _refresh,
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 44)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BnLargeTitle('Productos', padding: EdgeInsets.zero),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Expanded(
                      child: Text('Saldo consolidado', style: TextStyle(fontFamily: BnType.family, fontSize: 14, color: BnColors.texto2)),
                    ),
                    if (loading)
                      const BnSkeleton(width: 110, height: 22)
                    else if (!failed)
                      Text(
                        BnFormat.money(total, symbol: BnFormat.currencySymbol(currency)),
                        style: const TextStyle(
                          fontFamily: BnType.family,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.44,
                          color: BnColors.carbon,
                          fontFeatures: BnType.tabular,
                        ),
                      ),
                  ],
                ),
                if (controller.status == AccountsStatus.offlineStale) ...[
                  const SizedBox(height: 16),
                  ProductOfflineBanner(fetchedAt: controller.fetchedAt, onRetry: _refresh),
                ],
              ],
            ),
          ),
        ),
        if (failed)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 64),
              child: ProductMessageState(
                svg: AccountGlyphs.wifiOff,
                title: controller.errorMessage ?? 'No pudimos cargar tus productos.',
                message: 'Revisa tu conexión e inténtalo de nuevo.',
                actionLabel: 'Reintentar',
                onAction: _refresh,
              ),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: _Section(
              title: 'Cuentas',
              children: loading
                  ? const [_CardSkeleton(), _CardSkeleton()]
                  : [for (final a in accounts) _AccountCard(account: a)],
            ),
          ),
          SliverToBoxAdapter(
            child: _Section(
              title: 'Tarjetas',
              children: [
                if (cardsController.cards.isEmpty && cardsController.status == CardsStatus.loading) const _CardSkeleton(),
                for (final c in _sortedCards(cardsController.cards))
                  _BankCardTile(card: c, creditAccount: c.type == cards.CardType.credit ? creditAccount : null),
                const _CreateVirtualCardTile(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(title, style: _sectionTitle)),
            const SizedBox(height: 10),
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              children[i],
            ],
          ],
        ),
      );
}

/// White product card with the Productos `.press` (scale .98 · opacity .9).
/// Productos lists the credit card first, then debit, then virtual cards.
List<cards.Card> _sortedCards(List<cards.Card> list) {
  int rank(cards.Card c) => switch (c.type) {
        cards.CardType.credit => 0,
        cards.CardType.debit => 1,
        cards.CardType.virtual => 2,
      };
  return [...list]..sort((a, b) => rank(a).compareTo(rank(b)));
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.onTap, required this.child, this.semanticLabel});

  final VoidCallback onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => BnPressable(
        onTap: onTap,
        scale: .98,
        opacity: .9,
        semanticLabel: semanticLabel,
        child: BnCard(padding: const EdgeInsets.all(16), child: child),
      );
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.svg, required this.title, required this.meta, this.dark = false});

  final String svg;
  final String title;
  final String meta;
  final bool dark;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          BnIconTile(
            svg: svg,
            background: dark ? BnColors.grafito : BnColors.relleno,
            color: dark ? BnColors.blancoCalido : BnColors.carbon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: _cardTitle),
                Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: _cardMeta),
              ],
            ),
          ),
          BnSvg(AccountGlyphs.chevron, size: 16, color: BnColors.texto5),
        ],
      );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) => _ProductCard(
        semanticLabel: '${account.name}, ${shortNumber(account.maskedNumber)}',
        onTap: () => Navigator.of(context).pushNamed(AppRoute.accountDetail, arguments: account.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProductHeader(
              svg: account.type == AccountType.current ? AccountGlyphs.cash : BnGlyphs.bank,
              title: account.name,
              meta: shortNumber(account.maskedNumber),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo disponible', style: TextStyle(fontFamily: BnType.family, fontSize: 12, color: BnColors.texto3)),
                      Text(formatMoney(account.availableBalance), style: _cardAmount),
                    ],
                  ),
                ),
                AccountStatusLabel(status: account.status),
              ],
            ),
          ],
        ),
      );
}

class _BankCardTile extends StatelessWidget {
  const _BankCardTile({required this.card, this.creditAccount});

  final cards.Card card;

  /// The credit line behind a credit card: available + used = limit.
  final Account? creditAccount;

  @override
  Widget build(BuildContext context) {
    final credit = card.type == cards.CardType.credit;
    final title = switch (card.type) {
      cards.CardType.credit => 'Tarjeta de crédito',
      cards.CardType.debit => 'Tarjeta de débito',
      cards.CardType.virtual => 'Tarjeta virtual',
    };
    final blocked = card.status == cards.CardStatus.frozen || card.status == cards.CardStatus.blocked;
    return _ProductCard(
      semanticLabel: '$title, ${shortNumber(card.maskedPan)}',
      onTap: () => Navigator.of(context).pushNamed(AppRoute.cards, arguments: card.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProductHeader(svg: BnGlyphs.card, title: title, meta: shortNumber(card.maskedPan), dark: credit),
          if (creditAccount != null) _CreditLine(account: creditAccount!),
          if (blocked) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: BnColors.precaucionFondo, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  BnSvg(AccountGlyphs.lock, size: 15, color: BnColors.precaucion),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      card.status == cards.CardStatus.frozen ? 'Bloqueada temporalmente' : 'Bloqueada',
                      style: const TextStyle(fontFamily: BnType.family, fontSize: 13, fontWeight: FontWeight.w500, color: BnColors.precaucion),
                    ),
                  ),
                  const Text('Gestionar', style: TextStyle(fontFamily: BnType.family, fontSize: 13, fontWeight: FontWeight.w600, color: BnColors.carbon)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreditLine extends StatelessWidget {
  const _CreditLine({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final available = double.tryParse(account.availableBalance.amount) ?? 0;
    final used = (double.tryParse(account.ledgerBalance.amount) ?? 0).abs();
    final limit = available + used;
    final usedRatio = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final symbol = BnFormat.currencySymbol(account.currency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Disponible', style: TextStyle(fontFamily: BnType.family, fontSize: 12, color: BnColors.texto3)),
                  Text(formatMoney(account.availableBalance), style: _cardAmount),
                ],
              ),
            ),
            Text(
              'de ${BnFormat.money(limit, symbol: symbol)}',
              style: const TextStyle(fontFamily: BnType.family, fontSize: 13, color: BnColors.texto3, fontFeatures: BnType.tabular),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'Cupo utilizado: ${(usedRatio * 100).round()}%',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  const Positioned.fill(child: ColoredBox(color: BnColors.relleno)),
                  FractionallySizedBox(
                    widthFactor: usedRatio,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: BnColors.carbon, borderRadius: BorderRadius.circular(3)),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CreateVirtualCardTile extends StatelessWidget {
  const _CreateVirtualCardTile();

  @override
  Widget build(BuildContext context) => BnPressable(
        onTap: () => Navigator.of(context).pushNamed(AppRoute.createVirtualCard),
        scale: .98,
        opacity: .9,
        child: DashedBorder(
          color: BnColors.piedra,
          strokeWidth: 1.5,
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                BnIconTile(svg: AccountGlyphs.plus, background: BnColors.brandNaranjaTinte, color: BnColors.brandNaranjaTexto),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Crear tarjeta virtual', style: _cardTitle),
                      Text('Lista al instante para compras en línea', style: _cardMeta),
                    ],
                  ),
                ),
                BnSvg(AccountGlyphs.chevron, size: 16, color: BnColors.texto5),
              ],
            ),
          ),
        ),
      );
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) => const BnCard(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BnSkeleton(width: 40, height: 40, radius: 12),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [BnSkeleton(width: 150, height: 15), SizedBox(height: 6), BnSkeleton(width: 70, height: 12)],
                ),
              ],
            ),
            SizedBox(height: 18),
            BnSkeleton(width: 90, height: 11),
            SizedBox(height: 8),
            BnSkeleton(width: 140, height: 24, radius: 8),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Detalle de cuenta (Cuenta.dc.html)
// ---------------------------------------------------------------------------

/// Account detail. Its header ("Cuenta · **** 4821" 15 pt, "Saldo disponible"
/// 13 pt, 42 pt amount starting at 123 pt) is the landing state of the Inicio
/// row expansion, so it does not animate in; the rest rises (`.st`).
class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({
    required this.accountId,
    this.backLabel = 'Productos',
    this.tab = BnTab.products,
    super.key,
  });

  final String accountId;
  final String backLabel;
  final BnTab tab;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  late final TransactionsController _recent =
      TransactionsController(context.read<TransactionRepository>(), widget.accountId);
  bool _reveal = false;
  String? _toast;
  int _toastId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountDetailController>().load();
      _recent.load();
    });
  }

  @override
  void dispose() {
    _recent.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([context.read<AccountDetailController>().load(), _recent.load()]);
  }

  void _flash(String message) => setState(() {
        _toast = message;
        _toastId++;
      });

  Future<void> _share(Account account) async {
    final copied = await showAccountShareSheet(context, account);
    if (copied && mounted) _flash('Número copiado');
  }

  void _copyNumber(Account account) {
    Clipboard.setData(ClipboardData(text: account.maskedNumber));
    BnHaptics.light();
    _flash('Número copiado');
  }

  void _openTransactions(Account account, {String? openId}) {
    Navigator.of(context).push(
      BnRoutes.push<void>(
        ChangeNotifierProvider<TransactionsController>(
          create: (ctx) => TransactionsController(ctx.read<TransactionRepository>(), account.id),
          child: TransactionsPage(
            accountId: account.id,
            backLabel: accountTypeShort(account.type),
            initialTransactionId: openId,
            tab: widget.tab,
          ),
        ),
        settings: RouteSettings(name: AppRoute.transactions, arguments: account.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AccountDetailController>();
    final account = controller.account;
    final loading = account == null &&
        (controller.status == AccountDetailStatus.idle || controller.status == AccountDetailStatus.loading);

    return BnTabScaffold(
      tab: widget.tab,
      onRefresh: account == null ? null : _refresh,
      slivers: [
        SliverToBoxAdapter(
          child: BnNavBar(
            backLabel: widget.backLabel,
            title: account == null ? null : accountTypeShort(account.type),
            trailing: account == null
                ? null
                : BnPressable(
                    onTap: () => _share(account),
                    scale: .96,
                    semanticLabel: 'Compartir datos de la cuenta',
                    child: SizedBox(width: 44, height: 44, child: Center(child: BnSvg(BnGlyphs.share, size: 22, color: BnColors.carbon))),
                  ),
          ),
        ),
        if (loading)
          const SliverToBoxAdapter(child: _DetailSkeleton())
        else if (account == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 96),
              child: ProductMessageState(
                svg: AccountGlyphs.wifiOff,
                title: controller.errorMessage ?? 'Producto no encontrado.',
                message: 'Revisa tu conexión e inténtalo de nuevo.',
                actionLabel: 'Reintentar',
                onAction: controller.load,
              ),
            ),
          )
        else
          SliverToBoxAdapter(child: _detail(controller, account)),
      ],
      overlays: [
        if (_toast != null)
          ProductToast(key: ValueKey(_toastId), message: _toast!, width: 220, onDone: () => setState(() => _toast = null)),
      ],
    );
  }

  Widget _detail(AccountDetailController controller, Account account) {
    final symbol = BnFormat.currencySymbol(account.currency);
    final available = parseAmount(account.availableBalance.amount);
    final ledger = parseAmount(account.ledgerBalance.amount);
    final (integer, decimals) = BnFormat.moneyParts(available, symbol: symbol);
    final held = (ledger - available).clamp(0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(account.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: BnType.family, fontSize: 15, color: BnColors.texto2)),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 3, height: 3, decoration: const BoxDecoration(color: BnColors.texto5, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(
                    shortNumber(account.maskedNumber),
                    style: const TextStyle(fontFamily: BnType.family, fontSize: 15, color: BnColors.texto2, fontFeatures: BnType.tabular),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Saldo disponible', style: BnType.footnote),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  text: integer,
                  children: [TextSpan(text: decimals, style: const TextStyle(fontSize: 24, color: BnColors.texto4))],
                ),
                style: BnType.saldo,
              ),
              BnRise(
                delay: const Duration(milliseconds: 160),
                offset: 10,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      Expanded(child: _StatCard(label: 'Saldo contable', value: formatMoney(account.ledgerBalance))),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(label: 'Valores retenidos', value: BnFormat.money(held, symbol: symbol))),
                    ],
                  ),
                ),
              ),
              if (controller.status == AccountDetailStatus.offlineStale) ...[
                const SizedBox(height: 16),
                ProductOfflineBanner(fetchedAt: controller.fetchedAt, onRetry: _refresh),
              ],
            ],
          ),
        ),
        BnRise(
          delay: const Duration(milliseconds: 210),
          offset: 10,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _RoundAction(
                    svg: AccountGlyphs.transfer,
                    label: 'Transferir',
                    dark: true,
                    onTap: () => Navigator.of(context).pushNamed(AppRoute.transfer),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _RoundAction(svg: AccountGlyphs.share, label: 'Compartir datos', onTap: () => _share(account))),
                const SizedBox(width: 8),
                Expanded(child: _RoundAction(svg: AccountGlyphs.list, label: 'Ver movimientos', onTap: () => _openTransactions(account))),
              ],
            ),
          ),
        ),
        BnRise(
          delay: const Duration(milliseconds: 260),
          offset: 10,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(header: true, child: const Text('Datos de la cuenta', style: _sectionTitle)),
                const SizedBox(height: 10),
                BnCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _DataRow(label: 'Titular', child: _DataValue(holderName(context))),
                      _DataRow(
                        label: 'Número',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _DataValue(_reveal ? account.maskedNumber : '•••• ${lastDigits(account.maskedNumber)}', tabular: true),
                            const SizedBox(width: 4),
                            _IconButton(
                              svg: BnGlyphs.eye,
                              label: _reveal ? 'Ocultar número' : 'Mostrar número completo',
                              onTap: () => setState(() => _reveal = !_reveal),
                            ),
                            const SizedBox(width: 4),
                            _IconButton(svg: AccountGlyphs.copy, label: 'Copiar número de cuenta', onTap: () => _copyNumber(account)),
                          ],
                        ),
                      ),
                      _DataRow(label: 'Tipo', child: _DataValue(accountTypeShort(account.type))),
                      _DataRow(label: 'Moneda', child: _DataValue(currencyName(account.currency))),
                      _DataRow(
                        label: 'Estado',
                        divider: false,
                        child: AccountStatusLabel(status: account.status, fontSize: 15, iconSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        BnRise(
          delay: const Duration(milliseconds: 310),
          offset: 10,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: _RecentTransactions(
              controller: _recent,
              onSeeAll: () => _openTransactions(account),
              onOpen: (id) => _openTransactions(account, openId: id),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => BnCard(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: BnType.family, fontSize: 12, color: BnColors.texto3)),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: BnType.family, fontSize: 17, fontWeight: FontWeight.w600, color: BnColors.carbon, fontFeatures: BnType.tabular),
            ),
          ],
        ),
      );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.svg, required this.label, required this.onTap, this.dark = false});

  final String svg;
  final String label;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) => BnPressable(
        onTap: onTap,
        scale: .96,
        semanticLabel: label,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dark ? BnColors.carbon : BnColors.superficie,
                shape: BoxShape.circle,
                border: dark ? null : Border.all(color: BnColors.hairline),
              ),
              child: BnSvg(svg, size: 22, color: dark ? BnColors.superficie : BnColors.carbon),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: BnType.family, fontSize: 13, fontWeight: FontWeight.w500, color: BnColors.carbon),
            ),
          ],
        ),
      );
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.child, this.divider = true});

  final String label;
  final Widget child;
  final bool divider;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(border: divider ? const Border(bottom: BorderSide(color: BnColors.relleno)) : null),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontFamily: BnType.family, fontSize: 15, color: BnColors.texto2)),
            const SizedBox(width: 12),
            Expanded(child: Align(alignment: Alignment.centerRight, child: child)),
          ],
        ),
      );
}

class _DataValue extends StatelessWidget {
  const _DataValue(this.text, {this.tabular = false});

  final String text;
  final bool tabular;

  @override
  Widget build(BuildContext context) => Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: BnType.family,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: BnColors.carbon,
          fontFeatures: tabular ? BnType.tabular : null,
        ),
      );
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.svg, required this.label, required this.onTap});

  final String svg;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BnPressable(
        onTap: onTap,
        scale: .96,
        semanticLabel: label,
        child: SizedBox(width: 36, height: 36, child: Center(child: BnSvg(svg, size: 18, color: BnColors.texto2))),
      );
}

/// "Últimos movimientos": the two latest movements or the dashed empty box.
class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.controller, required this.onSeeAll, required this.onOpen});

  final TransactionsController controller;
  final VoidCallback onSeeAll;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final items = controller.items.take(2).toList(growable: false);
          final loading = items.isEmpty &&
              (controller.status == TransactionsStatus.idle || controller.status == TransactionsStatus.loading);
          final failed = items.isEmpty && controller.status == TransactionsStatus.error;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Semantics(header: true, child: const Text('Últimos movimientos', style: _sectionTitle))),
                    BnPressable(
                      onTap: onSeeAll,
                      scale: 1,
                      opacity: .6,
                      child: const SizedBox(
                        height: 44,
                        child: Center(
                          widthFactor: 1,
                          child: Text('Ver todos', style: TextStyle(fontFamily: BnType.family, fontSize: 15, fontWeight: FontWeight.w500, color: BnColors.carbon)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                for (var i = 0; i < 2; i++)
                  const SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        BnSkeleton(width: 40, height: 40, circle: true),
                        SizedBox(width: 12),
                        Expanded(child: Align(alignment: Alignment.centerLeft, child: BnSkeleton(width: 140, height: 14))),
                        BnSkeleton(width: 60, height: 14),
                      ],
                    ),
                  )
              else if (items.isNotEmpty)
                for (var i = 0; i < items.length; i++)
                  TransactionRow(
                    transaction: items[i],
                    compact: true,
                    divider: i < items.length - 1,
                    onTap: () => onOpen(items[i].id),
                  )
              else
                _EmptyRecent(
                  title: failed ? (controller.errorMessage ?? 'No pudimos cargar tus movimientos.') : 'Aún no tienes movimientos.',
                  message: failed
                      ? 'Desliza hacia abajo para reintentar.'
                      : 'Comparte los datos de esta cuenta para recibir tu primer depósito.',
                ),
            ],
          );
        },
      );
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: DashedBorder(
          color: BnColors.lineaFuerte,
          radius: 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontFamily: BnType.family, fontSize: 15, fontWeight: FontWeight.w600, color: BnColors.carbon)),
                const SizedBox(height: 4),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: BnType.family, fontSize: 14, color: BnColors.texto2)),
              ],
            ),
          ),
        ),
      );
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BnSkeleton(width: 200, height: 15),
            SizedBox(height: 18),
            BnSkeleton(width: 110, height: 13),
            SizedBox(height: 8),
            BnSkeleton(width: 210, height: 42, radius: 10),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: BnSkeleton(height: 64, radius: 14)),
                SizedBox(width: 12),
                Expanded(child: BnSkeleton(height: 64, radius: 14)),
              ],
            ),
            SizedBox(height: 28),
            BnSkeleton(height: 240, radius: 18),
          ],
        ),
      );
}
