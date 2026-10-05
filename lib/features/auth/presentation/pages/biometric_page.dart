import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routing/app_router.dart';
import '../../../../core/design_system/binova_widgets.dart';
import '../providers/auth_controller.dart';
import '../widgets/bn_compact_button.dart';

TextStyle _text(double size, {FontWeight weight = FontWeight.w400, Color color = BnColors.carbon, double? spacing}) =>
    TextStyle(fontFamily: BnType.family, fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing);




class BiometricPage extends StatefulWidget {
  const BiometricPage({super.key});

  @override
  State<BiometricPage> createState() => _BiometricPageState();
}

class _BiometricPageState extends State<BiometricPage> with SingleTickerProviderStateMixin {
  static const _idle = Duration(milliseconds: 450);
  static const _minScan = Duration(milliseconds: 1500);
  static const _successHold = Duration(milliseconds: 1100);



  static const _rejectedMessage = 'No pudimos validar tu identidad.';

  late final AnimationController _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  BnFaceIdState _state = BnFaceIdState.idle;
  String? _errorDetail;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_running || !mounted) return;
    _running = true;
    final auth = context.read<AuthController>();
    setState(() => _state = BnFaceIdState.idle);
    await Future<void>.delayed(_idle);
    if (!mounted) return;
    setState(() => _state = BnFaceIdState.scan);

    final scan = Stopwatch()..start();
    final unlocked = await auth.unlockWithBiometry();
    final remaining = _minScan - scan.elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    if (!mounted) return;
    _running = false;

    if (unlocked) {
      setState(() => _state = BnFaceIdState.ok);
      BnHaptics.success();
      _reveal.duration = Duration(milliseconds: bnReduceMotion(context) ? 200 : 420);
      _reveal.forward();
      await Future<void>.delayed(_successHold);
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil(AppRoute.home, (_) => false);
    } else {
      final message = auth.errorMessage;
      setState(() {
        _state = BnFaceIdState.err;
        _errorDetail = message == null || message == _rejectedMessage ? null : message;
      });
      BnHaptics.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = bnTopInset(context);
    final displayName = context.select<AuthController, String?>((a) => a.session?.user.displayName);
    final hudLabel = switch (_state) {
      BnFaceIdState.ok => 'Face ID: identidad confirmada',
      BnFaceIdState.err => 'Face ID: no reconocido',
      _ => 'Face ID: validando',
    };

    return BnScreen(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _reveal,
            child: _HomeSilhouette(top: top, name: displayName == null ? 'Pierre' : BnFormat.firstName(displayName)),
            builder: (context, child) {
              final t = BnMotion.entrada.transform(_reveal.value);
              final blur = 14 * (1 - t);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Transform.scale(
                    scale: 1.04 - 0.04 * t,
                    child: blur > 0.05
                        ? ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.decal),
                            child: child,
                          )
                        : child,
                  ),
                  IgnorePointer(
                    child: ColoredBox(color: Color.fromRGBO(246, 245, 242, .55 * (1 - Curves.ease.transform(_reveal.value)))),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: top,
            left: 0,
            right: 0,
            height: 44,
            child: Center(
              child: Text.rich(
                TextSpan(
                  style: _text(17, spacing: -0.51),
                  children: [
                    TextSpan(text: 'BI', style: _text(17, weight: FontWeight.w700, spacing: -0.51)),
                    TextSpan(text: 'nova', style: _text(17, color: BnColors.texto2, spacing: -0.51)),
                  ],
                ),
                semanticsLabel: 'BInova',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: hudLabel,
                  image: true,
                  child: ExcludeSemantics(child: BnFaceIdHud(state: _state, size: 156)),
                ),
                const SizedBox(height: 28),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 120),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: _Messages(state: _state, errorDetail: _errorDetail, onRetry: _run),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 52,
            child: Center(
              child: BnPressable(
                onTap: () => Navigator.of(context).pushReplacementNamed(AppRoute.login),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: Text('Usar contraseña', style: _text(15, weight: FontWeight.w500)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Messages extends StatelessWidget {
  const _Messages({required this.state, required this.errorDetail, required this.onRetry});

  final BnFaceIdState state;
  final String? errorDetail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (String group, List<Widget> lines) = switch (state) {
      BnFaceIdState.idle || BnFaceIdState.scan => (
          'wait',
          [
            _msg(Text('Confirma tu identidad para continuar.', textAlign: TextAlign.center, style: _text(17, weight: FontWeight.w600))),
            const SizedBox(height: 6),
            _msg(Text(
              state == BnFaceIdState.scan ? 'Validando identidad…' : 'Mira tu iPhone',
              textAlign: TextAlign.center,
              style: _text(14, color: BnColors.texto2),
            )),
          ],
        ),
      BnFaceIdState.ok => (
          'ok',
          [
            _msg(Text('Identidad confirmada', textAlign: TextAlign.center, style: _text(17, weight: FontWeight.w600))),
            const SizedBox(height: 6),
            _msg(Text('Entrando a tu banca…', textAlign: TextAlign.center, style: _text(14, color: BnColors.texto2))),
          ],
        ),
      BnFaceIdState.err => (
          'err',
          [
            _msg(Text('No pudimos verificar tu identidad.', textAlign: TextAlign.center, style: _text(17, weight: FontWeight.w600))),
            const SizedBox(height: 6),
            _msg(Text(
              errorDetail ?? 'Asegúrate de que tu rostro esté visible.',
              textAlign: TextAlign.center,
              style: _text(14, color: BnColors.texto2),
            )),
            const SizedBox(height: 18),
            _msg(BnCompactButton(label: 'Intentar nuevamente', onTap: onRetry)),
          ],
        ),
    };
    return Semantics(
      liveRegion: true,
      child: Column(
        key: ValueKey<String>(group),
        mainAxisSize: MainAxisSize.min,
        children: lines,
      ),
    );
  }


  static Widget _msg(Widget child) => BnRise(duration: const Duration(milliseconds: 260), offset: 6, child: child);
}



class _HomeSilhouette extends StatelessWidget {
  const _HomeSilhouette({required this.top, required this.name});

  final double top;
  final String name;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, top, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    Container(width: 44, height: 44, decoration: const BoxDecoration(color: BnColors.grafito, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(BnFormat.greeting(), style: _text(13, color: BnColors.texto3)),
                        const SizedBox(height: 4),
                        Text(name, style: _text(18, weight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: BnColors.grafito, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo total', style: _text(14, color: BnColors.texto5)),
                    const SizedBox(height: 14),
                    Container(
                      width: 196,
                      height: 36,
                      decoration: BoxDecoration(color: const Color(0x2EF6F5F2), borderRadius: BorderRadius.circular(10)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: Center(
                        child: Container(width: 56, height: 56, decoration: const BoxDecoration(color: BnColors.superficie, shape: BoxShape.circle)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              Container(height: 146, decoration: BoxDecoration(color: BnColors.superficie, borderRadius: BorderRadius.circular(18))),
              const SizedBox(height: 32),
              Container(height: 156, decoration: BoxDecoration(color: BnColors.superficie, borderRadius: BorderRadius.circular(18))),
            ],
          ),
        ),
      );
}
