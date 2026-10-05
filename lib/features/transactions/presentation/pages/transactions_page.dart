import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/binova_widgets.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/accounts_controller.dart';
import '../../../accounts/presentation/widgets/account_ui.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transactions_controller.dart';
import '../widgets/transaction_ui.dart';

final _download = bnLine('<path d="M12 4v11"/><path d="M8 11l4 4 4-4"/><path d="M5 20h14"/>', stroke: 1.7);
final _search = bnLine('<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>', stroke: 2);
final _inbox = bnLine('<path d="M3 13l3-8h12l3 8v6a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z"/><path d="M3 13h5l1.5 2.5h5L16 13h5"/>', stroke: 1.5);
final _shareCta = bnLine('<path d="M12 3v12"/><path d="M8 7l4-4 4 4"/><path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7"/>', stroke: 1.8);

enum _Filter { all, income, expense }

const _toastDuration = Duration(milliseconds: 2400);

/// Movimientos (Movimientos.dc.html) and its empty state (Estado-Vacio.dc.html).
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    required this.accountId,
    this.backLabel,
    this.initialTransactionId,
    this.tab = BnTab.products,
    super.key,
  });

  final String accountId;

  /// Back label; defaults to the account type ("Ahorros"), as when pushed from Cuenta.
  final String? backLabel;

  /// Opens this movement's detail sheet as soon as the list loads.
  final String? initialTransactionId;
  final BnTab tab;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _scroll = ScrollController();
  final _query = TextEditingController();
  late final TransactionsController _controller = context.read<TransactionsController>();
  _Filter _filter = _Filter.all;
  String? _pendingOpenId;
  String? _toast;
  int _toastId = 0;

  @override
  void initState() {
    super.initState();
    _pendingOpenId = widget.initialTransactionId;
    _controller.addListener(_onControllerChanged);
    _scroll.addListener(_maybeLoadMore);
    _query.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.load();
      final accounts = context.read<AccountsController>();
      if (accounts.accounts.isEmpty && accounts.status == AccountsStatus.idle) accounts.load();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _scroll.dispose();
    _query.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final ready = _controller.status == TransactionsStatus.loaded || _controller.status == TransactionsStatus.offlineStale;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeLoadMore();
      final id = _pendingOpenId;
      if (!ready || id == null) return;
      _pendingOpenId = null;
      for (final t in _controller.items) {
        if (t.id == id) {
          _openDetail(t);
          break;
        }
      }
    });
  }

  void _maybeLoadMore() {
    final c = _controller;
    if (!_scroll.hasClients || c.nextCursor == null || c.isLoadingMore || c.loadMoreError != null) return;
    if (_scroll.position.extentAfter < 400) c.loadMore();
  }

  Account? get _account {
    for (final a in context.read<AccountsController>().accounts) {
      if (a.id == widget.accountId) return a;
    }
    return null;
  }

  void _flash(String message) => setState(() {
        _toast = message;
        _toastId++;
      });

  Future<void> _openDetail(Transaction t) async {
    final account = _account;
    final action = await showTransactionDetailSheet(
      context,
      t,
      accountLabel: account == null ? null : '${accountTypeShort(account.type)} ${shortNumber(account.maskedNumber)}',
    );
    if (action != null && mounted) _flash(transactionActionMessage(action));
  }

  Future<void> _shareAccount(Account? account) async {
    if (account == null) {
      Navigator.of(context).maybePop();
      return;
    }
    final copied = await showAccountShareSheet(context, account);
    if (copied && mounted) _flash('Número copiado');
  }

  List<Transaction> _visible(List<Transaction> items) {
    final q = _query.text.trim().toLowerCase();
    return items.where((t) {
      final kindOk = switch (_filter) {
        _Filter.all => true,
        _Filter.income => isIncome(t),
        _Filter.expense => !isIncome(t),
      };
      if (!kindOk) return false;
      if (q.isEmpty) return true;
      return transactionTitle(t).toLowerCase().contains(q) || transactionCategory(t).label.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TransactionsController>();
    context.watch<AccountsController>();
    final account = _account;
    final loading = (c.status == TransactionsStatus.idle || c.status == TransactionsStatus.loading) && c.items.isEmpty;
    final failed = c.status == TransactionsStatus.error && c.items.isEmpty;
    final empty = !loading && !failed && c.items.isEmpty;

    return BnTabScaffold(
      tab: widget.tab,
      controller: _scroll,
      onRefresh: c.items.isEmpty ? null : c.load,
      slivers: [
        SliverToBoxAdapter(
          child: BnNavBar(
            backLabel: widget.backLabel ?? (account == null ? 'Cuenta' : accountTypeShort(account.type)),
            trailing: empty || failed
                ? null
                : BnPressable(
                    onTap: () => _flash('Estado de cuenta enviado a tu correo'),
                    semanticLabel: 'Descargar estado de cuenta',
                    child: SizedBox(width: 44, height: 44, child: Center(child: BnSvg(_download, size: 22, color: BnColors.carbon))),
                  ),
          ),
        ),
        SliverToBoxAdapter(child: _Header(account: account)),
        if (loading)
          const SliverToBoxAdapter(child: _ListSkeleton())
        else if (failed)
          _FillRemaining(
            child: ProductMessageState(
              svg: AccountGlyphs.wifiOff,
              title: c.errorMessage ?? 'No pudimos cargar tus movimientos.',
              message: 'Revisa tu conexión e inténtalo de nuevo.',
              actionLabel: 'Reintentar',
              onAction: c.load,
            ),
          )
        else if (empty)
          _FillRemaining(
            child: ProductMessageState(
              svg: _inbox,
              title: 'Aún no tienes movimientos.',
              message: 'Cuando uses esta cuenta, verás aquí cada ingreso y gasto.',
              actionLabel: 'Compartir datos de cuenta',
              actionSvg: _shareCta,
              onAction: () => _shareAccount(account),
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  _SearchField(controller: _query),
                  const SizedBox(height: 12),
                  _FilterControl(value: _filter, onChanged: (f) => setState(() => _filter = f)),
                  if (c.status == TransactionsStatus.offlineStale) ...[
                    const SizedBox(height: 16),
                    ProductOfflineBanner(fetchedAt: c.fetchedAt, onRetry: c.load),
                  ],
                ],
              ),
            ),
          ),
          ..._groups(_visible(c.items)),
          SliverToBoxAdapter(child: _LoadMoreFooter(controller: c)),
        ],
      ],
      overlays: [
        if (_toast != null)
          ProductToast(
            key: ValueKey(_toastId),
            message: _toast!,
            duration: _toastDuration,
            onDone: () => setState(() => _toast = null),
          ),
      ],
    );
  }

  List<Widget> _groups(List<Transaction> list) {
    if (list.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 40, 20, 0),
            child: Text(
              'No encontramos movimientos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: BnType.family, fontSize: 15, color: BnColors.texto2),
            ),
          ),
        ),
      ];
    }
    final groups = <(String, List<(int, Transaction)>)>[];
    for (var k = 0; k < list.length; k++) {
      final title = BnFormat.daySection(list[k].occurredAt.toLocal());
      if (groups.isEmpty || groups.last.$1 != title) groups.add((title, []));
      groups.last.$2.add((k, list[k]));
    }
    return [
      for (final g in groups)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverList.list(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Semantics(
                  header: true,
                  child: Text(
                    g.$1.toUpperCase(),
                    style: const TextStyle(fontFamily: BnType.family, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.52, color: BnColors.texto2),
                  ),
                ),
              ),
              for (final (k, t) in g.$2)
                BnRise(
                  key: ValueKey(t.id),
                  delay: Duration(milliseconds: math.min(k * 35, 280)),
                  child: TransactionRow(transaction: t, onTap: () => _openDetail(t)),
                ),
            ],
          ),
        ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.account});

  final Account? account;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BnLargeTitle('Movimientos', padding: EdgeInsets.zero),
            if (account != null) ...[
              const SizedBox(height: 4),
              Text(
                '${account!.name} ${shortNumber(account!.maskedNumber)}',
                style: const TextStyle(fontFamily: BnType.family, fontSize: 14, color: BnColors.texto2, fontFeatures: BnType.tabular),
              ),
            ],
          ],
        ),
      );
}

