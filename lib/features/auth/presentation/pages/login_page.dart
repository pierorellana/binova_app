import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routing/app_router.dart';
import '../../../../core/design_system/binova_widgets.dart';
import '../providers/auth_controller.dart';
import '../widgets/bn_mini_trace.dart';

final _eyeGlyph = bnLine('<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>');
final _eyeOffGlyph = bnLine(
  '<path d="M3 3l18 18"/><path d="M10.6 5.1A10 10 0 0 1 12 5c6.5 0 10 7 10 7a17 17 0 0 1-3.2 4.1"/>'
  '<path d="M6.6 6.6C3.8 8.4 2 12 2 12s3.5 7 10 7a9.7 9.7 0 0 0 5.4-1.6"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>',
);
final _alertGlyph = bnLine('<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5M12 16.5h.01"/>', stroke: 1.9);
final _faceIdGlyph = bnLine(
  '<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2"/>'
  '<path d="M9 9v1.5M15 9v1.5"/><path d="M12 9v4h-1"/><path d="M9.5 16a4 4 0 0 0 5 0"/>',
);
final _lockGlyph = bnLine('<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8 10.5V7.5a4 4 0 0 1 8 0v3"/>', stroke: 1.8);
final _checkGlyph = bnLine('<path d="M5 12.5l4.5 4.5L19 7.5"/>', stroke: 2.2);

TextStyle _text(double size, {FontWeight weight = FontWeight.w400, Color color = BnColors.carbon, double? height, double? spacing}) =>
    TextStyle(fontFamily: BnType.family, fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: spacing);

