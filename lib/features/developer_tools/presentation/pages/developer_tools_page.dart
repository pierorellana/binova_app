import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/design_system/binova_tokens.dart';
import '../../../../core/network/demo_network_mode.dart';

class DeveloperToolsPage extends StatelessWidget {
  const DeveloperToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.read<AppConfig>();
    if (!config.demoToolsEnabled) {
      return const Scaffold(
        body: Center(child: Text('Developer Tools no está disponible.')),
      );
    }

    final controller = context.watch<DemoNetworkModeController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Tools')),
      body: ListView(
        padding: const EdgeInsets.all(BinovaSpacing.xl),
        children: [
          Text(
            'Escenarios de conectividad',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: BinovaSpacing.sm),
          const Text(
            'Estos escenarios solo afectan las llamadas del ApiClient y no '
            'están disponibles en builds productivos.',
          ),
          const SizedBox(height: BinovaSpacing.lg),
          ...DemoNetworkMode.values.map(
            (mode) => RadioListTile<DemoNetworkMode>(
              contentPadding: EdgeInsets.zero,
              value: mode,
              groupValue: controller.value,
              onChanged: (value) {
                if (value != null) controller.value = value;
              },
              title: Text(_label(mode)),
              subtitle: Text(_description(mode)),
            ),
          ),
          const SizedBox(height: BinovaSpacing.lg),
          const Text(
            'Usa “offline” para validar caché stale, “server error” para '
            'validar errores recuperables y “timeout” para validar reintentos.',
          ),
        ],
      ),
    );
  }

  String _label(DemoNetworkMode mode) => switch (mode) {
        DemoNetworkMode.normal => 'Normal',
        DemoNetworkMode.slow => 'Slow',
        DemoNetworkMode.offline => 'Offline',
        DemoNetworkMode.serverError => 'Server error (500)',
        DemoNetworkMode.timeout => 'Timeout',
      };

  String _description(DemoNetworkMode mode) => switch (mode) {
        DemoNetworkMode.normal => 'Llamadas reales al API configurado.',
        DemoNetworkMode.slow => 'Retrasa cada llamada tres segundos.',
        DemoNetworkMode.offline => 'Simula ausencia de red antes de enviar.',
        DemoNetworkMode.serverError =>
          'Devuelve un error controlado del servidor.',
        DemoNetworkMode.timeout => 'Simula una llamada agotada por timeout.',
      };
}
