import 'package:flutter/widgets.dart';




class BnBalancedText extends StatelessWidget {
  const BnBalancedText(this.text, {required this.style, this.textAlign = TextAlign.start, super.key});

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final max = constraints.maxWidth;
      if (!max.isFinite) return Text(text, style: style, textAlign: textAlign);

      TextPainter layout(double width) => TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: direction,
            textScaler: scaler,
          )..layout(maxWidth: width);

      final full = layout(max);
      final lines = full.computeLineMetrics().length;
      full.dispose();
      var width = max;
      if (lines > 1) {
        var lo = 0.0, hi = max;
        while (hi - lo > 1) {
          final mid = (lo + hi) / 2;
          final p = layout(mid);
          final fits = p.computeLineMetrics().length <= lines && !p.didExceedMaxLines && p.width <= mid + .5;
          p.dispose();
          if (fits) {
            hi = mid;
          } else {
            lo = mid;
          }
        }
        width = hi.ceilToDouble();
      }
      final aligned = switch (textAlign) {
        TextAlign.center => Alignment.topCenter,
        TextAlign.right || TextAlign.end => Alignment.topRight,
        _ => Alignment.topLeft,
      };
      return Align(
        alignment: aligned,
        child: SizedBox(width: width, child: Text(text, style: style, textAlign: textAlign)),
      );
    });
  }
}