/// Login (`Login.dc.html`): credentials card, inline error with shake,
/// password recovery sheet and the Face ID entry point.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _showPassword = false;
  String? _validationError;
  // Starts dismissed so a failure from another screen (e.g. Face ID) is not shown here.
  bool _errorDismissed = true;
  int _shake = 0;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _clearError() {
    if (!_errorDismissed || _validationError != null) {
      setState(() {
        _errorDismissed = true;
        _validationError = null;
      });
    }
  }

  void _fail() {
    setState(() => _shake++);
    BnHaptics.error();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    if (auth.isLoading) return;
    FocusScope.of(context).unfocus();
    final username = _username.text.trim();
    final validation = username.isEmpty
        ? 'Ingresa tu usuario o correo.'
        : _password.text.isEmpty
            ? 'Ingresa tu contraseña.'
            : null;
    setState(() {
      _validationError = validation;
      _errorDismissed = false;
    });
    if (validation != null) return _fail();

    await auth.login(username: username, password: _password.text);
    if (!mounted) return;
    if (auth.status == AuthStatus.authenticated) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoute.home, (_) => false);
    } else {
      _fail();
    }
  }

  void _openRecovery() {
    FocusScope.of(context).unfocus();
    showBnSheet<void>(context, builder: (_) => const _RecoverySheet());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final busy = auth.status == AuthStatus.loading;
    final authError = auth.status == AuthStatus.failure ? auth.errorMessage : null;
    final error = _errorDismissed ? null : _validationError ?? authError;
    final hasError = error != null;
    final top = bnTopInset(context);

    return BnScreen(
      resizeToAvoidBottomInset: true,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: bnScrollPhysics,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, top + 40, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: _AppMark()),
                    const SizedBox(height: 28),
                    Semantics(
                      header: true,
                      child: Text('Hola de nuevo', style: _text(32, weight: FontWeight.w600, height: 1.1, spacing: -1.12)),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: _text(16, color: BnColors.texto2, height: 1.45),
                        children: [
                          const TextSpan(text: 'Ingresa a '),
                          TextSpan(text: 'BI', style: _text(16, weight: FontWeight.w600, height: 1.45)),
                          const TextSpan(text: 'nova de forma segura.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    BnShake(
                      trigger: _shake,
                      amplitude: 6,
                      duration: const Duration(milliseconds: 380),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: BnColors.superficie,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: hasError ? BnColors.criticoBorde : BnColors.hairline),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Column(
                            children: [
                              _Field(
                                label: 'Usuario o correo',
                                controller: _username,
                                autofillHints: const [AutofillHints.username],
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) => _clearError(),
                                onSubmitted: (_) => _passwordFocus.requestFocus(),
                              ),
                              const BnDivider(indent: 16),
                              _Field(
                                label: 'Contraseña',
                                labelColor: hasError ? BnColors.critico : BnColors.texto3,
                                controller: _password,
                                focusNode: _passwordFocus,
                                obscure: !_showPassword,
                                letterSpacing: 0.34,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onChanged: (_) => _clearError(),
                                onSubmitted: (_) => _submit(),
                                trailing: BnPressable(
                                  onTap: () => setState(() => _showPassword = !_showPassword),
                                  semanticLabel: _showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
                                  child: SizedBox.square(
                                    dimension: 44,
                                    child: Center(
                                      child: BnSvg(_showPassword ? _eyeOffGlyph : _eyeGlyph, size: 22, color: BnColors.texto2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (hasError) ...[
                      const SizedBox(height: 12),
                      BnRise(
                        key: ValueKey<String>(error),
                        duration: const Duration(milliseconds: 300),
                        offset: 6,
                        child: _ErrorBanner(message: error),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: BnPressable(
                        onTap: _openRecovery,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Center(
                            widthFactor: 1,
                            child: Text('¿Olvidaste tu contraseña?', style: _text(15, weight: FontWeight.w500)),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    _PrimaryButton(
                      busy: busy,
                      busyLabel: 'Verificando…',
                      label: hasError && _validationError == null ? 'Intentar de nuevo' : 'Ingresar',
                      onTap: _submit,
                    ),
                    const SizedBox(height: 12),
                    Opacity(
                      opacity: auth.biometricAvailable ? 1 : 0.4,
                      child: BnButton(
                        label: 'Ingresar con Face ID',
                        variant: BnButtonVariant.secondary,
                        icon: BnSvg(_faceIdGlyph, size: 22, color: BnColors.carbon),
                        onTap: auth.biometricAvailable && !busy
                            ? () => Navigator.of(context).pushReplacementNamed(AppRoute.biometric)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BnSvg(_lockGlyph, size: 14, color: BnColors.texto3),
                        const SizedBox(width: 6),
                        Text('Tus datos viajan cifrados.', style: _text(13, color: BnColors.texto3)),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 52 pt isotipo tile: "BI" over the orange bar.
class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'BInova',
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: BnColors.grafito, borderRadius: BorderRadius.circular(15)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('BI', style: _text(20, weight: FontWeight.w700, color: BnColors.blancoCalido, height: 1, spacing: -0.8)),
              const SizedBox(height: 4),
              Container(
                width: 12,
                height: 2,
                decoration: BoxDecoration(color: BnColors.brandNaranjaBi, borderRadius: BorderRadius.circular(1)),
              ),
            ],
          ),
        ),
      );
}

/// `.field`: 12/500 label over a 17 pt input; `#FBFAF8` while focused.
class _Field extends StatefulWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.labelColor = BnColors.texto3,
    this.focusNode,
    this.obscure = false,
    this.letterSpacing,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final Color labelColor;
  final FocusNode? focusNode;
  final bool obscure;
  final double? letterSpacing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final input = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: _text(12, weight: FontWeight.w500, color: widget.labelColor),
          child: Text(widget.label),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 24,
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: widget.obscure,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            cursorColor: BnColors.carbon,
            textAlignVertical: TextAlignVertical.center,
            style: _text(17, spacing: widget.letterSpacing),
            decoration: const InputDecoration.collapsed(hintText: null),
          ),
        ),
      ],
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focus.requestFocus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: _focus.hasFocus ? BnColors.superficieAlt : BnColors.superficie,
        constraints: const BoxConstraints(minHeight: 64),
        padding: widget.trailing == null
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
            : const EdgeInsets.fromLTRB(16, 0, 8, 0),
        alignment: Alignment.centerLeft,
        child: widget.trailing == null
            ? input
            : Row(children: [Expanded(child: input), const SizedBox(width: 8), widget.trailing!]),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: BnColors.criticoFondo, borderRadius: BorderRadius.circular(14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: BnSvg(_alertGlyph, size: 18, color: BnColors.criticoTexto),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: _text(14, weight: FontWeight.w600, color: BnColors.criticoTexto, height: 1.45)),
              ),
            ],
          ),
        ),
      );
}

/// Primary 54 pt button whose busy state shows the `.mini-trace` loader.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.busy, required this.busyLabel, required this.label, required this.onTap});

  final bool busy;
  final String busyLabel;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: busy ? busyLabel : label,
        excludeSemantics: true,
        child: BnPressable(
          onTap: busy ? null : onTap,
          child: Container(
            height: 54,
            decoration: BoxDecoration(color: BnColors.carbon, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy) ...[const BnMiniTrace(), const SizedBox(width: 10)],
                Text(busy ? busyLabel : label, style: _text(17, weight: FontWeight.w600, color: BnColors.superficie)),
              ],
            ),
          ),
        ),
      );
}

