import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import 'binova_tokens.dart';
import 'bn_motion.dart';
import 'bn_svg.dart';

enum BnOpPhase { proc, ok, warn, err }

/// Indicador de operación BInova (`.op` in the prototype).
///
/// * proc: the isotipo floats with a ±16° 3D tilt (2.4 s) while an orange
///   line runs along its border (1.6 s).
/// * ok: the square morphs into a circle, BI fades, a check is drawn.
/// * warn: light circle + dotted spinning ring + clock.
/// * err: stays square, shakes once, shows "!".
class BnOperationIndicator extends StatefulWidget {
  const BnOperationIndicator({required this.phase, this.small = false, super.key});

  final BnOpPhase phase;
  final bool small;

  @override
  State<BnOperationIndicator> createState() => _BnOperationIndicatorState();
}

class _BnOperationIndicatorState extends State<BnOperationIndicator> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: BnMotion.loaderInclinacion);
  late final AnimationController _trace = AnimationController(vsync: this, duration: BnMotion.loaderTrazo);
  late final AnimationController _morph = AnimationController(vsync: this, duration: BnMotion.morphResultado);
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 9));
  BnOpPhase _from = BnOpPhase.proc;

  @override
  void initState() {
    super.initState();
    _apply(initial: true);
  }

  @override
  void didUpdateWidget(covariant BnOperationIndicator old) {
    super.didUpdateWidget(old);
    if (old.phase != widget.phase) {
      _from = old.phase;
      _apply();
    }
  }

  void _later(Duration d, VoidCallback f) => Future<void>.delayed(d, () {
        if (mounted) f();
      });

  void _apply({bool initial = false}) {
    final p = widget.phase;
    if (p == BnOpPhase.proc) {
      _loop.repeat();
      _trace.repeat();
      _spin.stop();
      _morph.reverse();
      _draw.value = 0;
      return;
    }
    _loop.stop();
    _trace.stop();
    if (initial) {
      _morph.value = 1;
    } else {
      _morph.forward(from: 0);
    }
    if (p == BnOpPhase.ok) {
      _draw.value = 0;
      _later(const Duration(milliseconds: 120), () => _pop.forward(from: 0));
      _later(const Duration(milliseconds: 300), () => _draw.forward(from: 0));
    }
    if (p == BnOpPhase.warn) _spin.repeat();
    if (p == BnOpPhase.err) _later(const Duration(milliseconds: 160), () => _shake.forward(from: 0));
  }

  @override
  void dispose() {
    for (final c in [_loop, _trace, _morph, _pop, _shake, _draw, _spin]) {
      c.dispose();
    }
    super.dispose();
  }

  // ease-in-out between keyframes 0 → 50% → 100%.
  static double _pingPong(double t) {
    final half = t < .5 ? t * 2 : (1 - t) * 2;
    return Curves.easeInOut.transform(half);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = bnReduceMotion(context);
    return AnimatedScale(
      scale: widget.small ? .62 : 1,
      duration: const Duration(milliseconds: 300),
      curve: BnMotion.entrada,
      child: SizedBox(
        width: 120,
        height: 120,
        child: AnimatedBuilder(
          animation: Listenable.merge([_loop, _trace, _morph, _pop, _shake, _draw, _spin]),
          builder: (context, _) {
            final phase = widget.phase;
            final proc = phase == BnOpPhase.proc;
            final m = BnMotion.cambioEstado.transform(_morph.value);
            final k = reduce ? 0.0 : _pingPong(_loop.value);
            final tiltAmount = proc ? 1.0 : (1 - m);

            // tilt keyframes: 0/100% → (y 0, rx 8°, ry −16°) · 50% → (y −6, rx −4°, ry 16°)
            final ty = lerpDouble(0, -6, k)! * tiltAmount;
            final rx = bnDeg(lerpDouble(8, -4, k)!) * tiltAmount * (reduce ? 0 : 1);
            final ry = bnDeg(lerpDouble(-16, 16, k)!) * tiltAmount * (reduce ? 0 : 1);

            // pop (ok) 0 → 45% 1.06 → 100% 1
            double pop = 1;
            if (_pop.isAnimating || _pop.value > 0) {
              final t = BnMotion.entrada.transform(_pop.value);
              pop = t < .45 ? lerpDouble(1, 1.06, t / .45)! : lerpDouble(1.06, 1, (t - .45) / .55)!;
            }
            final shakeX = _shakeAt(BnMotion.vibracion.transform(_shake.value), 5);

            final circle = phase == BnOpPhase.ok || phase == BnOpPhase.warn;
            final fromCircle = _from == BnOpPhase.ok || _from == BnOpPhase.warn;
            final radiusTarget = circle ? 48.0 : 28.0;
            final radius = proc
                ? lerpDouble(28, fromCircle ? 48 : 28, m)!
                : lerpDouble(28, radiusTarget, m)!;

            // Surface: dark radial gradient → white (warn) / critical tint (err).
            final lightness = phase == BnOpPhase.warn || phase == BnOpPhase.err ? m : 0.0;
            final lightColor = phase == BnOpPhase.err ? BnColors.criticoFondo : BnColors.superficie;
            final lightBorder = phase == BnOpPhase.err ? const Color(0xFFEBC9C5) : BnColors.hairline;

            final shadowK = proc && !reduce ? k : 0.0;

            Widget tile = Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: BnColors.carbon.withOpacity(lerpDouble(.18, .06, lightness)!),
                    blurRadius: lerpDouble(30, 22, lightness)!,
                    offset: Offset(0, lerpDouble(14, 8, lightness)!),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(-.44, -.64),
                          radius: 1.2,
                          colors: [BnColors.grafitoAlto, BnColors.grafito, BnColors.grafitoBajo],
                          stops: [0, .52, 1],
                        ),
                      ),
                    ),
                    // inset 0 1px 0 rgba(255,255,255,.08)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 1,
                      child: ColoredBox(color: Color.fromRGBO(255, 255, 255, .08 * (1 - lightness))),
                    ),
                    if (lightness > 0)
                      Opacity(
                        opacity: lightness,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: lightColor,
                            borderRadius: BorderRadius.circular(radius),
                            border: Border.all(color: lightBorder),
                          ),
                        ),
                      ),
                    // BI + orange bar
                    Center(
                      child: Opacity(
                        opacity: ((1 - m) * (proc && reduce ? .5 + .5 * _pingPong(_trace.value) : 1)).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: proc ? 1 : lerpDouble(1, .6, m)!,
                          child: const _BiMark(),
                        ),
                      ),
                    ),
                    if (phase == BnOpPhase.ok)
                      Center(
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: CustomPaint(
                            painter: BnPathDraw(
                              path: Path()
                                ..moveTo(5.5, 12.5)
                                ..lineTo(9.7, 16.7)
                                ..lineTo(18.5, 8),
                              progress: reduce ? 1 : BnMotion.entrada.transform(_draw.value),
                              color: BnColors.superficie,
                              strokeWidth: 2.4,
                            ),
                          ),
                        ),
                      ),
                    if (phase == BnOpPhase.warn)
                      Center(
                        child: Opacity(
                          opacity: m,
                          child: BnSvg(bnLine('<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>', stroke: 1.9), size: 40, color: BnColors.carbon),
                        ),
                      ),
                    if (phase == BnOpPhase.err)
                      Center(
                        child: Opacity(
                          opacity: m,
                          child: BnSvg(BnGlyphs.exclamation, size: 36, color: BnColors.critico),
                        ),
                      ),
                  ],
                ),
              ),
            );

            // Orange trace runs around the border (rides along with the tilt).
            tile = SizedBox(
              width: 106,
              height: 106,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  tile,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (1 - m).clamp(0.0, 1.0),
                        child: CustomPaint(painter: _TracePainter(progress: _trace.value, reduce: reduce)),
                      ),
                    ),
                  ),
                ],
              ),
            );

            final transform = Matrix4.identity()
              ..setEntry(3, 2, -1 / 700)
              ..translate(shakeX, ty)
              ..rotateX(rx)
              ..rotateY(ry)
              ..scale(pop, pop);

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // floor shadow
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: -16,
                  height: 14,
                  child: Opacity(
                    opacity: proc ? lerpDouble(1, .65, shadowK)! : .6,
                    child: Transform.scale(
                      scaleX: proc ? lerpDouble(1, .8, shadowK)! : 1,
                      child: const CustomPaint(painter: BnFloorShadowPainter()),
                    ),
                  ),
                ),
                Transform(alignment: Alignment.center, transform: transform, child: tile),
                if (phase == BnOpPhase.warn)
                  Positioned.fill(
                    child: Opacity(
                      opacity: m,
                      child: Transform.rotate(
                        angle: _spin.value * 2 * math.pi,
                        child: const CustomPaint(painter: _DottedRingPainter()),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static double _shakeAt(double t, double a) {
    if (t <= 0 || t >= 1) return 0;
    const keys = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0];
    final vals = [0.0, -a, a * 0.8, -a * 0.4, a * 0.2, 0.0];
    for (var i = 0; i < keys.length - 1; i++) {
      if (t <= keys[i + 1]) {
        final local = (t - keys[i]) / (keys[i + 1] - keys[i]);
        return vals[i] + (vals[i + 1] - vals[i]) * local;
      }
    }
    return 0;
  }
}

class _BiMark extends StatelessWidget {
  const _BiMark();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'BI',
            style: TextStyle(
              fontFamily: BnType.family,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.12,
              color: BnColors.blancoCalido,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(color: BnColors.brandNaranjaBi, borderRadius: BorderRadius.circular(2)),
          ),
        ],
      );
}

