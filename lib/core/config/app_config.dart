import 'package:flutter/foundation.dart';

enum AppEnvironment { local, dev, test, demo, prodEvolution }

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.environment,
    required this.enableDemoTools,
    this.requestTimeout = const Duration(seconds: 12),
    this.splashMinimumDuration = const Duration(milliseconds: 700),
  });

  final String apiBaseUrl;
  final AppEnvironment environment;
  final bool enableDemoTools;
  final Duration requestTimeout;
  final Duration splashMinimumDuration;

  bool get demoToolsEnabled =>
      kDebugMode || (environment == AppEnvironment.demo && enableDemoTools);

  factory AppConfig.fromEnvironment() {
    const environmentName = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'local',
    );
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    final baseUrl =
        configuredBaseUrl.isNotEmpty ? configuredBaseUrl : _defaultLocalBaseUrl;

    return AppConfig(
      apiBaseUrl: baseUrl.replaceFirst(RegExp(r'/$'), ''),
      environment: _parseEnvironment(environmentName),
      enableDemoTools: const bool.fromEnvironment(
        'ENABLE_DEMO_TOOLS',
        defaultValue: false,
      ),
    );
  }

  static AppEnvironment _parseEnvironment(String value) {
    return AppEnvironment.values.firstWhere(
      (environment) => environment.name == value,
      orElse: () => AppEnvironment.local,
    );
  }

  static String get _defaultLocalBaseUrl {
    return 'https://9hqbzkgw-3000.use.devtunnels.ms/v1';
  }
}
