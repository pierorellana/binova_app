import 'package:flutter/material.dart';

import '../../../../core/design_system/binova_widgets.dart';
import '../../../accounts/domain/entities/account.dart';
import 'operation_copy.dart';
import 'operation_motion.dart';


TextStyle opStyle(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = BnColors.carbon,
  double? letterSpacing,
  double? height,
  bool tabular = false,
}) =>
    TextStyle(
      fontFamily: BnType.family,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: tabular ? BnType.tabular : null,
    );


String accountLabel(Account account) {
  final type = switch (account.type) {
    AccountType.savings => 'Ahorros',
    AccountType.current => 'Corriente',
    AccountType.credit => 'Crédito',
  };
  return '$type ${account.maskedNumber}';
}



Account? operationSource(List<Account> accounts) {
  final active = accounts.where((a) => a.status == AccountStatus.active).toList();
  if (active.isEmpty) return null;
  return active.firstWhere((a) => a.type == AccountType.savings, orElse: () => active.first);
}

double accountAvailable(Account account) => double.tryParse(account.availableBalance.amount) ?? 0;

abstract final class OpGlyphs {
  static final search = bnLine('<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>', stroke: 2);
  static final plus = bnLine('<path d="M12 5v14M5 12h14"/>', stroke: 1.8);
  static final bolt = bnLine('<path d="M13 2 4 14h7l-1 8 9-12h-7z"/>');
  static final drop = bnLine('<path d="M12 3.5s6 6.4 6 10.5a6 6 0 0 1-12 0c0-4.1 6-10.5 6-10.5z"/>');
  static final wifi = bnLine('<path d="M2 8.8a15 15 0 0 1 20 0M5 12.5a10 10 0 0 1 14 0M8.5 16.5a5 5 0 0 1 7 0"/><path d="M12 20h.01"/>');
  static final phone = BnGlyphs.phone;
  static final backspace = bnLine('<path d="M8.5 5H20a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H8.5L3 12z"/><path d="M11.5 9.5l5 5M16.5 9.5l-5 5"/>');
  static final lock = bnLine('<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8 10.5V7.5a4 4 0 0 1 8 0v3"/>', stroke: 2);
  static final shieldCheck = bnLine('<path d="M12 3l7 3v5.5c0 4.5-3 7.8-7 9.5-4-1.7-7-5-7-9.5V6z"/><path d="M9 12l2 2 4-4"/>', stroke: 1.8);
  static final share =
      bnLine('<path d="M12 3v12"/><path d="M8 7l4-4 4 4"/><path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7"/>', stroke: 1.8);
  static const dashedCircle = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44" fill="none">'
      '<circle cx="22" cy="22" r="21.5" stroke="#A8A59E" stroke-width="1" stroke-dasharray="3 3"/></svg>';
}


class OperationNavRow extends StatelessWidget {
  const OperationNavRow({required this.leading, required this.center, required this.trailing, super.key});

  final Widget leading;
  final Widget center;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [leading, Flexible(child: center), trailing],
          ),
        ),
      );
}

class OperationBackButton extends StatelessWidget {
  const OperationBackButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BnPressable(
        onTap: onTap,
        semanticLabel: 'Volver',
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: BnSvg(BnGlyphs.back, size: 24, color: BnColors.carbon)),
        ),
      );
}

class OperationTextButton extends StatelessWidget {
  const OperationTextButton({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BnPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(widthFactor: 1, child: Text(label, style: opStyle(17))),
          ),
        ),
      );
}

class OperationSearchField extends StatelessWidget {
  const OperationSearchField({required this.controller, required this.hint, super.key});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: BnColors.rellenoCampo, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            BnSvg(OpGlyphs.search, size: 17, color: BnColors.texto2),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                cursorColor: BnColors.carbon,
                style: opStyle(16),
                decoration: InputDecoration.collapsed(
                  hintText: hint,
                  hintStyle: opStyle(16, color: BnColors.placeholder),
                ),
              ),
            ),
          ],
        ),
      );
}


class OperationListTitle extends StatelessWidget {
  const OperationListTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
        child: rise(
          Semantics(
            header: true,
            child: Text(text.toUpperCase(), style: opStyle(13, weight: FontWeight.w600, color: BnColors.texto2, letterSpacing: .52)),
          ),
        ),
      );
}

class OperationAvatar extends StatelessWidget {
  const OperationAvatar({required this.target, this.size = 44, super.key});

  final OperationTarget target;
  final double size;

  @override
  Widget build(BuildContext context) {
    final compact = size < 44;
    final icon = target.icon;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: target.background, shape: BoxShape.circle),
      child: !compact && icon != null
          ? BnSvg(icon, size: 20, color: target.foreground)
          : Text(
              compact ? target.compactInitials : target.initials ?? '',
              style: opStyle(compact ? 11 : 15, weight: FontWeight.w600, color: target.foreground),
            ),
    );
  }
}

class OperationTargetRow extends StatelessWidget {
  const OperationTargetRow({required this.target, required this.onTap, super.key});

