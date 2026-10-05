import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../core/storage/onboarding_store.dart';
import '../core/network/demo_network_mode.dart';
import '../core/security/biometric_authenticator.dart';
import '../core/security/biometric_preference_store.dart';
import '../features/auth/presentation/providers/auth_controller.dart';
import '../features/accounts/presentation/providers/accounts_controller.dart';
import '../features/cards/domain/repositories/card_repository.dart';
import '../features/cards/presentation/providers/cards_controller.dart';
import '../features/dashboard/presentation/providers/dashboard_controller.dart';
import '../features/insights/presentation/providers/insights_controller.dart';
import '../features/notifications/domain/repositories/notification_repository.dart';
import '../features/notifications/presentation/providers/notifications_controller.dart';
import '../features/operations/domain/repositories/operations_repository.dart';
import '../features/exchange/domain/repositories/exchange_rate_repository.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import 'bootstrap/app_services.dart';
import 'bootstrap/bootstrap_controller.dart';
import 'routing/app_router.dart';
import 'theme/binova_theme.dart';

class BInovaApp extends StatelessWidget {
  const BInovaApp({required this.services, super.key});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: services.config),
        ChangeNotifierProvider<DemoNetworkModeController>.value(
          value: services.demoNetworkMode,
        ),
        Provider<OnboardingStore>.value(value: services.onboardingStore),
        Provider<BiometricAuthenticator>.value(
          value: services.biometricAuthenticator,
        ),
        Provider<BiometricPreferenceStore>.value(
          value: services.biometricPreferenceStore,
        ),
        ChangeNotifierProvider<BootstrapController>(
          create: (_) => BootstrapController(
            repository: services.authRepository,
            config: services.config,
          )..start(),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(
            repository: services.authRepository,
            biometric: services.biometricAuthenticator,
            observability: services.observability,
            pushNotifications: services.pushNotifications,
          ),
        ),
        ChangeNotifierProvider<DashboardController>(
          create: (_) => DashboardController(services.dashboardRepository),
        ),
        ChangeNotifierProvider<AccountsController>(
          create: (_) => AccountsController(services.accountRepository),
        ),
        Provider.value(value: services.accountRepository),
        Provider.value(value: services.transactionRepository),
        Provider<CardRepository>.value(value: services.cardRepository),
        ChangeNotifierProvider<CardsController>(
          create: (_) => CardsController(services.cardRepository),
        ),
        Provider.value(value: services.insightsRepository),
        ChangeNotifierProvider<InsightsController>(
          create: (_) => InsightsController(services.insightsRepository),
        ),
        Provider<NotificationRepository>.value(
            value: services.notificationRepository),
        ChangeNotifierProvider<NotificationsController>(
          create: (_) =>
              NotificationsController(services.notificationRepository),
        ),
        Provider<OperationsRepository>.value(
            value: services.operationsRepository),
        Provider<ExchangeRateRepository>.value(
            value: services.exchangeRateRepository),
        Provider<ProfileRepository>.value(value: services.profileRepository),
      ],
      child: MaterialApp(
        navigatorKey: services.pushNavigation.navigatorKey,
        title: 'BInova',
        debugShowCheckedModeBanner: false,
        theme: BinovaTheme.light(),
        initialRoute: AppRoute.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
