import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design_system/bn_sheet.dart';
import '../../core/design_system/bn_shell.dart';

import '../../core/security/biometric_authenticator.dart';
import '../../features/auth/presentation/pages/biometric_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/accounts/domain/repositories/account_repository.dart';
import '../../features/accounts/presentation/providers/accounts_controller.dart';
import '../../features/cards/domain/repositories/card_repository.dart';
import '../../features/cards/presentation/pages/cards_page.dart';
import '../../features/cards/presentation/providers/cards_controller.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/developer_tools/presentation/pages/developer_tools_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/insights/presentation/pages/insights_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/operations/domain/repositories/operations_repository.dart';
import '../../features/operations/presentation/pages/payment_page.dart';
import '../../features/operations/presentation/pages/topup_page.dart';
import '../../features/operations/presentation/pages/transfer_page.dart';
import '../../features/operations/presentation/providers/operation_flow_controller.dart';
import '../../features/exchange/domain/repositories/exchange_rate_repository.dart';
import '../../features/exchange/presentation/pages/exchange_page.dart';
import '../../features/exchange/presentation/providers/exchange_rate_controller.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/providers/profile_controller.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart'
    as transaction_domain;
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/transactions/presentation/providers/transactions_controller.dart';

abstract final class AppRoute {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const biometric = '/biometric';
  static const home = '/home';
  static const accounts = '/accounts';
  static const accountDetail = '/accounts/detail';
  static const transactions = '/transactions';
  static const transactionDetail = '/transactions/detail';
  static const cards = '/cards';
  static const createVirtualCard = '/cards/create-virtual';
  static const cardDetail = '/cards/detail';
  static const insights = '/insights';
  static const notifications = '/notifications';
  static const transfer = '/transfer';
  static const payment = '/payment';
  static const topup = '/topup';
  static const exchange = '/exchange';
  static const profile = '/profile';
  static const developerTools = '/developer-tools';
}



class AccountRouteArgs {
  const AccountRouteArgs(this.accountId, {this.fromHome = false, this.transactionId});

  final String accountId;
  final bool fromHome;
  final String? transactionId;

  static AccountRouteArgs? from(Object? arguments) => switch (arguments) {
        AccountRouteArgs args when args.accountId.isNotEmpty => args,
        String id when id.isNotEmpty => AccountRouteArgs(id),
        _ => null,
      };
}

abstract final class AppRouter {
  static const _tabRoutes = {AppRoute.home, AppRoute.accounts, AppRoute.insights, AppRoute.profile};
  static const _rootRoutes = {AppRoute.splash, AppRoute.onboarding, AppRoute.login, AppRoute.biometric};

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final child = _build(settings);
    final name = settings.name;
    if (_tabRoutes.contains(name)) return BnRoutes.instant<void>(child, settings: settings);