/// `rect x=1 y=1 w=98 h=98 rx=30 pathLength=100; stroke-dasharray: 16 84`
class _TracePainter extends CustomPainter {
  _TracePainter({required this.progress, required this.reduce});

  final double progress;
  final bool reduce;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100;
    final sy = size.height / 100;
    final rect = Rect.fromLTWH(1 * sx, 1 * sy, 98 * sx, 98 * sy);
    final rrect = RRect.fromRectAndRadius(rect, Radius.elliptical(30 * sx, 30 * sy));
    final paint = Paint()
      ..color = BnColors.brandNaranjaBi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * sx
      ..strokeCap = StrokeCap.round;
    final path = Path()..addRRect(rrect);
    if (reduce) {
      canvas.drawPath(path, paint..color = BnColors.brandNaranjaBi.withOpacity(.45));
      return;
    }
    final metric = path.computeMetrics().first;
    final len = metric.length;
    final dash = len * .16;
    final start = (progress * len) % len;
    final end = start + dash;
    canvas.drawPath(metric.extractPath(start, math.min(end, len)), paint);
    if (end > len) canvas.drawPath(metric.extractPath(0, end - len), paint);
  }

  @override
  bool shouldRepaint(covariant _TracePainter old) => old.progress != progress || old.reduce != reduce;
}

/// `radial-gradient(closest-side, rgba(20,21,24,.22), transparent)`: an
/// ellipse filling the box (a plain RadialGradient would be circular).
class BnFloorShadowPainter extends CustomPainter {
  const BnFloorShadowPainter({this.color = const Color(0x38141518)});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = size.center(Offset.zero);
    final r = size.width / 2;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(1, size.height / size.width);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..shader = RadialGradient(colors: [color, color.withOpacity(0)]).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BnFloorShadowPainter oldDelegate) => oldDelegate.color != color;
}

/// `circle r=57 stroke=#A8A59E 1.5 dasharray 3 7`
class _DottedRingPainter extends CustomPainter {
  const _DottedRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120;
    final paint = Paint()
      ..color = BnColors.texto5
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * s
      ..strokeCap = StrokeCap.round;
    final path = Path()..addOval(Rect.fromCircle(center: Offset(60 * s, 60 * s), radius: 57 * s));
    final metric = path.computeMetrics().first;
    var d = 0.0;
    while (d < metric.length) {
      canvas.drawPath(metric.extractPath(d, math.min(d + 3 * s, metric.length)), paint);
      d += 10 * s;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