/// Fills the viewport between the header and the tab bar (`flex: 1` centering).
class _FillRemaining extends StatelessWidget {
  const _FillRemaining({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
        builder: (context, constraints) {
          final reserved = BnTabBar.heightOf(context) + 28;
          final height = constraints.viewportMainAxisExtent - constraints.precedingScrollExtent - reserved;
          return SliverToBoxAdapter(
            child: SizedBox(height: math.max(height, 380), child: Center(child: child)),
          );
        },
      );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: BnColors.rellenoCampo, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            BnSvg(_search, size: 17, color: BnColors.texto2),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                cursorColor: BnColors.carbon,
                style: const TextStyle(fontFamily: BnType.family, fontSize: 16, color: BnColors.carbon),
                decoration: const InputDecoration.collapsed(
                  hintText: 'Buscar movimientos',
                  hintStyle: TextStyle(fontFamily: BnType.family, fontSize: 16, color: BnColors.placeholder),
                ),
              ),
            ),
          ],
        ),
      );
}

/// `role="tablist"` segmented filter: 14 pt labels, `.seg` 220 ms transitions.
class _FilterControl extends StatelessWidget {
  const _FilterControl({required this.value, required this.onChanged});

  final _Filter value;
  final ValueChanged<_Filter> onChanged;

