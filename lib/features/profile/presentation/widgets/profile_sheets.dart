import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';
import '../../domain/entities/device.dart';
import '../providers/profile_controller.dart';
import 'profile_switch.dart';

enum ProfileSheet { datos, seguridad, dispositivos, notificaciones, preferencias }



class ProfileLocalSwitches extends ChangeNotifier {
  bool faceIdPerOperation = true;
  bool accessAlerts = true;
  bool insightTips = true;

  void set(void Function(ProfileLocalSwitches s) change) {
    change(this);
    notifyListeners();
  }
}


Future<void> showProfileSheet(
  BuildContext context, {
  required ProfileSheet sheet,
  required ProfileController controller,
  required ProfileLocalSwitches local,
}) =>
    showBnSheet<void>(
      context,
      builder: (_) => ListenableBuilder(
        listenable: Listenable.merge([controller, local]),
        builder: (context, _) => _ProfileSheetBody(sheet: sheet, controller: controller, local: local),
      ),
    );



Future<bool> showLogoutSheet(BuildContext context) async {
  final confirmed = await showBnSheet<bool>(
    context,
    background: const Color(0x00FFFFFF),
    showHandle: false,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    builder: (_) => const _LogoutSheet(),
  );
  return confirmed ?? false;
}

class _ProfileSheetBody extends StatelessWidget {
  const _ProfileSheetBody({required this.sheet, required this.controller, required this.local});

  static const _titles = {
    ProfileSheet.datos: 'Datos personales',
    ProfileSheet.seguridad: 'Seguridad',
    ProfileSheet.dispositivos: 'Dispositivos',
    ProfileSheet.notificaciones: 'Notificaciones',
    ProfileSheet.preferencias: 'Preferencias',
  };

  final ProfileSheet sheet;
  final ProfileController controller;
  final ProfileLocalSwitches local;

  @override
  Widget build(BuildContext context) {
    final error = controller.errorMessage;
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BnSheetHeader(title: _titles[sheet]!),
          const SizedBox(height: 8),
          ...switch (sheet) {
            ProfileSheet.datos => _datos(),
            ProfileSheet.seguridad => _seguridad(),
            ProfileSheet.dispositivos => _dispositivos(),
            ProfileSheet.notificaciones => _notificaciones(),
            ProfileSheet.preferencias => _preferencias(),
          },
          if (error != null && controller.isReady) ...[
            const SizedBox(height: 12),
            Text(error, style: const TextStyle(fontFamily: BnType.family, fontSize: 13, height: 1.45, color: BnColors.critico)),
          ],
          const SizedBox(height: 20),
          BnButton(label: 'Listo', onTap: () => Navigator.of(context).maybePop()),
        ],
      ),
    );
  }

  List<Widget> _datos() {
    final user = controller.profile;
    return [
      _KvList([
        if (user != null) _Kv.text('Nombre', user.displayName, strong: true),
        if (user != null) _Kv.text('Correo', maskEmail(user.email), strong: true),
      ]),
      const SizedBox(height: 16),
      const Text(
        'Para cambiar tu nombre o cédula acércate a una agencia. Correo y celular se actualizan con Face ID.',
        style: TextStyle(fontFamily: BnType.family, fontSize: 13, height: 1.45, color: BnColors.texto3),
      ),
    ];
  }

  List<Widget> _seguridad() => [
        _KvList([
          _Kv.chevron('Cambiar contraseña'),
          _Kv.chevron('Clave de transacciones'),
          _Kv.toggle(
            'Pedir Face ID en cada operación',
            value: local.faceIdPerOperation,
            onChanged: (v) => local.set((s) => s.faceIdPerOperation = v),
          ),
          _Kv.toggle(
            'Avisarme de nuevos accesos',
            value: local.accessAlerts,
            onChanged: (v) => local.set((s) => s.accessAlerts = v),
          ),
        ]),
      ];

  List<Widget> _dispositivos() {
    final devices = controller.devices;
    if (devices.isEmpty) {
      return const [
        _KvList([_Kv(child: Text('No hay dispositivos registrados.', style: TextStyle(color: BnColors.texto3)))]),
      ];
    }
    return [
      _KvList([for (final d in devices) _Kv(child: _DeviceRow(device: d, onRevoke: () => controller.revokeDevice(d.id)))]),
    ];
  }

  List<Widget> _notificaciones() {
    final prefs = controller.preferences;
    final busy = controller.status == ProfileStatus.updating;
    return [
      _KvList([
        _Kv.toggle(
          'Movimientos y pagos',
          value: prefs?.notificationsEnabled ?? false,
          onChanged: prefs == null || busy ? null : (v) => controller.updatePreference('notificationsEnabled', v),
        ),
        _Kv.text('Seguridad', 'Siempre activas', small: true),
        _Kv.toggle(
          'Recomendaciones de Insights',
          value: local.insightTips,
          onChanged: (v) => local.set((s) => s.insightTips = v),
        ),
      ]),
    ];
  }

  List<Widget> _preferencias() {
    final prefs = controller.preferences;
    final busy = controller.status == ProfileStatus.updating;
    return [
      _KvList([
        _Kv.text('Idioma', 'Español'),
        _Kv.toggle(
          'Ocultar saldo al abrir',
          value: prefs?.hideBalance ?? false,
          onChanged: prefs == null || busy ? null : (v) => controller.updatePreference('hideBalance', v),
        ),
        _Kv.text('Reducir movimiento', 'Según el sistema'),
      ]),
    ];
  }
}


