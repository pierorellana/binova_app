import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../../app/routing/app_router.dart';
import '../../../../core/design_system/binova_widgets.dart';
import '../../../../core/security/biometric_authenticator.dart';
import '../../../../core/security/biometric_preference_store.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/profile_controller.dart';
import '../widgets/profile_sheets.dart';
import '../widgets/profile_switch.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _local = ProfileLocalSwitches();
  bool _biometricEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileController>().load();
      _loadBiometricPreference();
    });
  }

  @override
  void dispose() {
    _local.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricPreference() async {
    final enabled = await context.read<BiometricPreferenceStore>().isEnabled();
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<void> _setBiometric(bool value) async {
    setState(() => _biometricEnabled = value);
    await context.read<BiometricPreferenceStore>().setEnabled(value);
  }

  void _open(ProfileSheet sheet) => showProfileSheet(
        context,
        sheet: sheet,
        controller: context.read<ProfileController>(),
        local: _local,
      );

  Future<void> _logout() async {
    final confirmed = await showLogoutSheet(context);
    if (!confirmed || !mounted) return;
    await context.read<AuthController>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoute.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final biometric = context.read<BiometricAuthenticator>();

    final List<Widget> body;
    if (controller.isReady) {
      final user = controller.profile!;
      body = [
        _HeaderCard(
          name: user.displayName,
          subtitle: maskEmail(user.email),
          onTap: () => _open(ProfileSheet.datos),
        ),
        _Group(
          title: 'Cuenta y seguridad',
          rows: [
            _Row(glyph: _Glyphs.id, label: 'Datos personales', onTap: () => _open(ProfileSheet.datos)),
            _Row(
              glyph: _Glyphs.shield,
              label: 'Seguridad',
              subtitle: 'Contraseña y clave de transacciones',
              onTap: () => _open(ProfileSheet.seguridad),
            ),
            _Row(
              glyph: _Glyphs.faceId,
              label: 'Face ID',
              subtitle: biometric.isAvailable ? null : 'No disponible en este dispositivo',
              trailing: ProfileSwitch(
                label: 'Face ID',
                value: biometric.isAvailable && _biometricEnabled,
                trackDuration: const Duration(milliseconds: 260),
                onChanged: biometric.isAvailable ? _setBiometric : null,
              ),
            ),
            _Row(
              glyph: BnGlyphs.phone,
              label: 'Dispositivos',
              value: '${controller.devices.where((d) => d.active).length}',
              onTap: () => _open(ProfileSheet.dispositivos),
            ),
          ],
        ),
        _Group(
          title: 'Aplicación',
          rows: [
            _Row(glyph: BnGlyphs.bell, label: 'Notificaciones', light: true, onTap: () => _open(ProfileSheet.notificaciones)),
            _Row(
              glyph: _Glyphs.sliders,
              label: 'Preferencias',
              value: 'Español',
              light: true,
              onTap: () => _open(ProfileSheet.preferencias),
            ),
          ],
        ),
        _LogoutButton(onTap: _logout),
        const _Footer(),
      ];
    } else if (controller.status == ProfileStatus.failure) {
      body = [
        Padding(
          padding: const EdgeInsets.only(top: 96),
          child: _FailureState(
            message: controller.errorMessage ?? 'No pudimos cargar tu perfil.',
            onRetry: controller.load,
          ),
        ),
      ];
    } else {
      body = const [_ProfileSkeleton()];
    }

    return BnTabScaffold(
      tab: BnTab.profile,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 44),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Semantics(header: true, child: const Text('Perfil', style: BnType.largeTitle)),
              ),
              ...body,
            ],
          ),
        ),
      ],
    );
  }
}

abstract final class _Glyphs {
  static final chevron = BnGlyphs.chevronRight;
  static final id = bnLine(
    '<rect x="3" y="5" width="18" height="14" rx="2.5"/><circle cx="9" cy="11" r="2"/><path d="M6 16c.6-1.5 1.7-2 3-2s2.4.5 3 2M15 10h3M15 13h3"/>',
    stroke: 1.7,
  );
  static final shield = bnLine('<path d="M12 3l7 3v5.5c0 4.5-3 7.8-7 9.5-4-1.7-7-5-7-9.5V6z"/><path d="M9 12l2 2 4-4"/>', stroke: 1.7);
  static final faceId = bnLine(
    '<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2"/>'
    '<path d="M9 9v1.5M15 9v1.5"/><path d="M12 9v4h-1"/><path d="M9.5 16a4 4 0 0 0 5 0"/>',
    stroke: 1.7,
  );
  static final sliders = bnLine('<path d="M4 7h10M18 7h2M4 17h4M12 17h8"/><circle cx="16" cy="7" r="2"/><circle cx="10" cy="17" r="2"/>', stroke: 1.7);
  static final logout = bnLine('<path d="M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3"/><path d="M10 17l-5-5 5-5"/><path d="M5 12h11"/>', stroke: 1.8);
}

