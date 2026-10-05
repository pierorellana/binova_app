import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';
import 'card_skin.dart';

/// Card expiry is not part of the card entity, so it stays masked like the
/// rest of the protected data.
const kCardExpiryMasked = '••/••';

final _contactless = bnLine(
  '<path d="M8 8.5a5 5 0 0 1 0 7"/><path d="M11.5 6a8.5 8.5 0 0 1 0 12"/><path d="M15 3.5a12 12 0 0 1 0 17"/>',
  stroke: 1.7,
);

/// Time marks (ms) of the construction sequence in `Tarjetas.dc.html`:
/// outline 60+520 → fill wipe 380+520 → sweep 820+700 → d1/d2/d3 → g1..g4.
abstract final class CardBuildTimeline {
  static const total = 1520.0;
  static double seg(double t, double start, double duration, Curve curve) =>
      curve.transform(((t - start) / duration).clamp(0.0, 1.0));
}

/// Front side (`.side` anverso). [buildMs] is the elapsed construction time;
/// null means the card is already built.
class CardFront extends StatelessWidget {
  const CardFront({
    required this.visual,
    this.glareCenter = const Offset(.2, 0),
    this.glareAlpha = .08,
    this.buildMs,
    super.key,
  });

  final CardVisual visual;
  final Offset glareCenter;
  final double glareAlpha;
  final double? buildMs;

  @override
  Widget build(BuildContext context) {
    final skin = visual.skin;
    final t = buildMs;
    double rise(double delay) => t == null ? 1 : CardBuildTimeline.seg(t, delay, 360, BnMotion.entrada);
    double digit(int i) => t == null ? 1 : CardBuildTimeline.seg(t, 1060 + 60.0 * i, 220, BnMotion.entrada);

    Widget detail(double p, Widget child) =>
        p >= 1 ? child : Opacity(opacity: p, child: Transform.translate(offset: Offset(0, 10 * (1 - p)), child: child));

    final digits = visual.last4.split('');
    final fill = Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: CardSkinPainter(skin)),
        CustomPaint(painter: CardGlarePainter(center: glareCenter, alpha: glareAlpha)),
        if (t != null && t >= 820 && t < CardBuildTimeline.total)
          _Sweep(progress: CardBuildTimeline.seg(t, 820, 700, BnMotion.estandar)),
        Positioned(
          left: 18,
          right: 18,
          top: 14,
          height: 22,
          child: Row(
            children: [
              const CardBrandMark(),
              const SizedBox(width: 10),
              Text(skin.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('•••• ', style: TextStyle(fontSize: 13, color: skin.muted, fontFeatures: BnType.tabular)),
              for (var i = 0; i < digits.length; i++)
                _Digit(
                    progress: digit(i),
                    child: Text(digits[i],
                        style: TextStyle(fontSize: 13, color: skin.muted, fontFeatures: BnType.tabular))),
            ],
          ),
        ),
        Positioned(
          left: 18,
          top: 82,
          child: detail(
            rise(860),
            Row(
              children: [
                CardChip(color: skin.chip),
                const SizedBox(width: 14),
                Opacity(opacity: .8, child: BnSvg(_contactless, size: 22, color: skin.fg)),
              ],
            ),
          ),
        ),
        Positioned(
          left: 18,
          bottom: 16,
          child:
              detail(rise(940), _Field(label: 'Titular', value: visual.holder, muted: skin.muted, valueSpacing: 1.04)),
        ),
        Positioned(
          right: 18,
          bottom: 16,
          child: detail(
            rise(1020),
            _Field(label: skin.name, value: kCardExpiryMasked, muted: skin.muted, end: true, tabular: true),
          ),
        ),
      ],
    );

    final wipe = t == null ? 1.0 : CardBuildTimeline.seg(t, 380, 520, BnMotion.cambioEstado);
    if (wipe <= 0) return const SizedBox.expand();
    return DefaultTextStyle(
      style: TextStyle(fontFamily: BnType.family, color: skin.fg, height: 1.2),
      child: wipe >= 1 ? fill : ClipPath(clipper: _WipeClipper(wipe), child: fill),
    );
  }
}

