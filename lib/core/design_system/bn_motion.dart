import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'binova_tokens.dart';



bool bnReduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

abstract final class BnHaptics {
  static void tap() => HapticFeedback.selectionClick();
  static void light() => HapticFeedback.lightImpact();
  static void success() => HapticFeedback.mediumImpact();
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 72));
    await HapticFeedback.heavyImpact();
  }
}


class BnPressable extends StatefulWidget {
  const BnPressable({
    required this.child,
    this.onTap,
    this.scale = BnMotion.pressScale,
    this.opacity = 0.86,
    this.duration = BnMotion.press,
    this.haptic = false,
    this.semanticLabel,
    this.button = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final double opacity;
  final Duration duration;
  final bool haptic;
  final String? semanticLabel;
  final bool button;

  @override
  State<BnPressable> createState() => _BnPressableState();
}

class _BnPressableState extends State<BnPressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    Widget child = AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: widget.duration,
      curve: BnMotion.entrada,
      child: AnimatedOpacity(
        opacity: _down ? widget.opacity : 1,
        duration: widget.duration,
        child: widget.child,
      ),
    );
    child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) BnHaptics.tap();
              widget.onTap!();
            }
          : null,
      child: child,
    );
    return Semantics(
      button: widget.button && enabled,
      enabled: enabled,
      label: widget.semanticLabel,
      child: child,
    );
  }
}


class BnRowPressable extends StatefulWidget {
  const BnRowPressable({
    required this.child,
    this.onTap,
    this.color = const Color(0x00FFFFFF),
    this.pressedColor = BnColors.rowPressed,
    this.borderRadius,
    this.pressScale = 1,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color pressedColor;
  final BorderRadius? borderRadius;
  final double pressScale;
  final String? semanticLabel;

  @override
  State<BnRowPressable> createState() => _BnRowPressableState();
}

class _BnRowPressableState extends State<BnRowPressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.pressScale : 1,
          duration: BnMotion.press,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _down ? widget.pressedColor : widget.color,
              borderRadius: widget.borderRadius,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}



class BnRise extends StatefulWidget {
  const BnRise({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 340),
    this.offset = 8,
    this.curve = BnMotion.entrada,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;
  final Curve curve;

  @override
  State<BnRise> createState() => _BnRiseState();
}

class _BnRiseState extends State<BnRise> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = bnReduceMotion(context);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = widget.curve.transform(_c.value);
        return Opacity(
          opacity: _c.value.clamp(0.0, 1.0) == 0 ? 0 : t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, reduce ? 0 : widget.offset * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}



class BnShake extends StatefulWidget {
  const BnShake({
    required this.child,
    required this.trigger,
    this.amplitude = 5,
    this.duration = const Duration(milliseconds: 420),
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final int trigger;
  final double amplitude;
  final Duration duration;
  final Duration delay;

  @override
  State<BnShake> createState() => _BnShakeState();
}

class _BnShakeState extends State<BnShake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void didUpdateWidget(covariant BnShake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double shakeAt(double t, double a) {
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final t = BnMotion.vibracion.transform(_c.value);
          return Transform.translate(offset: Offset(shakeAt(t, widget.amplitude), 0), child: child);
        },
      );
}


class BnCountUp extends StatefulWidget {
  const BnCountUp({
    required this.value,
    required this.builder,
    this.duration = BnMotion.conteoMonto,
    this.delay = const Duration(milliseconds: 120),
    super.key,
  });

  final double value;
  final Widget Function(BuildContext context, double value) builder;
  final Duration duration;
  final Duration delay;

  @override
  State<BnCountUp> createState() => _BnCountUpState();
}

class _BnCountUpState extends State<BnCountUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  double _from = 0;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void didUpdateWidget(covariant BnCountUp old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = _current;
      _c.forward(from: 0);
    }
  }

  double get _current {
    final t = Curves.easeOutCubic.transform(_c.value);
    return _from + (widget.value - _from) * t;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (bnReduceMotion(context)) return widget.builder(context, widget.value);
    return AnimatedBuilder(animation: _c, builder: (context, _) => widget.builder(context, _current));
  }
}


class BnSkeleton extends StatefulWidget {
  const BnSkeleton({this.width, this.height = 12, this.radius = 6, this.circle = false, super.key});

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  State<BnSkeleton> createState() => _BnSkeletonState();
}

class _BnSkeletonState extends State<BnSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = bnReduceMotion(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final p = reduce ? 0.5 : Curves.easeInOut.transform(_c.value);

        final pos = 1.2 - 1.4 * p;
        return Container(
          width: widget.circle ? widget.height : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.circle ? null : BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              colors: const [BnColors.skeleton, BnColors.skeleton, BnColors.skeletonHighlight, BnColors.skeleton, BnColors.skeleton],
              stops: const [0, .4, .5, .6, 1],
              transform: _ShimmerTransform(pos),
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerTransform extends GradientTransform {
  const _ShimmerTransform(this.position);

  final double position;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final w = bounds.width;
    final offset = (w - 3 * w) * position;

    return Matrix4.identity()
      ..translate(bounds.left + offset, 0.0)
      ..scale(3.0, 1.0, 1.0)
      ..translate(-bounds.left, 0.0);
  }
}


class BnPathDraw extends CustomPainter {
  BnPathDraw({required this.path, required this.progress, required this.color, required this.strokeWidth, this.viewBox = 24});

  final Path path;
  final double progress;
  final Color color;
  final double strokeWidth;
  final double viewBox;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final s = size.width / viewBox;
    canvas.scale(s);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress.clamp(0, 1)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant BnPathDraw oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}

double bnDeg(double degrees) => degrees * math.pi / 180;
