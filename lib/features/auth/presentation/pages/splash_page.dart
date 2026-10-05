import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/bootstrap/bootstrap_controller.dart';
import '../../../../app/routing/app_router.dart';
import '../../../../core/design_system/binova_widgets.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/bn_compact_button.dart';




class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  static const _totalMs = 2470.0;
  static const _reducedMs = 1300.0;
  static const _exitStartMs = 2250.0;

  late final AnimationController _c = AnimationController(vsync: this);
  BootstrapController? _bootstrap;
  bool _reduce = false;
  bool _started = false;
  bool _holding = false;
  bool _exiting = false;

  double get _total => _reduce ? _reducedMs : _totalMs;
  double get _holdAt => _reduce ? 1 : _exitStartMs / _totalMs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bootstrap ??= context.read<BootstrapController>()..addListener(_maybeExit);
    if (_started) return;
    _started = true;
    _reduce = bnReduceMotion(context);
    _c.duration = Duration(milliseconds: _total.round());
    _c.animateTo(_holdAt).whenCompleteOrCancel(() {
      _holding = true;
      _maybeExit();
    });
  }

  @override
  void dispose() {
    _bootstrap?.removeListener(_maybeExit);
    _c.dispose();
    super.dispose();
  }

  void _maybeExit() {
    if (!mounted || !_holding || _exiting) return;
    final bootstrap = _bootstrap!;
    if (bootstrap.status != BootstrapStatus.ready) return;
    _exiting = true;
    final destination = _routeFor(bootstrap.destination!);
    _c.forward().whenCompleteOrCancel(() {
      if (mounted) Navigator.of(context).pushReplacementNamed(destination);
    });
  }

  String _routeFor(InitialDestination destination) => switch (destination) {
        InitialDestination.onboarding => AppRoute.onboarding,
        InitialDestination.login => AppRoute.login,
        InitialDestination.biometric => AppRoute.biometric,
      };

  @override
  Widget build(BuildContext context) {
    final bootstrap = context.watch<BootstrapController>();
    final failed = bootstrap.status == BootstrapStatus.failure;
    return BnScreen(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => _Choreography(ms: _c.value * _total, reduce: _reduce),
          ),
          if (failed)
            Positioned(
              left: 24,
              right: 24,
              bottom: 104,
              child: _FailureAction(
                message: bootstrap.errorMessage ?? 'No pudimos preparar la aplicación.',
                onRetry: bootstrap.start,
              ),
            ),
        ],
      ),
    );
  }
}


double _seg(double ms, double start, double duration, [Curve curve = Curves.linear]) =>
    curve.transform(((ms - start) / duration).clamp(0.0, 1.0));

class _Choreography extends StatelessWidget {
  const _Choreography({required this.ms, required this.reduce});

  final double ms;
  final bool reduce;

  static const _ink = TextStyle(fontFamily: BnType.family, fontSize: 34, height: 1, letterSpacing: -1.36);

