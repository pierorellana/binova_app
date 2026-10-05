import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'binova_tokens.dart';
import 'bn_motion.dart';
import 'bn_svg.dart';

enum BnFaceIdState { idle, scan, ok, err }

/// HUD Face ID BInova: light glass, not the system's black card.
/// Shared by the unlock screen (156 px), operations and card creation (148 px).
class BnFaceIdHud extends StatefulWidget {
  const BnFaceIdHud({required this.state, this.size = 148, this.label = 'Face ID', super.key});

  final BnFaceIdState state;
  final double size;
  final String label;

  @override
  State<BnFaceIdHud> createState() => _BnFaceIdHudState();
}

class _BnFaceIdHudState extends State<BnFaceIdHud> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 340))..forward();
  late final AnimationController _breathe = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _sweep = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _okFade = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _check = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _err = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateWidget(covariant BnFaceIdHud old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) _apply();
  }

  void _later(int ms, VoidCallback f) => Future<void>.delayed(Duration(milliseconds: ms), () {
        if (mounted) f();
      });

  void _apply() {
    switch (widget.state) {
      case BnFaceIdState.idle:
        _breathe.stop();
        _sweep.stop();
        _okFade.value = 0;
        _ring.value = 0;
        _check.value = 0;
        _err.reverse();
      case BnFaceIdState.scan:
        _err.reverse();
        _okFade.value = 0;
        _breathe.repeat(reverse: true);
        _sweep.repeat(reverse: true);
      case BnFaceIdState.ok:
        _breathe.stop();
        _sweep.stop();
        _okFade.forward(from: 0);
        _pop.forward(from: 0);
        _later(120, () => _ring.forward(from: 0));
        _later(400, () => _check.forward(from: 0));
      case BnFaceIdState.err:
        _breathe.stop();
        _sweep.stop();
        _err.forward();
        _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    for (final c in [_in, _breathe, _sweep, _okFade, _ring, _check, _pop, _shake, _err]) {
      c.dispose();
    }
    super.dispose();
  }

  static const _corners = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none" stroke="#141518" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M6 18V12a6 6 0 0 1 6-6h6M46 6h6a6 6 0 0 1 6 6v6M58 46v6a6 6 0 0 1-6 6h-6M18 58h-6a6 6 0 0 1-6-6v-6"/></svg>';
  static const _face = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none" stroke="#141518" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M23 24v4M41 24v4"/><path d="M32 24v10h-3"/></svg>';
  static const _smile = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none" stroke="#141518" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M24.5 42a11 11 0 0 0 15 0"/></svg>';
  static const _flat = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" fill="none" stroke="#141518" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M25 43h14"/></svg>';

  @override
  Widget build(BuildContext context) {
    final reduce = bnReduceMotion(context);
    final big = widget.size >= 156;
    return AnimatedBuilder(
      animation: Listenable.merge([_in, _breathe, _sweep, _okFade, _ring, _check, _pop, _shake, _err]),
      builder: (context, _) {
        final scanning = widget.state == BnFaceIdState.scan;
        final inT = BnMotion.entradaExpresiva.transform(_in.value);
        double scale = lerpDouble(.86, 1, inT)!;
        if (_pop.value > 0 && _pop.value < 1) {
          final t = BnMotion.entrada.transform(_pop.value);
          scale *= t < .4 ? lerpDouble(1, 1.05, t / .4)! : lerpDouble(1.05, 1, (t - .4) / .6)!;
        }
        final shakeX = _shakeAt(BnMotion.vibracion.transform(_shake.value), 6);
        final ok = BnMotion.entrada.transform(_okFade.value);
        final breathe = scanning && !reduce ? lerpDouble(1, .92, Curves.easeInOut.transform(_breathe.value))! : 1.0;
        final sweepY = reduce ? 17.0 : 34 * BnMotion.cambioEstado.transform(_sweep.value);

        final glyph = SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: 1 - ok,
                child: Transform.scale(scale: breathe * lerpDouble(1, .6, ok)!, child: const BnSvg(_corners, size: 64)),
              ),
              Opacity(
                opacity: 1 - ok,
                child: Transform.scale(
                  scale: lerpDouble(1, .7, ok)!,
                  child: Stack(children: [
                    const BnSvg(_face, size: 64),
                    Opacity(opacity: 1 - _err.value, child: const BnSvg(_smile, size: 64)),
                    Opacity(opacity: _err.value, child: const BnSvg(_flat, size: 64)),
                  ]),
                ),
              ),
              if (scanning)
                Positioned(
                  left: 12,
                  top: 15 + sweepY - 1,
                  child: Container(
                    width: 40,
                    height: 2,
                    decoration: BoxDecoration(color: BnColors.brandNaranjaBi.withOpacity(reduce ? .6 : 1), borderRadius: BorderRadius.circular(1)),
                  ),
                ),
              if (widget.state == BnFaceIdState.ok)
                Positioned.fill(
                  child: CustomPaint(
                    painter: BnPathDraw(
                      viewBox: 64,
                      path: Path()..addArc(Rect.fromCircle(center: const Offset(32, 32), radius: 26), -1.5708, 6.2831),
                      progress: reduce ? 1 : BnMotion.entrada.transform(_ring.value),
                      color: BnColors.carbon,
                      strokeWidth: 2.4,
                    ),
                  ),
                ),
              if (widget.state == BnFaceIdState.ok)
                Positioned.fill(
                  child: CustomPaint(
                    painter: BnPathDraw(
                      viewBox: 64,
                      path: Path()
                        ..moveTo(21, 32.5)
                        ..lineTo(28.5, 40)
                        ..lineTo(44, 24.5),
                      progress: reduce ? 1 : BnMotion.entrada.transform(_check.value),
                      color: BnColors.carbon,
                      strokeWidth: 3,
                    ),
                  ),
                ),
            ],
          ),
        );

        return Opacity(
          opacity: inT.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(shakeX, 0),
            child: Transform.scale(
              scale: reduce ? 1 : scale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(big ? 36 : 34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(251, 250, 248, big ? .78 : .84),
                      borderRadius: BorderRadius.circular(big ? 36 : 34),
                      border: Border.all(color: const Color(0x0F141518)),
                      boxShadow: const [BoxShadow(color: Color(0x24141518), blurRadius: 50, offset: Offset(0, 20))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        glyph,
                        SizedBox(height: big ? 12 : 10),
                        Text(
                          widget.label,
                          style: const TextStyle(fontFamily: BnType.family, fontSize: 14, fontWeight: FontWeight.w600, color: BnColors.carbon),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static double _shakeAt(double t, double a) {
    if (t <= 0 || t >= 1) return 0;
    const keys = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0];
    final vals = [0.0, -a, a * (5 / 6), -a * .5, a / 3, 0.0];
    for (var i = 0; i < keys.length - 1; i++) {
      if (t <= keys[i + 1]) {
        final local = (t - keys[i]) / (keys[i + 1] - keys[i]);
        return vals[i] + (vals[i + 1] - vals[i]) * local;
      }
    }
    return 0;
  }
}

/// Small Face ID glyph (used on buttons such as "Confirmar con Face ID").
class BnFaceIdGlyph extends StatelessWidget {
  const BnFaceIdGlyph({this.size = 20, this.color, super.key});

  final double size;
  final Color? color;

  static final svg = bnLine(
    '<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2"/><path d="M9 9v1.5M15 9v1.5"/><path d="M12 9v4h-1"/><path d="M9.5 16a4 4 0 0 0 5 0"/>',
  );

  @override
  Widget build(BuildContext context) => BnSvg(svg, size: size, color: color);
}
