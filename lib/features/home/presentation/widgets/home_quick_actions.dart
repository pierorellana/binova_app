import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';

/// Transferir · Pagar · Recargar · Más. [enabled] false renders the offline
/// variant (opacity .45, not tappable).
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    required this.onTransfer,
    required this.onPay,
    required this.onTopup,
    required this.onMore,
    this.enabled = true,
    super.key,
  });

  final VoidCallback onTransfer;
  final VoidCallback onPay;
  final VoidCallback onTopup;
  final VoidCallback onMore;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, VoidCallback)>[
      ('Transferir', BnGlyphs.transfer, onTransfer),
      ('Pagar', BnGlyphs.pay, onPay),
      ('Recargar', BnGlyphs.phone, onTopup),
      ('Más', BnGlyphs.dots, onMore),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Semantics(
        container: true,
        label: 'Acciones rápidas',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _Action(label: items[i].$1, svg: items[i].$2, onTap: enabled ? items[i].$3 : null)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.label, required this.svg, this.onTap});

  final String label;
  final String svg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: BnColors.superficie,
            shape: BoxShape.circle,
            border: Border.all(color: BnColors.hairline),
          ),
          child: BnSvg(svg, size: 22, color: BnColors.carbon),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            fontFamily: BnType.family,
            fontSize: 13,
            height: 1.2,
            fontWeight: FontWeight.w500,
            color: BnColors.carbon,
          ),
        ),
      ],
    );
    if (onTap == null) return Opacity(opacity: .45, child: Semantics(enabled: false, child: content));
    return BnPressable(onTap: onTap, scale: .96, semanticLabel: label, child: content);
  }
}