  static const _items = [(_Filter.all, 'Todos'), (_Filter.income, 'Ingresos'), (_Filter.expense, 'Egresos')];

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: BnColors.rellenoCampo, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(child: _segment(_items[i].$1, _items[i].$2)),
            ],
          ],
        ),
      );

  Widget _segment(_Filter filter, String label) {
    final selected = filter == value;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (selected) return;
          BnHaptics.tap();
          onChanged(filter);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.ease,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? BnColors.superficie : const Color(0x00FFFFFF),
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected ? const [BoxShadow(color: Color(0x1A141518), blurRadius: 3, offset: Offset(0, 1))] : const [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: BnType.family,
              fontSize: 14,
              color: BnColors.carbon,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.controller});

  final TransactionsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingMore) {
      return const Padding(padding: EdgeInsets.fromLTRB(20, 4, 20, 0), child: _SkeletonRow());
    }
    final error = controller.loadMoreError;
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(child: Text(error, style: BnType.footnote)),
          BnPressable(
            onTap: controller.loadMore,
            child: const SizedBox(
              height: 44,
              child: Center(
                widthFactor: 1,
                child: Text('Reintentar', style: TextStyle(fontFamily: BnType.family, fontSize: 15, fontWeight: FontWeight.w500, color: BnColors.carbon)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BnSkeleton(height: 40, radius: 12),
            const SizedBox(height: 12),
            const BnSkeleton(height: 36, radius: 10),
            const SizedBox(height: 24),
            const BnSkeleton(width: 60, height: 12),
            const SizedBox(height: 4),
            for (var i = 0; i < 5; i++) const _SkeletonRow(),
          ],
        ),
      );
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 68,
        child: Row(
          children: [
            BnSkeleton(width: 42, height: 42, circle: true),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BnSkeleton(width: 140, height: 14),
                  SizedBox(height: 6),
                  BnSkeleton(width: 100, height: 11),
                ],
              ),
            ),
            BnSkeleton(width: 64, height: 14),
          ],
        ),
      );
}

/// Standalone movement detail (opened from Inicio / Avisos). Same visual as
/// the Movimientos sheet, laid out on a full white surface.
class TransactionDetailPage extends StatefulWidget {
  const TransactionDetailPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  String? _toast;
  int _toastId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TransactionDetailController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TransactionDetailController>();
    final t = c.transaction;
    final top = bnTopInset(context);
    final Widget body;
    if (t != null) {
      body = SingleChildScrollView(
        physics: bnScrollPhysics,
        padding: EdgeInsets.fromLTRB(20, top + 8, 20, bnBottomInset(context) + 20),
        child: Column(
          children: [
            if (c.status == TransactionDetailStatus.offlineStale) ...[
              ProductOfflineBanner(fetchedAt: c.fetchedAt, onRetry: c.load),
              const SizedBox(height: 12),
            ],
            TransactionDetailContent(
              transaction: t,
              onClose: () => Navigator.of(context).maybePop(),
              onAction: (action) => setState(() {
                _toast = transactionActionMessage(action);
                _toastId++;
              }),
            ),
          ],
        ),
      );
    } else if (c.status == TransactionDetailStatus.error) {
      body = Column(
        children: [
          SizedBox(height: top),
          const BnNavBar(),
          Expanded(
            child: Center(
              child: ProductMessageState(
                svg: AccountGlyphs.wifiOff,
                title: c.errorMessage ?? 'No pudimos cargar el detalle del movimiento.',
                message: 'Revisa tu conexión e inténtalo de nuevo.',
                actionLabel: 'Reintentar',
                onAction: c.load,
              ),
            ),
          ),
        ],
      );
    } else {
      body = Padding(
        padding: EdgeInsets.fromLTRB(20, top + 48, 20, 0),
        child: const Column(
          children: [
            BnSkeleton(width: 56, height: 56, circle: true),
            SizedBox(height: 16),
            BnSkeleton(width: 140, height: 16),
            SizedBox(height: 12),
            BnSkeleton(width: 180, height: 36, radius: 10),
            SizedBox(height: 28),
            BnSkeleton(height: 240, radius: 16),
          ],
        ),
      );
    }
    return BnScreen(
      background: BnColors.superficie,
      child: Stack(
        children: [
          Positioned.fill(child: body),
          if (_toast != null)
            ProductToast(
              key: ValueKey(_toastId),
              message: _toast!,
              duration: _toastDuration,
              onDone: () => setState(() => _toast = null),
            ),
        ],
      ),
    );
  }
}