String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 1) return email;
  return '${email[0]}${'*' * (at - 1)}${email.substring(at)}';
}


class _KvList extends StatelessWidget {
  const _KvList(this.rows);

  final List<_Kv> rows;

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: BnType.family, fontSize: 15, color: BnColors.carbon),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++)
              Container(
                constraints: const BoxConstraints(minHeight: 52),
                decoration: BoxDecoration(
                  border: i == rows.length - 1 ? null : const Border(bottom: BorderSide(color: BnColors.relleno)),
                ),
                alignment: Alignment.centerLeft,
                child: rows[i],
              ),
          ],
        ),
      );
}

class _Kv extends StatelessWidget {
  const _Kv({required this.child});

  factory _Kv.text(String label, String value, {bool strong = false, bool small = false}) => _Kv(
        child: _KvRow(
          label: Text(label, style: strong ? const TextStyle(color: BnColors.texto2) : null),
          trailing: Text(
            value,
            textAlign: TextAlign.right,
            style: strong
                ? const TextStyle(fontWeight: FontWeight.w500)
                : TextStyle(fontSize: small ? 13 : 15, color: small ? BnColors.texto3 : BnColors.texto2),
          ),
        ),
      );

  factory _Kv.chevron(String label) => _Kv(
        child: _KvRow(label: Text(label), trailing: BnSvg(BnGlyphs.chevronRight, size: 16, color: BnColors.texto5)),
      );

  factory _Kv.toggle(String label, {required bool value, required ValueChanged<bool>? onChanged}) => _Kv(
        child: _KvRow(
          label: Text(label),
          trailing: ProfileSwitch(value: value, onChanged: onChanged, label: label),
        ),
      );

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.label, required this.trailing});

  final Widget label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: label),
          const SizedBox(width: 12),
          trailing,
        ],
      );
}

class _DeviceRow extends StatefulWidget {
  const _DeviceRow({required this.device, required this.onRevoke});

  final Device device;
  final Future<void> Function() onRevoke;

  @override
  State<_DeviceRow> createState() => _DeviceRowState();
}

class _DeviceRowState extends State<_DeviceRow> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _revoke() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await widget.onRevoke();
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    final seen = BnFormat.relativeDay(d.lastSeenAt.toLocal());
    final platform = d.platform == DevicePlatform.ios ? 'iOS' : 'Android';
    final subtitle = _failed
        ? 'No pudimos cerrar la sesión. Inténtalo de nuevo.'
        : d.active
            ? '$platform · ${seen[0].toLowerCase()}${seen.substring(1)}'
            : 'Sesión cerrada';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.deviceLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(fontSize: 13, color: _failed ? BnColors.critico : BnColors.texto3)),
              ],
            ),
          ),
          if (d.active) ...[
            const SizedBox(width: 12),
            BnPressable(
              scale: .98,
              opacity: .88,
              onTap: _busy ? null : _revoke,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _busy ? .5 : 1,
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: BnColors.hairline),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Cerrar sesión', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  @override
  Widget build(BuildContext context) {


    final inset = MediaQuery.paddingOf(context).bottom;
    final nudge = inset > 0 ? (inset + 10 - 34).clamp(0.0, 10.0) : 0.0;
    return Transform.translate(
      offset: Offset(0, nudge),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        label: 'Cerrar sesión',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: const Color(0xF5FBFAF8), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '¿Cerrar sesión en BInova? Para volver a entrar usarás Face ID o tu contraseña.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: BnType.family, fontSize: 13, height: 1.45, color: BnColors.texto2),
                    ),
                  ),
                  BnPressable(
                    scale: .98,
                    opacity: .88,
                    onTap: () => Navigator.of(context).pop(true),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: BnColors.hairline))),
                      child: const Text('Cerrar sesión',
                          style: TextStyle(fontFamily: BnType.family, fontSize: 17, fontWeight: FontWeight.w500, color: BnColors.critico)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            BnPressable(
              scale: .98,
              opacity: .88,
              onTap: () => Navigator.of(context).pop(false),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: BnColors.superficie, borderRadius: BorderRadius.circular(16)),
                child: const Text('Cancelar',
                    style: TextStyle(fontFamily: BnType.family, fontSize: 17, fontWeight: FontWeight.w600, color: BnColors.carbon)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
