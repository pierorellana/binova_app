import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/authenticated_api_client.dart';
import '../../core/network/demo_network_mode.dart';
import '../../core/observability/observability.dart';
import '../../core/security/biometric_authenticator.dart';
import '../../core/security/biometric_preference_store.dart';
import '../../core/security/secure_session_store.dart';
import '../../core/storage/json_cache_store.dart';
import '../../core/storage/onboarding_store.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/accounts/data/datasources/account_remote_data_source.dart';
import '../../features/accounts/data/repositories/account_repository_impl.dart';
import '../../features/accounts/domain/repositories/account_repository.dart';
import '../../features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/cards/data/datasources/card_remote_data_source.dart';
import '../../features/cards/data/repositories/card_repository_impl.dart';
import '../../features/cards/domain/repositories/card_repository.dart';
import '../../features/transactions/data/datasources/transaction_remote_data_source.dart';
import '../../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';
import '../../features/insights/data/datasources/insights_remote_data_source.dart';
import '../../features/insights/data/repositories/insights_repository_impl.dart';
import '../../features/insights/domain/repositories/insights_repository.dart';
import '../../features/notifications/data/datasources/notification_remote_data_source.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/operations/data/datasources/operations_remote_data_source.dart';
import '../../features/operations/data/repositories/operations_repository_impl.dart';
import '../../features/operations/domain/repositories/operations_repository.dart';
import '../../features/exchange/data/datasources/exchange_rate_remote_data_source.dart';
import '../../features/exchange/data/repositories/exchange_rate_repository_impl.dart';
import '../../features/exchange/domain/repositories/exchange_rate_repository.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';

class AppServices {
  AppServices({
    required this.config,
    required this.authRepository,
    required this.onboardingStore,
    required this.biometricAuthenticator,
    required this.biometricPreferenceStore,
    required this.dashboardRepository,
    required this.accountRepository,
    required this.transactionRepository,
    required this.cardRepository,
    required this.insightsRepository,
    required this.notificationRepository,
    required this.operationsRepository,
    required this.exchangeRateRepository,
    required this.profileRepository,
    required this.observability,
    required this.demoNetworkMode,
  });

  final AppConfig config;
  final AuthRepository authRepository;
  final OnboardingStore onboardingStore;
  final BiometricAuthenticator biometricAuthenticator;
  final BiometricPreferenceStore biometricPreferenceStore;
  final DashboardRepository dashboardRepository;
  final AccountRepository accountRepository;
  final TransactionRepository transactionRepository;
  final CardRepository cardRepository;
  final InsightsRepository insightsRepository;
  final NotificationRepository notificationRepository;
  final OperationsRepository operationsRepository;
  final ExchangeRateRepository exchangeRateRepository;
  final ProfileRepository profileRepository;
  final Observability observability;
  final DemoNetworkModeController demoNetworkMode;

  static Future<AppServices> create() async {
    final config = AppConfig.fromEnvironment();
    final observability = DebugObservability(
      enabled: config.environment != AppEnvironment.prodEvolution,
    );
    final preferences = await SharedPreferences.getInstance();
    final secureStore = FlutterSecureSessionStore();
    final biometricPreferenceStore =
        SharedPreferencesBiometricPreferenceStore(preferences);
    final demoNetworkMode = DemoNetworkModeController();
    final apiClient = ApiClient(
      config: config,
      demoMode: demoNetworkMode,
      observability: observability,
    );
    final cache = SharedPreferencesJsonCacheStore(preferences);
    final biometricAuthenticator = LocalAuthBiometricAuthenticator();
    await biometricAuthenticator.initialize();
    final local = SecureAuthLocalDataSource(secureStore);
    final remote = HttpAuthRemoteDataSource(apiClient);
    final authenticatedClient = AuthenticatedApiClient(
      client: apiClient,
      sessionStore: secureStore,
      refreshSession: (refreshToken) =>
          remote.refresh(refreshToken: refreshToken),
    );
    return AppServices(
      config: config,
      authRepository: AuthRepositoryImpl(
        remote: remote,
        local: local,
        onboarding: SharedPreferencesOnboardingStore(preferences),
        biometricPreference: biometricPreferenceStore,
      ),
      onboardingStore: SharedPreferencesOnboardingStore(preferences),
      biometricAuthenticator: biometricAuthenticator,
      biometricPreferenceStore: biometricPreferenceStore,
      dashboardRepository: DashboardRepositoryImpl(
        remote: HttpDashboardRemoteDataSource(authenticatedClient),
        cache: cache,
      ),
      accountRepository: AccountRepositoryImpl(
        remote: HttpAccountRemoteDataSource(authenticatedClient),
        cache: cache,
      ),
      transactionRepository: TransactionRepositoryImpl(
        remote: HttpTransactionRemoteDataSource(authenticatedClient),
        cache: cache,
      ),
      cardRepository: CardRepositoryImpl(
        remote: HttpCardRemoteDataSource(authenticatedClient),
        cache: cache,
      ),
      insightsRepository: InsightsRepositoryImpl(
        remote: HttpInsightsRemoteDataSource(authenticatedClient),
        cache: cache,
      ),
      notificationRepository: NotificationRepositoryImpl(
        remote: HttpNotificationRemoteDataSource(authenticatedClient),
        cache: cache,
      ),
      operationsRepository: OperationsRepositoryImpl(
        HttpOperationsRemoteDataSource(authenticatedClient),
      ),
      exchangeRateRepository: ExchangeRateRepositoryImpl(
        remote: HttpExchangeRateRemoteDataSource(authenticatedClient),
        cache: cache,
      ),
      profileRepository: ProfileRepositoryImpl(
        HttpProfileRemoteDataSource(authenticatedClient),
      ),
      observability: observability,
      demoNetworkMode: demoNetworkMode,
    );
  }
}
