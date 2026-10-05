import 'package:flutter/material.dart';

import '../../../../core/design_system/binova_widgets.dart';
import 'operation_motion.dart';
import 'operation_parts.dart';

enum AmountKeyResult { accepted, rejected, rejectedWithHaptic }

/// Keypad input rules of the prototype (`press(k)`): at most 7 digits and
/// 2 decimals, a single decimal point, leading zero replaced.
abstract final class AmountInput {
  static (String, AmountKeyResult) press(String value, String key) {
    if (key == 'del') {
      return (value.isEmpty ? value : value.substring(0, value.length - 1), AmountKeyResult.accepted);
    }
    if (key == '.') {
      if (value.contains('.')) return (value, AmountKeyResult.rejected);
      return ('${value.isEmpty ? '0' : value}.', AmountKeyResult.accepted);
    }
    final dot = value.indexOf('.');
    final decimals = dot >= 0 ? value.length - dot - 1 : -1;
    if (decimals >= 2 || value.replaceAll('.', '').length >= 7) {
      return (value, AmountKeyResult.rejectedWithHaptic);
    }
    return ('${value == '0' ? '' : value}$key', AmountKeyResult.accepted);
  }

  static double parse(String value) => double.tryParse(value.isEmpty ? '0' : value) ?? 0;

  /// `1500.5` typed → `1,500.5` shown (integer part grouped, decimals as typed).
  static String shown(String value) {
    final raw = value.isEmpty ? '0' : value;
    final parts = raw.split('.');
    final integer = BnFormat.number(int.tryParse(parts[0].isEmpty ? '0' : parts[0]) ?? 0, decimals: 0);
    return parts.length > 1 ? '$integer.${parts[1]}' : integer;
  }
}

/// Big amount with grey `$`, pop-in of the last digit, font-size transition
/// (68 → 52 px beyond 7 characters) and the invalid-input nudge.
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    required this.value,
    required this.presses,
    required this.nudge,
    required this.over,
    super.key,
  });

  final String value;
  final int presses;
  final int nudge;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final shown = AmountInput.shown(value);
    final color = value.isEmpty ? BnColors.texto5 : (over ? BnColors.critico : BnColors.carbon);
    return Semantics(
      liveRegion: true,
      label: 'Monto: ${BnFormat.money(AmountInput.parse(value))}',
      excludeSemantics: true,
      child: OperationNudge(
        trigger: nudge,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: shown.length > 7 ? 52 : 68),
          duration: const Duration(milliseconds: 200),
          curve: BnMotion.entrada,
          builder: (context, size, _) {
            final style = opStyle(size, weight: FontWeight.w600, color: color, letterSpacing: -.04 * size, height: 1, tabular: true);
            final chars = shown.split('');
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: size * .5 * .12, right: 2),
                  child: Text(r'$', style: style.copyWith(fontSize: size * .5, letterSpacing: -.02 * size, color: BnColors.texto4)),
                ),
                for (var i = 0; i < chars.length; i++)
                  if (i == chars.length - 1 && value.isNotEmpty)
                    DigitPop(key: ValueKey(presses), child: Text(chars[i], style: style))
                  else
                    Text(chars[i], style: style),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 3×4 numeric keypad (`.key`: #E9E6E1 + scale .94 while pressed, 120 ms).
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({required this.onKey, super.key});

  final ValueChanged<String> onKey;

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'del'];

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Teclado numérico',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
          child: Column(
            children: [
              for (var row = 0; row < 4; row++) ...[
                if (row > 0) const SizedBox(height: 4),
                Row(
                  children: [
                    for (var col = 0; col < 3; col++) ...[
                      if (col > 0) const SizedBox(width: 4),
                      Expanded(child: _Key(value: _keys[row * 3 + col], onKey: onKey)),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      );
}

class _Key extends StatelessWidget {
  const _Key({required this.value, required this.onKey});

  final String value;
  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) => PressScale(
        onTap: () => onKey(value),
        semanticLabel: value == 'del'
            ? 'Borrar'
            : value == '.'
                ? 'Punto decimal'
                : value,
        builder: (context, pressed) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pressed ? BnColors.divisorSuave : const Color(0x00E9E6E1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: value == 'del'
              ? BnSvg(OpGlyphs.backspace, size: 26, color: BnColors.carbon)
              : Text(value, style: opStyle(26, weight: FontWeight.w500)),
        ),
      );
}