  @override
  Widget build(BuildContext context) {

    final double groupOpacity;
    final double groupScale;
    if (reduce) {
      groupOpacity = _seg(ms, 0, 300, Curves.ease);
      groupScale = 1;
    } else {
      final exit = _seg(ms, 2250, 220, BnMotion.salida);
      groupOpacity = 1 - exit;
      groupScale = 1 - 0.015 * exit;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Semantics(
            label: 'BInova. Tu banco evoluciona contigo.',
            header: true,
            child: ExcludeSemantics(
              child: Opacity(
                opacity: groupOpacity,
                child: Transform.scale(
                  scale: groupScale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 120, child: Center(child: _wordmark(context))),
                      const SizedBox(height: 4),
                      _slogan(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 52,
          child: Opacity(
            opacity: _seg(ms, 700, 400, Curves.ease),
            child: const Text(
              'BANCO INTERNACIONAL',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: BnType.family, fontSize: 11, letterSpacing: 1.76, color: BnColors.texto3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _wordmark(BuildContext context) {
    final ink = reduce ? 1.0 : _seg(ms, 1000, 300, BnMotion.estandar);
    final letterStyle = _ink.copyWith(
      fontWeight: FontWeight.w700,
      color: Color.lerp(BnColors.blancoCalido, BnColors.carbon, ink),
    );
    final bar = reduce ? 1.0 : _seg(ms, 620, 320, BnMotion.entrada);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            if (!reduce) ...[
              Positioned(left: -100, right: -100, top: 68, height: 12, child: Center(child: _shadow())),
              Positioned(left: -100, right: -100, top: -24, height: 84, child: Center(child: _tile())),
            ],
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    _slideIn(Text('B', style: letterStyle), start: 220, from: -14),
                    _slideIn(Text('I', style: letterStyle), start: 300, from: 14),
                  ],
                ),
                const SizedBox(height: 7),
                Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.diagonal3Values(bar, 1, 1),
                  child: Container(
                    width: 18,
                    height: 3,
                    decoration: BoxDecoration(color: BnColors.brandNaranjaBi, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ],
            ),
          ],
        ),
        _nova(context),
      ],
    );
  }


  Widget _slideIn(Widget letter, {required double start, required double from}) {
    if (reduce) return letter;
    final e = _seg(ms, start, 420, BnMotion.entradaExpresiva);
    final blur = 6 * (1 - e);
    Widget child = Transform.translate(offset: Offset(from * (1 - e), 0), child: letter);
    if (blur > 0.05) {
      child = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: child);
    }
    return Opacity(opacity: e, child: child);
  }


  Widget _nova(BuildContext context) {
    final style = _ink.copyWith(fontWeight: FontWeight.w400, color: BnColors.texto2);
    final p = reduce ? 1.0 : _seg(ms, 1050, 460, BnMotion.cambioEstado);
    final painter = TextPainter(
      text: TextSpan(text: 'nova', style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final natural = painter.width;
    painter.dispose();
    return ClipRect(
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: (110 * p / natural).clamp(0.0, 1.0),
        child: Opacity(opacity: p, child: Text('nova', style: style, softWrap: false)),
      ),
    );
  }


  Widget _tile() {
    final enter = _seg(ms, 0, 598, BnMotion.entradaExpresiva);
    final leave = _seg(ms, 1001, 299, BnMotion.estandar);
    final rest = 1 - enter;
    final scale = (0.55 + 0.45 * enter) * (1 + 0.32 * leave);
    final transform = Matrix4.identity()
      ..setEntry(3, 2, -1 / 700)
      ..rotateX(bnDeg(62 * rest))
      ..rotateY(bnDeg(-38 * rest))
      ..scale(scale, scale, 1);
    return Opacity(
      opacity: enter * (1 - leave),
      child: Transform(
        alignment: Alignment.center,
        transform: transform,
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const RadialGradient(
              center: Alignment(-0.44, -0.64),
              radius: 1.2,
              colors: [BnColors.grafitoAlto, BnColors.grafito, BnColors.grafitoBajo],
              stops: [0, 0.52, 1],
            ),
            boxShadow: const [BoxShadow(color: Color(0x33141518), offset: Offset(0, 18), blurRadius: 36)],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x14FFFFFF), Color(0x00FFFFFF)],
              stops: [0, 0.03],
            ),
          ),
        ),
      ),
    );
  }



  Widget _shadow() {
    final enter = _seg(ms, 0, 598, Curves.ease);
    final leave = _seg(ms, 1001, 299, Curves.ease);
    return Opacity(
      opacity: enter * (1 - leave),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(70 / 12 * (0.4 + 0.6 * enter), 1, 1),
        child: const SizedBox.square(
          dimension: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color(0x33141518), Color(0x00141518)]),
            ),
          ),
        ),
      ),
    );
  }


  Widget _slogan() {
    final double opacity;
    final double dy;
    if (reduce) {
      opacity = _seg(ms, 200, 300, Curves.ease);
      dy = 0;
    } else {
      final enter = _seg(ms, 1400, 270, Curves.ease);
      opacity = enter * (1 - _seg(ms, 2102, 198, Curves.ease));
      dy = 6 * (1 - enter);
    }
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, dy),
        child: const Text(
          'Tu banco evoluciona contigo.',
          style: TextStyle(fontFamily: BnType.family, fontSize: 15, letterSpacing: -0.15, color: BnColors.texto2),
        ),
      ),
    );
  }
}

class _FailureAction extends StatelessWidget {
  const _FailureAction({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => BnRise(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: BnType.family, fontSize: 15, height: 1.45, color: BnColors.texto2),
            ),
            const SizedBox(height: 16),
            BnCompactButton(label: 'Reintentar', onTap: onRetry),
          ],
        ),
      );
}