/// Back side (`.side.back`): magnetic stripe, masked number, expiry, CVV.
class CardBack extends StatelessWidget {
  const CardBack({required this.visual, super.key});

  final CardVisual visual;

  @override
  Widget build(BuildContext context) {
    final skin = visual.skin;
    return DefaultTextStyle(
      style: TextStyle(fontFamily: BnType.family, color: skin.fg, height: 1.2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: CardSkinPainter(skin, texture: false)),
          const Positioned(left: 0, right: 0, top: 30, height: 40, child: ColoredBox(color: Color(0xD90E0F11))),
          Positioned(
            left: 18,
            right: 18,
            top: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Número', color: skin.muted),
                const SizedBox(height: 4),
                Text(
                  '•••• •••• •••• ${visual.last4}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.08, fontFeatures: BnType.tabular),
                ),
              ],
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Field(label: 'Vence', value: kCardExpiryMasked, muted: skin.muted, tabular: true),
                const SizedBox(width: 28),
                _Field(label: 'CVV', value: '•••', muted: skin.muted, tabular: true),
                const SizedBox(width: 28),
                Expanded(
                  child: Text(
                    'Datos protegidos con Face ID',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: skin.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "BI" wordmark with the orange underline used on the cards.
class CardBrandMark extends StatelessWidget {
  const CardBrandMark(
      {this.fontSize = 17,
      this.barWidth = 10,
      this.barHeight = 2,
      this.gap = 3,
      this.color,
      this.center = false,
      super.key});

  final double fontSize;
  final double barWidth;
  final double barHeight;
  final double gap;
  final Color? color;
  final bool center;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            'BI',
            style: TextStyle(
              fontFamily: BnType.family,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.04 * fontSize,
              height: 1,
              color: color,
            ),
          ),
          SizedBox(height: gap),
          Container(
            width: barWidth,
            height: barHeight,
            decoration:
                BoxDecoration(color: BnColors.brandNaranjaBi, borderRadius: BorderRadius.circular(barHeight / 2 + .5)),
          ),
        ],
      );
}

/// EMV chip: 40×30, r7, two horizontal and one vertical contact line.
class CardChip extends StatelessWidget {
  const CardChip({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0x1F141518)),
        ),
        child: const Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(left: -1, right: -1, top: 9, height: 1, child: ColoredBox(color: Color(0x38141518))),
            Positioned(left: -1, right: -1, top: 18, height: 1, child: ColoredBox(color: Color(0x38141518))),
            Positioned(top: -1, bottom: -1, left: 14, width: 1, child: ColoredBox(color: Color(0x38141518))),
          ],
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: color));
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.muted,
    this.end = false,
    this.tabular = false,
    this.valueSpacing = 0,
  });

  final String label;
  final String value;
  final Color muted;
  final bool end;
  final bool tabular;
  final double valueSpacing;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _Label(label, color: muted),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: valueSpacing,
              fontFeatures: tabular ? BnType.tabular : null,
            ),
          ),
        ],
      );
}

class _Digit extends StatelessWidget {
  const _Digit({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) => progress >= 1
      ? child
      : Opacity(
          opacity: progress,
          child: Transform.translate(offset: Offset(0, 6 * (1 - progress)), child: child),
        );
}

/// `.sweep`: skewed white shine travelling from -40% to 110%.
class _Sweep extends StatelessWidget {
  const _Sweep({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: w * lerpDouble(-.4, 1.1, progress)!,
                top: -.2 * h,
                width: w * .38,
                height: h * 1.4,
                child: Opacity(
                  opacity: 1 - progress,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.skewX(bnDeg(-18)),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0x00FFFFFF), Color(0x38FFFFFF), Color(0x00FFFFFF)]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
}

/// `clip-path: inset(0 X% 0 0 round 20px)` animated from 100% to 0.
class _WipeClipper extends CustomClipper<Path> {
  const _WipeClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) => Path()
    ..addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * progress, size.height),
      const Radius.circular(BnRadius.tarjetaBancaria),
    ));

  @override
  bool shouldReclip(covariant _WipeClipper old) => old.progress != progress;
}
