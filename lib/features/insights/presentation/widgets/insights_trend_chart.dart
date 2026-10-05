import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';

/// One column of the monthly spending chart.
class InsightsTrendPoint {
  const InsightsTrendPoint({required this.label, required this.value, required this.current});

  final String label;
  final double value;
  final bool current;
}

/// `section[aria-label="Tendencia de gastos por mes"]`: white card, 150 pt
/// tall six-column grid (gap 14) with bars that grow from the bottom
/// (`grow 520ms cubic-bezier(.2,.8,.2,1)`). Columns keep the 1/6 width of the
/// prototype grid and align to the end, so the current month sits on the right.
class InsightsTrendChart extends StatelessWidget {
  const InsightsTrendChart({required this.points, required this.symbol, super.key});

  static const _columns = 6;
  static const _gap = 14.0;
  static const _maxBar = 104.0;

  final List<InsightsTrendPoint> points;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final max = points.fold<double>(0, (m, p) => p.value > m ? p.value : m);
    return Semantics(
      label: 'Tendencia de gastos por mes',
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        decoration: BoxDecoration(
          color: BnColors.superficie,
          border: Border.all(color: BnColors.hairline),
          borderRadius: BorderRadius.circular(BnRadius.cardGrande),
        ),
        child: SizedBox(
          height: 150,
          child: LayoutBuilder(builder: (context, c) {
            final column = (c.maxWidth - _gap * (_columns - 1)) / _columns;
            final visible = points.length > _columns ? points.sublist(points.length - _columns) : points;
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  SizedBox(
                    width: column,
                    child: _Column(
                      point: visible[i],
                      height: max <= 0 ? 0 : (visible[i].value / max * _maxBar).roundToDouble(),
                      symbol: symbol,
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.point, required this.height, required this.symbol});

  final InsightsTrendPoint point;
  final double height;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final current = point.current;
    return Semantics(
      label: '${point.label}: ${BnFormat.money(point.value, symbol: symbol)}',
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            current ? BnFormat.money(point.value.roundToDouble(), symbol: symbol, decimals: 0) : '',
            style: const TextStyle(
              fontFamily: BnType.family,
              fontSize: 11,
              height: 1.15,
              fontWeight: FontWeight.w600,
              color: BnColors.carbon,
              fontFeatures: BnType.tabular,
            ),
          ),
          const SizedBox(height: 8),
          _GrowBar(
            height: height,
            color: current ? BnColors.brandNaranjaBi : BnColors.hairline,
          ),
          const SizedBox(height: 8),
          Text(
            point.label,
            style: TextStyle(
              fontFamily: BnType.family,
              fontSize: 12,
              height: 1.15,
              color: current ? BnColors.carbon : BnColors.texto3,
              fontWeight: current ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// `.bar { transform-origin: bottom; animation: grow 520ms cubic-bezier(.2,.8,.2,1) both }`.
class _GrowBar extends StatefulWidget {
  const _GrowBar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  State<_GrowBar> createState() => _GrowBarState();
}

class _GrowBarState extends State<_GrowBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status == AnimationStatus.dismissed) {
      _c.duration = bnReduceMotion(context) ? const Duration(milliseconds: 200) : const Duration(milliseconds: 520);
      _c.forward();
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
    final bar = Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(8)),
    );
    return AnimatedBuilder(
      animation: _c,
      child: bar,
      builder: (context, child) => reduce
          ? Opacity(opacity: _c.value, child: child)
          : Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(1, BnMotion.entrada.transform(_c.value), 1),
              child: child,
            ),
    );
  }
}
