import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';

const _cardWidth = 264.0;
const _gap = 12.0;



class HomeForYou extends StatelessWidget {
  const HomeForYou({required this.onInsights, required this.onExchange, super.key});

  final VoidCallback onInsights;
  final VoidCallback onExchange;

  @override
  Widget build(BuildContext context) {
    final cards = <(String, Color, Color, String, String, VoidCallback)>[
      (
        BnGlyphs.trend,
        BnColors.positivoFondo,
        BnColors.positivo,
        'Este mes has ahorrado un 14% más.',
        'Ver tu progreso',
        onInsights
      ),
      (
        BnGlyphs.bars,
        BnColors.brandNaranjaTinte,
        BnColors.brandNaranjaTexto,
        'Revisa cómo han cambiado tus gastos.',
        'Abrir Insights',
        onInsights
      ),
      (
        BnGlyphs.globe,
        BnColors.relleno,
        BnColors.carbon,
        '¿Viajas próximamente? Consulta el tipo de cambio.',
        'Abrir conversor',
        onExchange
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: BnSectionHeader('Para ti', subtitle: 'Según tu actividad reciente'),
          ),
          SizedBox(
            height: 156,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const _SnapPhysics(extent: _cardWidth + _gap, parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: _gap),
              itemBuilder: (context, i) {
                final (svg, bg, fg, text, cta, onTap) = cards[i];
                return _Card(svg: svg, background: bg, foreground: fg, text: text, cta: cta, onTap: onTap);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.svg,
    required this.background,
    required this.foreground,
    required this.text,
    required this.cta,
    required this.onTap,
  });

  final String svg;
  final Color background;
  final Color foreground;
  final String text;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BnPressable(
        onTap: onTap,
        scale: .96,
        semanticLabel: '$text $cta',
        child: Container(
          width: _cardWidth,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BnColors.superficie,
            borderRadius: BorderRadius.circular(BnRadius.card),
            border: Border.all(color: BnColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BnIconTile(svg: svg, size: 36, iconSize: 18, background: background, color: foreground, circle: true),
              const SizedBox(height: 12),
              Text(text, style: BnType.body.copyWith(height: 1.35)),
              const Spacer(),
              const SizedBox(height: 12),
              Text(
                cta,
                style: const TextStyle(
                  fontFamily: BnType.family,
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: BnColors.carbon,
                ),
              ),
            ],
          ),
        ),
      );
}


class _SnapPhysics extends ScrollPhysics {
  const _SnapPhysics({required this.extent, super.parent});

  final double extent;

  @override
  _SnapPhysics applyTo(ScrollPhysics? ancestor) => _SnapPhysics(extent: extent, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    var page = position.pixels / extent;
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    final target = (page.roundToDouble() * extent).clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tolerance);
  }

  @override
  bool get allowImplicitScrolling => false;
}
