import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_tokens.dart';
import '../../../../core/design_system/bn_motion.dart';

enum StepDirection { fwd, back }

/// Plays a one-shot entrance when mounted. Give it a new key to replay.
/// Reduce Motion turns every variant into a 200 ms fade.
abstract class OperationEntrance extends StatefulWidget {
  const OperationEntrance({required this.child, super.key});

  final Widget child;
  Duration get duration;
  Curve get curve;
  Widget transform(BuildContext context, double t, Widget child);

  @override
  State<OperationEntrance> createState() => _OneShotState();
}

class _OneShotState extends State<OperationEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (bnReduceMotion(context)) _c.duration = const Duration(milliseconds: 200);
    if (!_c.isAnimating && _c.value == 0) _c.forward();
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
        if (reduce) return Opacity(opacity: Curves.ease.transform(_c.value), child: child);
        return widget.transform(context, widget.curve.transform(_c.value), child!);
      },
    );
  }
}

/// `.fwd` / `.back`: hierarchical step push, slide 28 px + fade, 280 ms.
class OperationStepIn extends OperationEntrance {
  const OperationStepIn({required this.direction, required super.child, super.key});

  final StepDirection direction;

  @override
  Duration get duration => BnMotion.pushNavegacion;

  @override
  Curve get curve => BnMotion.entrada;

  @override
  Widget transform(BuildContext context, double t, Widget child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset((direction == StepDirection.fwd ? 28 : -28) * (1 - t), 0),
          child: child,
        ),
      );
}

/// `.fade`: 300 ms ease fade-in.
class OperationFadeIn extends OperationEntrance {
  const OperationFadeIn({required super.child, super.key});

  @override
  Duration get duration => const Duration(milliseconds: 300);

  @override
  Curve get curve => Curves.ease;

  @override
  Widget transform(BuildContext context, double t, Widget child) => Opacity(opacity: t.clamp(0.0, 1.0), child: child);
}

/// `.pa` / `.pb`: the last typed digit rises 10 px from 90 % scale (180 ms).
class DigitPop extends OperationEntrance {
  const DigitPop({required super.child, super.key});

  @override
  Duration get duration => const Duration(milliseconds: 180);

  @override
  Curve get curve => BnMotion.entrada;

  @override
  Widget transform(BuildContext context, double t, Widget child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - t)),
          child: Transform.scale(scale: .9 + .1 * t, child: child),
        ),
      );
}

/// `.nudge`: 320 ms horizontal shake (−5, 4, −2) whenever [trigger] changes.
class OperationNudge extends StatefulWidget {
  const OperationNudge({required this.trigger, required this.child, super.key});

  final int trigger;
  final Widget child;

  @override
  State<OperationNudge> createState() => _OperationNudgeState();
}

class _OperationNudgeState extends State<OperationNudge> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));

  @override
  void didUpdateWidget(covariant OperationNudge old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !bnReduceMotion(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _at(double t) {
    const keys = [0.0, .25, .5, .75, 1.0];
    const vals = [0.0, -5.0, 4.0, -2.0, 0.0];
    for (var i = 0; i < keys.length - 1; i++) {
      if (t <= keys[i + 1]) {
        return vals[i] + (vals[i + 1] - vals[i]) * ((t - keys[i]) / (keys[i + 1] - keys[i]));
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(_at(BnMotion.vibracion.transform(_c.value)), 0),
          child: child,
        ),
      );
}

/// `.key` / `.chip` press: background + scale transition while held.
class PressScale extends StatefulWidget {
  const PressScale({
    required this.builder,
    required this.onTap,
    this.scale = .94,
    this.duration = const Duration(milliseconds: 120),
    this.semanticLabel,
    this.selected,
    super.key,
  });

  final Widget Function(BuildContext context, bool pressed) builder;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  final String? semanticLabel;
  final bool? selected;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: widget.selected,
        label: widget.semanticLabel,
        excludeSemantics: widget.semanticLabel != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _down ? widget.scale : 1,
            duration: widget.duration,
            curve: Curves.ease,
            child: widget.builder(context, _down),
          ),
        ),
      );
}

/// Rise helper for staggered `.st` children (keeps call sites short).
Widget rise(Widget child, [int delayMs = 0]) => BnRise(delay: Duration(milliseconds: delayMs), child: child);