  final OperationTarget target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BnRowPressable(
        onTap: onTap,
        pressedColor: BnColors.relleno,
        pressScale: .99,
        semanticLabel: '${target.name}, ${target.subtitle}',
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: BnColors.divisorSuave))),
          child: Row(
            children: [
              OperationAvatar(target: target),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(target.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: opStyle(16, weight: FontWeight.w500, height: 1.2)),
                    Text(target.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: opStyle(13, color: BnColors.texto3, height: 1.2, tabular: true)),
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

class OperationTargetSkeleton extends StatelessWidget {
  const OperationTargetSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 68,
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: BnColors.divisorSuave))),
        child: const Row(
          children: [
            BnSkeleton(height: 44, circle: true),
            SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BnSkeleton(width: 140, height: 14),
                SizedBox(height: 8),
                BnSkeleton(width: 200, height: 11),
              ],
            ),
          ],
        ),
      );
}


class OperationComingSoonRow extends StatelessWidget {
  const OperationComingSoonRow({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => BnRise(
        delay: const Duration(milliseconds: 240),
        child: Opacity(
          opacity: .55,
          child: Semantics(
            enabled: false,
            label: '$label, próximamente',
            excludeSemantics: true,
            child: Container(
              constraints: const BoxConstraints(minHeight: 68),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const BnSvg(OpGlyphs.dashedCircle, size: 44),
                        BnSvg(OpGlyphs.plus, size: 18, color: BnColors.carbon),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: opStyle(16, weight: FontWeight.w500, height: 1.2)),
                      Text('PRÓXIMAMENTE',
                          style: opStyle(12, weight: FontWeight.w600, color: BnColors.texto2, letterSpacing: .48, height: 1.2)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}


class OperationRecipientHeader extends StatelessWidget {
  const OperationRecipientHeader({required this.target, super.key});

  final OperationTarget target;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OperationAvatar(target: target, size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(target.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: opStyle(15, weight: FontWeight.w600, height: 1.2)),
                Text(target.subtitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: opStyle(12, color: BnColors.texto3, height: 1.2, tabular: true)),
              ],
            ),
          ),
        ],
      );
}


class OperationSourceCard extends StatelessWidget {
  const OperationSourceCard({required this.account, required this.loading, this.error, super.key});

  final Account? account;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final value = account;
    final Widget body;
    if (value != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Desde ${accountLabel(value)}', style: opStyle(15, weight: FontWeight.w500, height: 1.2)),
          Text('Disponible ${BnFormat.money(accountAvailable(value))}',
              style: opStyle(13, color: BnColors.texto3, height: 1.2, tabular: true)),
        ],
      );
    } else if (loading) {
      body = const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [BnSkeleton(width: 170, height: 13), SizedBox(height: 7), BnSkeleton(width: 120, height: 11)],
      );
    } else {
      body = Text(error ?? 'No tienes una cuenta activa para operar.', style: opStyle(14, color: BnColors.critico, height: 1.3));
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BnColors.superficie,
        border: Border.all(color: BnColors.hairline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          BnIconTile(svg: BnGlyphs.bank, size: 36, iconSize: 18, radius: 10),
          const SizedBox(width: 12),
          Expanded(child: body),
        ],
      ),
    );
  }
}


class OperationDetailCard extends StatelessWidget {
  const OperationDetailCard({required this.rows, super.key});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: BnColors.superficie,
          border: Border.all(color: BnColors.hairline),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++)
              Container(
                constraints: const BoxConstraints(minHeight: 52),
                decoration: BoxDecoration(
                  border: i == 0 ? null : const Border(top: BorderSide(color: BnColors.relleno)),
                ),
                child: OperationDetailRow(label: rows[i].$1, value: rows[i].$2, size: 15),
              ),
          ],
        ),
      );
}

class OperationDetailRow extends StatelessWidget {
  const OperationDetailRow({required this.label, required this.value, required this.size, super.key});

  final String label;
  final String value;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label, style: opStyle(size, color: BnColors.texto2)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: opStyle(size, weight: FontWeight.w500, tabular: true)),
          ),
        ],
      );
}


class OperationStatusLabel extends StatelessWidget {
  const OperationStatusLabel({required this.icon, required this.label, required this.color, super.key});

  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BnSvg(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: opStyle(13, weight: FontWeight.w600, color: color, letterSpacing: .13)),
        ],
      );
}


class OperationMiniTrace extends StatefulWidget {
  const OperationMiniTrace({super.key});

  @override
  State<OperationMiniTrace> createState() => _OperationMiniTraceState();
}

class _OperationMiniTraceState extends State<OperationMiniTrace> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = bnReduceMotion(context);
    return SizedBox(
      width: 18,
      height: 18,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _MiniTracePainter(reduce ? 0 : _c.value)),
      ),
    );
  }
}

class _MiniTracePainter extends CustomPainter {
  _MiniTracePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(6 * s, 6 * s, 88 * s, 88 * s), Radius.circular(28 * s));
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 * s
      ..color = BnColors.hairline;
    canvas.drawRRect(rrect, base);
    final metric = (Path()..addRRect(rrect)).computeMetrics().first;
    final len = metric.length;

    final start = (t * len) % len;
    final dash = len * .22;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9 * s
      ..strokeCap = StrokeCap.round
      ..color = BnColors.brandNaranjaBi;
    final end = start + dash;
    canvas.drawPath(metric.extractPath(start, end.clamp(0, len)), paint);
    if (end > len) canvas.drawPath(metric.extractPath(0, end - len), paint);
  }

  @override
  bool shouldRepaint(covariant _MiniTracePainter old) => old.t != t;
}