/// Profile card (`.press` scale .98 / opacity .88) with the 60 pt avatar.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.name, required this.subtitle, required this.onTap});

  final String name;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: BnPressable(
          scale: .98,
          opacity: .88,
          onTap: onTap,
          semanticLabel: '$name, datos personales',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BnColors.superficie,
              border: Border.all(color: BnColors.hairline),
              borderRadius: BorderRadius.circular(BnRadius.card),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    children: [
                      BnInitialsAvatar(initials: BnFormat.initials(name), size: 60, fontSize: 20),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: BnColors.brandNaranjaBi,
                            shape: BoxShape.circle,
                            border: Border.all(color: BnColors.superficie, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: BnType.family, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.36, color: BnColors.carbon)),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: BnType.family, fontSize: 14, color: BnColors.texto2)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                BnSvg(_Glyphs.chevron, size: 16, color: BnColors.texto5),
              ],
            ),
          ),
        ),
      );
}

/// Grouped list: uppercase 13/600 heading + white card with inset dividers.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Semantics(
                header: true,
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(fontFamily: BnType.family, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.52, color: BnColors.texto2),
                ),
              ),
            ),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: BnColors.superficie,
                border: Border.all(color: BnColors.hairline),
                borderRadius: BorderRadius.circular(BnRadius.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const BnDivider(indent: 60),
                    rows[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.glyph,
    required this.label,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.light = false,
  });

  final String glyph;
  final String label;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// `#EFEDE9` tile with a carbon glyph instead of the grafito tile.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          BnIconTile(
            svg: glyph,
            size: 32,
            iconSize: 17,
            radius: 9,
            background: light ? BnColors.relleno : BnColors.grafito,
            color: light ? BnColors.carbon : BnColors.blancoCalido,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontFamily: BnType.family, fontSize: 16, color: BnColors.carbon)),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(fontFamily: BnType.family, fontSize: 13, color: BnColors.texto3)),
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 12),
            Text(value!, style: const TextStyle(fontFamily: BnType.family, fontSize: 15, color: BnColors.texto3)),
          ],
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: 12),
            BnSvg(_Glyphs.chevron, size: 16, color: BnColors.texto5),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return BnRowPressable(onTap: onTap, semanticLabel: label, child: content);
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: BnColors.superficie,
            border: Border.all(color: BnColors.hairline),
            borderRadius: BorderRadius.circular(BnRadius.card),
          ),
          child: BnRowPressable(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BnSvg(_Glyphs.logout, size: 18, color: BnColors.critico),
                  const SizedBox(width: 8),
                  const Text('Cerrar sesión',
                      style: TextStyle(fontFamily: BnType.family, fontSize: 16, fontWeight: FontWeight.w500, color: BnColors.critico)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: 'BI', style: TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: 'nova 1.0 · Banco Internacional'),
          ]),
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: BnType.family, fontSize: 12, color: BnColors.texto3),
        ),
      );
}

/// `.sk` placeholders shaped like the profile card and the first group.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Cargando tu perfil',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _card(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    BnSkeleton(height: 60, circle: true),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BnSkeleton(width: 140, height: 14, radius: 7),
                        SizedBox(height: 8),
                        BnSkeleton(width: 110, height: 10, radius: 5),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Padding(padding: EdgeInsets.only(left: 16, bottom: 8), child: BnSkeleton(width: 140, height: 10, radius: 5)),
              _card(
                child: Column(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const BnDivider(indent: 60),
                      const SizedBox(
                        height: 56,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(children: [
                            BnSkeleton(width: 32, height: 32, radius: 9),
                            SizedBox(width: 12),
                            BnSkeleton(width: 130, height: 12),
                          ]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: BnColors.superficie,
          border: Border.all(color: BnColors.hairline),
          borderRadius: BorderRadius.circular(BnRadius.card),
        ),
        child: child,
      );
}

/// `Estado-Vacio` style failure with a retry action.
class _FailureState extends StatelessWidget {
  const _FailureState({required this.message, required this.onRetry});

  static final _alert = bnLine('<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5M12 16.5h.01"/>', stroke: 1.5);

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: BnColors.hairline))),
                  Container(
                    margin: const EdgeInsets.all(14),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: BnColors.superficie, border: Border.all(color: BnColors.hairline)),
                  ),
                  BnSvg(_alert, size: 28, color: BnColors.texto2),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: BnType.family, fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: -0.38, color: BnColors.carbon)),
            const SizedBox(height: 8),
            const Text('Revisa tu conexión e inténtalo de nuevo.',
                textAlign: TextAlign.center, style: TextStyle(fontFamily: BnType.family, fontSize: 15, height: 1.45, color: BnColors.texto2)),
            const SizedBox(height: 24),
            BnPressable(
              onTap: onRetry,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BnColors.superficie,
                  border: Border.all(color: BnColors.lineaFuerte),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Reintentar',
                    style: TextStyle(fontFamily: BnType.family, fontSize: 16, fontWeight: FontWeight.w600, color: BnColors.carbon)),
              ),
            ),
          ],
        ),
      );
}
