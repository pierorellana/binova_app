import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';


Future<void> showHomeMoreServices(BuildContext context, {required VoidCallback onExchange}) => showBnSheet<void>(
      context,
      builder: (sheetContext) => _MoreServices(
        onExchange: () {
          Navigator.of(sheetContext).pop();
          onExchange();
        },
      ),
    );

const _sectionLabel =
    TextStyle(fontFamily: BnType.family, fontSize: 13, fontWeight: FontWeight.w500, color: BnColors.texto3);

class _MoreServices extends StatelessWidget {
  const _MoreServices({required this.onExchange});

  final VoidCallback onExchange;

  @override
  Widget build(BuildContext context) {
    final upcoming = <(String, String)>[
      (BnGlyphs.cardlessWithdrawal, 'Retiro sin tarjeta'),
      (BnGlyphs.goals, 'Metas de ahorro'),
      (BnGlyphs.investments, 'Inversiones'),
      (BnGlyphs.shield, 'Seguros'),
    ];
    return SingleChildScrollView(
      physics: bnScrollPhysics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const BnSheetHeader(title: 'Más servicios'),
          const SizedBox(height: 16),
          const Text('Servicios BInova · en camino', style: _sectionLabel),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < upcoming.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _Upcoming(svg: upcoming[i].$1, label: upcoming[i].$2)),
              ],
            ],
          ),
          const SizedBox(height: 24),
          const Text('Servicios conectados', style: _sectionLabel),
          const SizedBox(height: 8),
          BnCard(radius: 16, child: _Connected(onTap: onExchange)),
        ],
      ),
    );
  }
}

class _Upcoming extends StatelessWidget {
  const _Upcoming({required this.svg, required this.label});

  final String svg;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
        enabled: false,
        label: '$label, próximamente',
        excludeSemantics: true,
        child: Opacity(
          opacity: .5,
          child: Column(
            children: [
              BnIconTile(svg: svg, size: 52, iconSize: 22, radius: 16, background: BnColors.blancoCalido),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: BnType.family, fontSize: 12, height: 1.25, color: BnColors.carbon),
              ),
              const SizedBox(height: 8),
              const Text(
                'PRÓXIMAMENTE',
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontFamily: BnType.family,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .4,
                  color: BnColors.texto2,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Connected extends StatelessWidget {
  const _Connected({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BnRowPressable(
        onTap: onTap,
        semanticLabel: 'Conversor de monedas',
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              BnIconTile(
                svg: BnGlyphs.globe,
                size: 36,
                iconSize: 18,
                radius: 10,
                background: BnColors.brandNaranjaTinte,
                color: BnColors.brandNaranjaTexto,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Conversor de monedas', style: BnType.body.copyWith(height: 1.2)),
                    Text('Tipo de cambio en tiempo real', style: BnType.footnote.copyWith(height: 1.2)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              BnSvg(BnGlyphs.chevronRight, size: 16, color: BnColors.texto5),
            ],
          ),
        ),
      );
}
