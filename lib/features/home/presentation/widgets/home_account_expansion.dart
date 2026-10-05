import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';

/// Shared element from `Home.dc.html` (`.xp`): the tapped product row grows
/// into the account detail header (340 ms, cubic-bezier(.2,.8,.2,1)), then the
/// detail route is pushed underneath and the overlay fades away once the
/// route is on screen.
Future<void> playHomeAccountExpansion(
  BuildContext context, {
  required Rect from,
  required String name,
  required String maskedNumber,
  required String amount,
  required VoidCallback navigate,
}) async {
  BnHaptics.tap();
  if (bnReduceMotion(context)) {
    navigate();
    return;
  }
  final overlay = Overlay.of(context, rootOverlay: true);
  final topInset = bnTopInset(context);
  final visible = ValueNotifier<bool>(true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Expansion(
      from: from,
      topInset: topInset,
      name: name,
      maskedNumber: maskedNumber,
      amount: amount,
      visible: visible,
    ),
  );
  overlay.insert(entry);
  // Same timeline as the canvas: navigate 360 ms after the tap.
  await Future<void>.delayed(const Duration(milliseconds: 360));
  navigate();
  // The route cross-fades in 120 ms under the overlay; reveal it right after
  // so the detail's staggered entrance plays, as in the canvas.
  await Future<void>.delayed(const Duration(milliseconds: 140));
  visible.value = false;
  await Future<void>.delayed(const Duration(milliseconds: 200));
  entry.remove();
  visible.dispose();
}

class _Expansion extends StatefulWidget {
  const _Expansion({
    required this.from,
    required this.topInset,
    required this.name,
    required this.maskedNumber,
    required this.amount,
    required this.visible,
  });

  final Rect from;
  final double topInset;
  final String name;
  final String maskedNumber;
  final String amount;
  final ValueNotifier<bool> visible;

  @override
  State<_Expansion> createState() => _ExpansionState();
}

class _ExpansionState extends State<_Expansion> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: BnMotion.sharedElement)..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return ValueListenableBuilder<bool>(
      valueListenable: widget.visible,
      builder: (context, visible, child) => IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(opacity: visible ? 1 : 0, duration: const Duration(milliseconds: 180), child: child),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = BnMotion.entrada.transform(_c.value);
          final ease = Curves.ease.transform(_c.value);
          // Label: opacity 200 ms ease after 120 ms; max-height 340 ms ease.
          final labelOpacity = const Interval(120 / 340, 320 / 340, curve: Curves.ease).transform(_c.value);
          double lerp(double a, double b) => a + (b - a) * t;

          final side = lerp(widget.from.left, 0);
          final top = lerp(widget.from.top, 0);
          final height = lerp(widget.from.height, screen.height);
          return DefaultTextStyle(
            style: _base,
            child: Stack(
              children: [
                Positioned(
                  top: top,
                  left: side,
                  right: side,
                  height: height,
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    padding: EdgeInsets.fromLTRB(lerp(68, 20), lerp(14, widget.topInset + 64), lerp(16, 20), 0),
                    decoration: BoxDecoration(
                      color: Color.lerp(BnColors.superficie, BnColors.blancoCalido, ease),
                      borderRadius: BorderRadius.circular(lerp(18, 0)),
                      boxShadow: [BoxShadow(color: BnColors.hairline.withOpacity(1 - ease), spreadRadius: 1)],
                    ),
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      maxHeight: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(widget.name,
                                    maxLines: 1, softWrap: false, overflow: TextOverflow.clip, style: _caption),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(color: BnColors.texto5, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(widget.maskedNumber, style: _caption.copyWith(fontFeatures: BnType.tabular)),
                            ],
                          ),
                          SizedBox(height: 16 * Curves.ease.transform(_c.value)),
                          ClipRect(
                            child: Align(
                              alignment: Alignment.topLeft,
                              heightFactor: Curves.ease.transform(_c.value),
                              child: Opacity(
                                opacity: labelOpacity,
                                child: const SizedBox(
                                  height: 20,
                                  child: Text('Saldo disponible', style: BnType.footnote),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.amount,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontFamily: BnType.family,
                              fontSize: lerp(16, 42),
                              fontWeight: FontWeight.w600,
                              letterSpacing: lerp(16, 42) * -0.03,
                              height: 1.1,
                              color: BnColors.carbon,
                              fontFeatures: BnType.tabular,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

const _base = TextStyle(fontFamily: BnType.family, color: BnColors.carbon, decoration: TextDecoration.none);
const _caption = TextStyle(fontFamily: BnType.family, fontSize: 15, height: 1.2, color: BnColors.texto2);