enum _RecoveryStep { form, sending, sent }

/// "Recuperar contraseña" sheet: form → sending (1.1 s) → sent.
class _RecoverySheet extends StatefulWidget {
  const _RecoverySheet();

  @override
  State<_RecoverySheet> createState() => _RecoverySheetState();
}

class _RecoverySheetState extends State<_RecoverySheet> {
  final _email = TextEditingController();
  _RecoveryStep _step = _RecoveryStep.form;
  int _shake = 0;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_step != _RecoveryStep.form) return;
    if (!_email.text.contains('@')) {
      setState(() => _shake++);
      BnHaptics.error();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _step = _RecoveryStep.sending);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (mounted) setState(() => _step = _RecoveryStep.sent);
  }

  @override
  Widget build(BuildContext context) {
    final sent = _step == _RecoveryStep.sent;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BnSheetHeader(title: 'Recuperar contraseña'),
        if (!sent) ...[
          const SizedBox(height: 6),
          Text(
            'Te enviaremos un enlace seguro para crear una nueva contraseña.',
            style: _text(15, color: BnColors.texto2, height: 1.45),
          ),
          const SizedBox(height: 16),
          BnShake(
            trigger: _shake,
            amplitude: 6,
            duration: const Duration(milliseconds: 380),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: BnColors.superficieAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BnColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Correo registrado', style: _text(12, weight: FontWeight.w500, color: BnColors.texto3)),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 24,
                    child: TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      cursorColor: BnColors.carbon,
                      textAlignVertical: TextAlignVertical.center,
                      style: _text(17),
                      decoration: const InputDecoration.collapsed(hintText: null),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _PrimaryButton(
            busy: _step == _RecoveryStep.sending,
            busyLabel: 'Enviando…',
            label: 'Enviar enlace',
            onTap: _send,
          ),
        ] else ...[
          const SizedBox(height: 20),
          BnRise(
            duration: const Duration(milliseconds: 300),
            offset: 6,
            child: Semantics(
              liveRegion: true,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: BnColors.grafito, shape: BoxShape.circle),
                    child: BnSvg(_checkGlyph, size: 26, color: BnColors.superficie),
                  ),
                  const SizedBox(height: 14),
                  Text('Revisa tu correo', style: _text(18, weight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    'El enlace vence en 15 minutos. Si no llega, revisa la carpeta de spam.',
                    textAlign: TextAlign.center,
                    style: _text(15, color: BnColors.texto2, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          BnButton(label: 'Volver al inicio de sesión', onTap: () => Navigator.of(context).maybePop()),
        ],
      ],
    );
  }
}