    if (name == AppRoute.accountDetail && (AccountRouteArgs.from(settings.arguments)?.fromHome ?? false)) {
      return BnRoutes.fade<void>(child, settings: settings, duration: const Duration(milliseconds: 120));
    }
    if (_rootRoutes.contains(name)) {
      return BnRoutes.fade<void>(child, settings: settings, duration: const Duration(milliseconds: 300));
    }
    return BnRoutes.push<void>(child, settings: settings);
  }

  static Widget _build(RouteSettings settings) {
    switch (settings.name) {
      case AppRoute.splash:
        return _page(const SplashPage());
      case AppRoute.onboarding:
        return _page(const OnboardingPage());
      case AppRoute.login:
        return _page(const LoginPage());
      case AppRoute.biometric:
        return _page(const BiometricPage());
      case AppRoute.home:
        return _page(const HomePage());
      case AppRoute.accounts:
        return _page(const AccountsPage());
      case AppRoute.accountDetail:
        final args = AccountRouteArgs.from(settings.arguments);
        if (args == null) return _page(const AccountsPage());
        final accountId = args.accountId;
        return _page(
          ChangeNotifierProvider<AccountDetailController>(
            create: (context) => AccountDetailController(
              context.read<AccountRepository>(),
              accountId,
            ),
            child: args.fromHome
                ? AccountDetailPage(accountId: accountId, backLabel: 'Inicio', tab: BnTab.home)
                : AccountDetailPage(accountId: accountId),
          ),
        );
      case AppRoute.transactions:
        final args = AccountRouteArgs.from(settings.arguments);
        if (args == null) return _page(const AccountsPage());
        final accountId = args.accountId;
        return _page(
          ChangeNotifierProvider<TransactionsController>(
            create: (context) => TransactionsController(
              context.read<transaction_domain.TransactionRepository>(),
              accountId,
            ),
            child: TransactionsPage(
              accountId: accountId,
              backLabel: args.fromHome ? 'Inicio' : null,
              tab: args.fromHome ? BnTab.home : BnTab.products,
              initialTransactionId: args.transactionId,
            ),
          ),
        );
      case AppRoute.transactionDetail:
        final transactionId = settings.arguments as String?;
        if (transactionId == null || transactionId.isEmpty) {
          return _page(const HomePage());
        }
        return _page(
          ChangeNotifierProvider<TransactionDetailController>(
            create: (context) => TransactionDetailController(
              context.read<transaction_domain.TransactionRepository>(),
              transactionId,
            ),
            child: TransactionDetailPage(transactionId: transactionId),
          ),
        );
      case AppRoute.cards:
        return _page(CardsPage(focus: settings.arguments as String?));
      case AppRoute.createVirtualCard:
        return _page(
          ChangeNotifierProvider<CardCreationController>(
            create: (context) => CardCreationController(
              context.read<CardRepository>(),
              context.read<BiometricAuthenticator>(),
            ),
            child: const VirtualCardCreationPage(),
          ),
        );
      case AppRoute.cardDetail:
        final cardId = settings.arguments as String?;
        if (cardId == null || cardId.isEmpty) {
          return _page(const CardsPage());
        }
        return _page(
          ChangeNotifierProvider<CardDetailController>(
            create: (context) => CardDetailController(
              context.read<CardRepository>(),
              cardId,
            ),
            child: CardDetailPage(cardId: cardId),
          ),
        );
      case AppRoute.insights:
        return _page(const InsightsPage());
      case AppRoute.notifications:
        return _page(const NotificationsPage());
      case AppRoute.transfer:
        return _page(
          ChangeNotifierProvider<OperationFlowController>(
            create: (context) => OperationFlowController(
              repository: context.read<OperationsRepository>(),
              biometric: context.read<BiometricAuthenticator>(),
            ),
            child: const TransferPage(),
          ),
        );
      case AppRoute.payment:
        return _page(
          ChangeNotifierProvider<OperationFlowController>(
            create: (context) => OperationFlowController(
              repository: context.read<OperationsRepository>(),
              biometric: context.read<BiometricAuthenticator>(),
            ),
            child: const PaymentPage(),
          ),
        );
      case AppRoute.topup:
        return _page(
          ChangeNotifierProvider<OperationFlowController>(
            create: (context) => OperationFlowController(
              repository: context.read<OperationsRepository>(),
              biometric: context.read<BiometricAuthenticator>(),
            ),
            child: const TopupPage(),
          ),
        );
      case AppRoute.exchange:
        return _page(
          ChangeNotifierProvider<ExchangeRateController>(
            create: (context) => ExchangeRateController(
              context.read<ExchangeRateRepository>(),
            ),
            child: const ExchangePage(),
          ),
        );
      case AppRoute.profile:
        return _page(
          ChangeNotifierProvider<ProfileController>(
            create: (context) => ProfileController(
              context.read<ProfileRepository>(),
            ),
            child: const ProfilePage(),
          ),
        );
      case AppRoute.developerTools:
        return _page(const DeveloperToolsPage());
      default:
        return _page(const SplashPage());
    }
  }

  static Widget _page(Widget child) => child;
}
