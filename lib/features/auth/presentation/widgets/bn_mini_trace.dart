import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_tokens.dart';

/// `.mini-trace`: the in-button loader of the prototype. A 22 % orange dash
/// travels around the isotipo outline (`stroke-dasharray: 22 78`, 1.2 s linear).
class BnMiniTrace extends StatefulWidget {
  const BnMiniTrace({this.size = 20, super.key});

  final double size;

  @override
  State<BnMiniTrace> createState() => _BnMiniTraceState();
}

class _BnMiniTraceState extends State<BnMiniTrace> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(painter: _MiniTracePainter(_c)),
      );
}

class _MiniTracePainter extends CustomPainter {
  _MiniTracePainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(6 * s, 6 * s, 88 * s, 88 * s), Radius.circular(28 * s));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 * s;
    canvas.drawRRect(rrect, stroke..color = const Color(0x40FFFFFF));

    final metric = (Path()..addRRect(rrect)).computeMetrics().first;
    final length = metric.length;
    final start = progress.value * length;
    final end = start + 0.22 * length;
    final dash = metric.extractPath(start, end.clamp(0, length));
    if (end > length) dash.addPath(metric.extractPath(0, end - length), Offset.zero);
    canvas.drawPath(
      dash,
      stroke
        ..color = BnColors.brandNaranjaBi
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniTracePainter old) => false;
}
