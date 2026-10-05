import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';
import 'card_faces.dart';
import 'card_skin.dart';
import 'wallet_card.dart';



abstract final class CardStackMetrics {
  static const y0 = 128.0;
  static const step = 46.0;
  static const stageY = 470.0;
  static const cardHeight = 216.0;
  static const side = 24.0;


  static double frameOffset(BuildContext context) => bnTopInset(context) - BnSpacing.safeTop;

  static double bottomOf(int docked) => docked == 0 ? y0 + cardHeight : y0 + (docked - 1) * step + cardHeight;


  static double panelTop(int docked) => docked >= 3 ? 462 + (docked - 3) * step : 418;
}


class CardStackEntry {
  const CardStackEntry({
    required this.visual,
    required this.y,
    required this.scale,
    required this.z,
    required this.order,
    required this.shade,
    required this.building,
    required this.arc,
    required this.failing,
    required this.frozen,
    required this.isFront,
    required this.interactive,
    required this.flipped,
  });

  final CardVisual visual;
  final double y;
  final double scale;
  final int z;
  final int order;
  final double shade;
  final bool building;
  final bool arc;
  final bool failing;
  final bool frozen;
  final bool isFront;
  final bool interactive;
  final bool flipped;
}



List<CardStackEntry> layoutCardStack({
  required List<CardVisual> present,
  required List<String> docked,
  required List<String> order,
  required bool interactive,
  bool buildPhase = false,
  bool failing = false,
  bool flipped = false,
  bool Function(CardVisual visual)? isFrozen,
}) {
  final dockedOrder = order.where(docked.contains).toList();
  final k = dockedOrder.length;
  final lastDocked = docked.isEmpty ? null : docked.last;
  final entries = <CardStackEntry>[];
  for (var n = 0; n < present.length; n++) {
    final v = present[n];
    final building = !docked.contains(v.id);
    final d = building ? 0 : dockedOrder.indexOf(v.id);
    final isFront = !building && d == 0;
    entries.add(CardStackEntry(
      visual: v,
      y: building ? CardStackMetrics.stageY : CardStackMetrics.y0 + (k - 1 - d) * CardStackMetrics.step,
      scale: building ? 1 : 1 - d * .04,
      z: building ? 40 : 20 - d,
      order: n,
      shade: building ? 0 : math.min(d * .14, .4),
      building: building,
      arc: !building && v.id == lastDocked && buildPhase,
      failing: building && failing,
      frozen: !building && (isFrozen?.call(v) ?? false),
      isFront: isFront,
      interactive: interactive && !building,
      flipped: interactive && isFront && flipped,
    ));
  }
  return entries;
}



class CardStackLayer extends StatelessWidget {
  const CardStackLayer({required this.entries, this.onTapCard, this.onSwipe, super.key});

  final List<CardStackEntry> entries;
  final ValueChanged<CardStackEntry>? onTapCard;
  final ValueChanged<int>? onSwipe;

  @override
  Widget build(BuildContext context) {
    final top = CardStackMetrics.frameOffset(context);
    final sorted = [...entries]..sort((a, b) => a.z != b.z ? a.z.compareTo(b.z) : a.order.compareTo(b.order));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final e in sorted)
          _PosedCard(
            key: ValueKey(e.visual.id),
            entry: e,
            top: top,
            onTap: e.interactive && onTapCard != null ? () => onTapCard!(e) : null,
            onSwipe: e.interactive && e.isFront ? onSwipe : null,
          ),
      ],
    );
  }
}

class _PosedCard extends StatelessWidget {
  const _PosedCard({required this.entry, required this.top, this.onTap, this.onSwipe, super.key});

  final CardStackEntry entry;
  final double top;
  final VoidCallback? onTap;
  final ValueChanged<int>? onSwipe;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final title = e.visual.card?.productName ?? e.visual.skin.title;
    return TweenAnimationBuilder<Offset>(

      tween: Tween(end: Offset(e.y, e.scale)),
      duration: bnReduceMotion(context) ? Duration.zero : BnMotion.tarjetaAlApilar,
      curve: BnMotion.entrada,
      builder: (context, pose, child) => Positioned(
        left: CardStackMetrics.side,
        right: CardStackMetrics.side,
        top: top + pose.dx,
        height: CardStackMetrics.cardHeight,
        child: Transform.scale(scale: pose.dy, alignment: Alignment.topCenter, child: child),
      ),
      child: WalletCard(
        visual: e.visual,
        building: e.building,
        arc: e.arc,
        failing: e.failing,
        frozen: e.frozen,
        shade: e.shade,
        tiltEnabled: e.interactive && e.isFront,
        flipped: e.flipped,
        onTap: onTap,
        onSwipe: onSwipe,
        semanticLabel: e.isFront
            ? '$title, al frente. ${e.flipped ? 'Toca para ver el anverso.' : 'Toca para ver los datos.'}'
            : 'Traer $title al frente',
      ),
    );
  }
}


class CardSlot extends StatelessWidget {
  const CardSlot({super.key});

  @override
  Widget build(BuildContext context) => Positioned(
        left: CardStackMetrics.side,
        right: CardStackMetrics.side,
        top: CardStackMetrics.frameOffset(context) + CardStackMetrics.y0,
        height: CardStackMetrics.cardHeight,
        child: const CustomPaint(
          painter: _DashedBorderPainter(),
          child: Center(
            child:
                CardBrandMark(fontSize: 30, barWidth: 16, barHeight: 3, gap: 6, color: BnColors.piedra, center: true),
          ),
        ),
      );
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(.75),
      const Radius.circular(BnRadius.tarjetaBancaria),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = BnColors.piedra;
    for (final m in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7.5) {
        canvas.drawPath(m.extractPath(d, math.min(d + 4.5, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}


class CardBuildBars extends StatelessWidget {
  const CardBuildBars({required this.total, required this.done, super.key});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) => Semantics(
        value: '$done de $total',
        child: SizedBox(
          width: total * 40.0,
          child: Row(
            children: [
              for (var n = 0; n < total; n++) ...[
                if (n > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 3,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: BnColors.hairline, borderRadius: BorderRadius.circular(2)),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: n < done ? 1 : 0),
                      duration: const Duration(milliseconds: 500),
                      curve: BnMotion.entrada,
                      builder: (context, v, _) => FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: lerpDouble(0, 1, v),
                        child: const ColoredBox(color: BnColors.carbon),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
