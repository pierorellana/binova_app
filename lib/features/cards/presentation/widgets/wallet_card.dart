import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';
import 'card_faces.dart';
import 'card_skin.dart';

final _lock = bnLine(
  '<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8 10.5V7.5a4 4 0 0 1 8 0v3"/>',
  stroke: 1.9,
);

const _sideShadow = [
  BoxShadow(color: Color(0x29141518), offset: Offset(0, 18), blurRadius: 40),
  BoxShadow(color: Color(0x14141518), offset: Offset(0, 2), blurRadius: 6),
];




class WalletCard extends StatefulWidget {
  const WalletCard({
    required this.visual,
    required this.semanticLabel,
    this.building = false,
    this.arc = false,
    this.failing = false,
    this.frozen = false,
    this.shade = 0,
    this.tiltEnabled = false,
    this.flipped = false,
    this.onTap,
    this.onSwipe,
    super.key,
  });

  final CardVisual visual;
  final String semanticLabel;
  final bool building;
  final bool arc;
  final bool failing;
  final bool frozen;
  final double shade;


  final bool tiltEnabled;
  final bool flipped;


  final VoidCallback? onTap;


  final ValueChanged<int>? onSwipe;

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> with TickerProviderStateMixin {
  late final AnimationController _build =
      AnimationController(vsync: this, duration: Duration(milliseconds: CardBuildTimeline.total.round()));
  late final AnimationController _arc = AnimationController(vsync: this, duration: BnMotion.tarjetaAlApilar);

  late final AnimationController _fail = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  Offset _tilt = Offset.zero;
  Offset? _downAt;

  @override
  void initState() {
    super.initState();
    if (widget.building) _build.forward();
    if (widget.arc) _arc.forward();
    if (widget.failing) _fail.forward();
  }

  @override
  void didUpdateWidget(covariant WalletCard old) {
    super.didUpdateWidget(old);
    if (widget.building && !old.building) _build.forward(from: 0);
    if (widget.arc && !old.arc) _arc.forward(from: 0);
    if (widget.failing && !old.failing) _fail.forward(from: 0);
    if (!widget.tiltEnabled) _tilt = Offset.zero;
  }

  @override
  void dispose() {
    _build.dispose();
    _arc.dispose();
    _fail.dispose();
    super.dispose();
  }

  void _track(Offset local, Size size) {
    if (!widget.tiltEnabled) return;
    setState(() => _tilt = Offset(
          ((local.dx / size.width - .5) * 2).clamp(-1.0, 1.0),
          ((local.dy / size.height - .5) * 2).clamp(-1.0, 1.0),
        ));
  }

  void _release(Offset? position) {
    final down = _downAt;
    _downAt = null;
    if (_tilt != Offset.zero) setState(() => _tilt = Offset.zero);
    if (down == null || position == null || widget.onSwipe == null) return;
    final dx = position.dx - down.dx;
    if (dx.abs() > 50) widget.onSwipe!(dx < 0 ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = bnReduceMotion(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_build, _arc, _fail]),
      builder: (context, _) {
        final buildMs = widget.building ? _build.value * CardBuildTimeline.total : null;
        var opacity = 1.0;
        final lift = Matrix4.identity()..setEntry(3, 2, -1 / 1200);

        if (reduce) {

          if (widget.building) opacity *= (buildMs! / 200).clamp(0.0, 1.0);
          if (_arc.isAnimating) opacity *= (_arc.value * 720 / 200).clamp(0.0, 1.0);
        } else {
          if (buildMs != null) {

            final e = CardBuildTimeline.seg(buildMs, 0, 620, BnMotion.entradaExpresiva);
            opacity *= e;
            lift
              ..translate(0.0, 40 * (1 - e))
              ..rotateX(bnDeg(26 * (1 - e)))
              ..scale(lerpDouble(.9, 1, e)!);
          }
          if (_arc.value > 0 && _arc.value < 1) {

            final v = _arc.value;
            final p = v < .4 ? BnMotion.entrada.transform(v / .4) : 1 - BnMotion.entrada.transform((v - .4) / .6);
            lift
              ..rotateX(bnDeg(16 * p))
              ..translate(0.0, 0.0, 18 * p);
          }
          if (widget.failing) {
            final (dx, dy, s, o) = _failPose(_fail.value * 900);
            opacity *= o;
            lift
              ..translate(dx, dy)
              ..scale(s);
          }
        }

        final layers = Stack(
          fit: StackFit.expand,
          children: [
            _TiltFlip(
              visual: widget.visual,
              tilt: widget.tiltEnabled ? _tilt : Offset.zero,
              glareOn: widget.tiltEnabled,
              flipped: widget.tiltEnabled && widget.flipped,
              buildMs: reduce ? null : buildMs,
              reduce: reduce,
            ),
            _Outline(ms: !reduce && buildMs != null && buildMs < 1100 ? buildMs : null),
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: widget.frozen ? 1 : 0,
                duration: const Duration(milliseconds: 360),
                curve: Curves.ease,
                child: const _Frost(),
              ),
            ),
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: widget.shade,
                duration: reduce ? Duration.zero : BnMotion.tarjetaAlApilar,
                curve: Curves.ease,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: BnColors.grafitoBajo,
                    borderRadius: BorderRadius.all(Radius.circular(BnRadius.tarjetaBancaria)),
                  ),
                ),
              ),
            ),
            _hitArea(),
          ],
        );

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform(alignment: Alignment.center, transform: lift, child: layers),
        );
      },
    );
  }

  Widget _hitArea() => LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          final enabled = widget.onTap != null;
          return Semantics(
            button: enabled,
            enabled: enabled,
            label: widget.semanticLabel,
            child: Listener(
              onPointerDown: (e) {
                if (!widget.tiltEnabled) return;
                _downAt = e.position;
                _track(e.localPosition, size);
              },
              onPointerMove: (e) => _track(e.localPosition, size),
              onPointerUp: (e) => _release(e.position),
              onPointerCancel: (_) => _release(null),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
              ),
            ),
          );
        },
      );



  static (double, double, double, double) _failPose(double ms) {
    final v = ((ms - 200) / 700).clamp(0.0, 1.0);
    const stops = [0.0, .2, .4, .6, 1.0];
    const xs = [0.0, -6.0, 5.0, -2.0, 0.0];
    const ys = [0.0, 0.0, 0.0, 0.0, 24.0];
    const ss = [1.0, 1.0, 1.0, 1.0, .94];
    const os = [1.0, 1.0, 1.0, 1.0, 0.0];
    var i = 0;
    while (i < stops.length - 2 && v > stops[i + 1]) {
      i++;
    }
    final local = BnMotion.salida.transform(((v - stops[i]) / (stops[i + 1] - stops[i])).clamp(0.0, 1.0));
    double at(List<double> l) => lerpDouble(l[i], l[i + 1], local)!;
    return (at(xs), at(ys), at(ss), at(os));
  }
}


