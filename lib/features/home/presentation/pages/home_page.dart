import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../../app/routing/app_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/design_system/binova_widgets.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/accounts_controller.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../dashboard/presentation/providers/dashboard_controller.dart';
import '../../../notifications/presentation/providers/notifications_controller.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart' as transaction_domain;
import '../../../transactions/presentation/providers/transactions_controller.dart';
import '../widgets/home_account_expansion.dart';
import '../widgets/home_balance_card.dart';
import '../widgets/home_data.dart';
import '../widgets/home_for_you.dart';
import '../widgets/home_header.dart';
import '../widgets/home_more_services_sheet.dart';
import '../widgets/home_movements.dart';
import '../widgets/home_offline_banner.dart';
import '../widgets/home_products_card.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_skeleton.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final AccountsController _accounts = context.read<AccountsController>();
  TransactionsController? _transactions;
  Timer? _ticker;
  bool _hidden = false;
  bool _retrying = false;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _accounts.addListener(_syncTransactions);

    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardController>().load();
      _accounts.load();
      final notifications = context.read<NotificationsController>();
      if (notifications.status == NotificationsStatus.idle) notifications.load();
      _syncTransactions();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _accounts.removeListener(_syncTransactions);

    _transactions?.removeListener(_onTransactions);
    super.dispose();
  }


  Account? get _mainAccount {
    final list = _accounts.accounts;
    if (list.isEmpty) return null;
    return list.firstWhere((a) => a.type != AccountType.credit, orElse: () => list.first);
  }

  void _syncTransactions() {
    final account = _mainAccount;
    if (!mounted || account == null || _transactions?.accountId == account.id) return;
    _transactions?.removeListener(_onTransactions);
    _transactions = TransactionsController(context.read<transaction_domain.TransactionRepository>(), account.id)
      ..addListener(_onTransactions)
      ..load();
  }

  void _onTransactions() {
    if (mounted) setState(() {});
  }

  Future<void> _reload() => Future.wait<void>([
        context.read<DashboardController>().load(),
        _accounts.load(),
        if (_transactions != null) _transactions!.load(),
      ]);


  Future<void> _retry() async {
    BnHaptics.tap();
    setState(() => _retrying = true);
    await _reload();
    if (mounted) setState(() => _retrying = false);
  }

  void _push(String route, {Object? arguments}) => Navigator.of(context).pushNamed(route, arguments: arguments);

  void _switchTab(String route) => Navigator.of(context).pushReplacementNamed(route);

  void _openProduct(Account account, Rect rowRect) {
    if (account.type == AccountType.credit) {
      BnHaptics.tap();
      _push(AppRoute.cards, arguments: 'credit');
      return;
    }
    playHomeAccountExpansion(
      context,
      from: rowRect,
      name: account.name,
      maskedNumber: account.maskedNumber,

      amount: BnFormat.money(homeAmount(account.availableBalance.amount),
          symbol: BnFormat.currencySymbol(account.currency)),
      navigate: () => _push(AppRoute.accountDetail, arguments: AccountRouteArgs(account.id, fromHome: true)),
    );
  }

  void _openMore() => showHomeMoreServices(context, onExchange: () => _push(AppRoute.exchange));

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardController>();
    context.watch<AccountsController>();
    final notifications = context.watch<NotificationsController>();
    final auth = context.watch<AuthController>();
    final status = dashboard.status;
    final loading = status == DashboardStatus.idle || status == DashboardStatus.loading;

    if (loading && (dashboard.config == null || _retrying)) return const HomeSkeleton();

    if (status == DashboardStatus.loaded) _wasOffline = false;
    if (status == DashboardStatus.offlineStale) _wasOffline = true;
    final offline = status == DashboardStatus.offlineStale || (loading && _wasOffline);

    final displayName = auth.session?.user.displayName ?? 'Pierre';
    if (dashboard.config == null) return _error(displayName, dashboard.errorMessage);

    final data = HomeData.from(
      config: dashboard.config,
      accounts: _accounts.accounts,
      transactions: _transactions?.items ?? const <Transaction>[],
      fetchedAt: dashboard.fetchedAt,
    );
    if (offline) return _offline(displayName, data, dashboard.fetchedAt);

    final demoTools = context.read<AppConfig>().demoToolsEnabled;
    Widget st(int delayMs, Widget child) => SliverToBoxAdapter(
          child:
              BnRise(delay: Duration(milliseconds: delayMs), duration: const Duration(milliseconds: 360), child: child),
        );

    return BnTabScaffold(
      tab: BnTab.home,
      onRefresh: _reload,
      slivers: [
        st(
          0,
          HomeHeader(
            displayName: displayName,
            onAvatar: () => _switchTab(AppRoute.profile),

            onAvatarLongPress: demoTools ? () => _push(AppRoute.developerTools) : null,
            onBell: () => _push(AppRoute.notifications),
            hasUnread: notifications.items.any((n) => !n.read),
          ),
        ),
        st(40, HomeBalanceCard(data: data, hidden: _hidden, onToggle: () => setState(() => _hidden = !_hidden))),
        st(
          80,
          HomeQuickActions(
            onTransfer: () => _push(AppRoute.transfer),
            onPay: () => _push(AppRoute.payment),
            onTopup: () => _push(AppRoute.topup),
            onMore: _openMore,
          ),
        ),
        st(
          120,
          HomeProductsCard(
            data: data,
            hidden: _hidden,
            onTap: _openProduct,
            onSeeAll: () => _switchTab(AppRoute.accounts),
          ),
        ),
        st(
          160,
          HomeForYou(
            onInsights: () => _switchTab(AppRoute.insights),
            onExchange: () => _push(AppRoute.exchange),
          ),
        ),
        if (data.movements.isNotEmpty)
          st(
            200,
            HomeMovements(
              data: data,
              onOpen: (t) => _push(
                AppRoute.transactions,
                arguments: AccountRouteArgs(_transactions!.accountId, fromHome: true, transactionId: t.id),
              ),
              onSeeAll: () => _push(AppRoute.transactions, arguments: AccountRouteArgs(_transactions!.accountId, fromHome: true)),
            ),
          ),
      ],
    );
  }


  Widget _offline(String displayName, HomeData data, DateTime? fetchedAt) {
    final at = fetchedAt ?? DateTime.now();
    void noop() {}
    return BnTabScaffold(
      tab: BnTab.home,
      onRefresh: _reload,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeHeader(displayName: displayName),
              HomeOfflineBanner(
                title: 'Sin conexión.',
                message: 'Mostrando la última información disponible.',
                updatedAt: at,
                onRetry: _retry,
              ),
              HomeBalanceCard(data: data, hidden: _hidden, offlineAt: at),
              HomeQuickActions(onTransfer: noop, onPay: noop, onTopup: noop, onMore: noop, enabled: false),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  'Las operaciones se habilitarán al recuperar la conexión.',
                  textAlign: TextAlign.center,
                  style: BnType.footnote,
                ),
              ),
              HomeProductsCard(data: data, hidden: _hidden),
            ],
          ),
        ),
      ],
    );
  }


  Widget _error(String displayName, String? message) => BnTabScaffold(
        tab: BnTab.home,
        onRefresh: _reload,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeHeader(displayName: displayName),
                HomeOfflineBanner(
                  title: message ?? 'No pudimos cargar tu inicio.',
                  message: 'Revisa tu conexión e inténtalo de nuevo.',
                  onRetry: _retry,
                ),
              ],
            ),
          ),
        ],
      );
}