class _TiltFlip extends StatelessWidget {
  const _TiltFlip({
    required this.visual,
    required this.tilt,
    required this.glareOn,
    required this.flipped,
    required this.buildMs,
    required this.reduce,
  });

  final CardVisual visual;
  final Offset tilt;
  final bool glareOn;
  final bool flipped;
  final double? buildMs;
  final bool reduce;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<_TiltValue>(
        tween: _TiltTween(end: _TiltValue(tilt.dx, tilt.dy, glareOn ? 1 : 0)),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        builder: (context, tv, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: flipped ? math.pi : 0),
          duration: reduce ? Duration.zero : const Duration(milliseconds: 640),
          curve: BnMotion.cambioEstado,
          builder: (context, flip, _) {
            final rx = bnDeg(-tv.ty * 7);
            final ry = bnDeg(tv.tx * 9);
            final showBack = math.cos(flip + ry) < 0;
            final glareCenter = Offset(
              lerpDouble(.2, .5 + tv.tx * .4, tv.on)!,
              lerpDouble(0, .3 + tv.ty * .4, tv.on)!,
            );
            final face = showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: _Side(child: CardBack(visual: visual)),
                  )
                : _Side(
                    child: CardFront(
                      visual: visual,
                      glareCenter: glareCenter,
                      glareAlpha: lerpDouble(.08, .16, tv.on)!,
                      buildMs: buildMs,
                    ),
                  );
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateX(rx)
                ..rotateY(ry + flip),
              child: face,
            );
          },
        ),
      );
}

class _TiltValue {
  const _TiltValue(this.tx, this.ty, this.on);

  final double tx;
  final double ty;
  final double on;
}

class _TiltTween extends Tween<_TiltValue> {
  _TiltTween({super.end});

  @override
  _TiltValue lerp(double t) {
    final a = begin ?? end!;
    final b = end!;
    return _TiltValue(
      lerpDouble(a.tx, b.tx, t)!,
      lerpDouble(a.ty, b.ty, t)!,
      lerpDouble(a.on, b.on, t)!,
    );
  }
}


class _Side extends StatelessWidget {
  const _Side({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(BnRadius.tarjetaBancaria)),
          boxShadow: _sideShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BnRadius.tarjetaBancaria),
          child: child,
        ),
      );
}


class _Frost extends StatelessWidget {
  const _Frost();

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(BnRadius.tarjetaBancaria),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
          child: Container(
            color: const Color(0x6BF6F5F2),
            padding: const EdgeInsets.all(14),
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: BnColors.superficie,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x1F141518), offset: Offset(0, 2), blurRadius: 8)],
              ),
              child: BnSvg(_lock, size: 18, color: BnColors.carbon),
            ),
          ),
        ),
      );
}


class _Outline extends StatelessWidget {
  const _Outline({required this.ms});


  final double? ms;

  @override
  Widget build(BuildContext context) {
    final ms = this.ms;
    if (ms == null) return const SizedBox.shrink();
    final fade = ms <= 770 ? 1.0 : 1 - Curves.ease.transform(((ms - 770) / 330).clamp(0.0, 1.0));
    return IgnorePointer(
      child: Opacity(
        opacity: fade,
        child: CustomPaint(
          painter: _OutlinePainter(CardBuildTimeline.seg(ms, 60, 520, BnMotion.cambioEstado)),
        ),
      ),
    );
  }
}

class _OutlinePainter extends CustomPainter {
  const _OutlinePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    const i = .75;
    const r = 20.0;
    final w = size.width - i;
    final h = size.height - i;
    final path = Path()
      ..moveTo(i + r, i)
      ..lineTo(w - r, i)
      ..arcToPoint(Offset(w, i + r), radius: const Radius.circular(r))
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
      ..lineTo(i + r, h)
      ..arcToPoint(Offset(i, h - r), radius: const Radius.circular(r))
      ..lineTo(i, i + r)
      ..arcToPoint(const Offset(i + r, i), radius: const Radius.circular(r));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = BnColors.carbon;
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (s, m) => s + m.length);
    var remaining = total * progress;
    for (final m in metrics) {
      if (remaining <= 0) break;
      canvas.drawPath(m.extractPath(0, math.min(remaining, m.length)), paint);
      remaining -= m.length;
    }
  }

  @override
  bool shouldRepaint(covariant _OutlinePainter old) => old.progress != progress;
}
