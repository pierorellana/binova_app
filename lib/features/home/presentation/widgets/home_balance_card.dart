import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';
import 'home_data.dart';

const _label = Color(0xFFA8A59E);
const _muted = Color(0xFF8E8B85);
const _divider = Color(0x14FFFFFF);

TextStyle _text(double size,
        {FontWeight weight = FontWeight.w400, Color color = BnColors.blancoCalido, double? height}) =>
    TextStyle(fontFamily: BnType.family, fontSize: size, fontWeight: weight, color: color, height: height);

/// Grafito "Saldo total" card. With [offlineAt] it renders the cached
/// variant from `Estado-SinConexion` (no eye toggle, "Saldo a las …").
class HomeBalanceCard extends StatelessWidget {
  const HomeBalanceCard({
    required this.data,
    required this.hidden,
    this.onToggle,
    this.offlineAt,
    super.key,
  });

  final HomeData data;
  final bool hidden;
  final VoidCallback? onToggle;
  final DateTime? offlineAt;

  bool get _offline => offlineAt != null;

  @override
  Widget build(BuildContext context) {
    final month = HomeData.monthName();
    return Semantics(
      container: true,
      label: 'Saldo total',
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: EdgeInsets.fromLTRB(20, 20, 20, _offline ? 20 : 18),
        decoration: BoxDecoration(color: BnColors.grafito, borderRadius: BorderRadius.circular(BnRadius.saldo)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Saldo total', style: _text(14, color: _label))),
                if (!_offline) _EyeButton(hidden: hidden, onTap: onToggle),
              ],
            ),
            const SizedBox(height: 8),
            _Amount(data: data, hidden: hidden, animate: !_offline),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_offline)
                  BnSvg(HomeGlyphs.clock, size: 13, color: _muted)
                else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: BnColors.positivoPunto, shape: BoxShape.circle),
                  ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _offline ? 'Saldo a las ${HomeData.clock(offlineAt!)}' : HomeData.updatedLabel(data.fetchedAt),
                    style: _text(13, color: _muted, height: 1.2),
                  ),
                ),
              ],
            ),
            if (!_offline)
              Container(
                margin: const EdgeInsets.only(top: 18),
                padding: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: _divider))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Ingresos de $month',
                        value: hidden ? homeMask : data.money(data.income, signed: true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _Metric(
                        label: 'Gastos de $month',
                        value: hidden ? homeMask : data.money(-data.expense),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EyeButton extends StatelessWidget {
  const _EyeButton({required this.hidden, this.onTap});

  final bool hidden;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => BnPressable(
        onTap: onTap,
        scale: .96,
        semanticLabel: hidden ? 'Mostrar saldo' : 'Ocultar saldo',
        child: Container(
          width: 44,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(16)),
          child: BnSvg(hidden ? BnGlyphs.eyeOff : BnGlyphs.eye, size: 18, color: BnColors.blancoCalido),
        ),
      );
}

class _Amount extends StatelessWidget {
  const _Amount({required this.data, required this.hidden, required this.animate});

  final HomeData data;
  final bool hidden;
  final bool animate;

  static const _style = TextStyle(
    fontFamily: BnType.family,
    fontSize: 42,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.47,
    height: 1.1,
    color: BnColors.blancoCalido,
    fontFeatures: BnType.tabular,
  );

  Widget _parts(double value) {
    final (integer, decimals) = BnFormat.moneyParts(value, symbol: data.symbol);
    return Text.rich(
      TextSpan(
        text: integer,
        children: [TextSpan(text: decimals, style: const TextStyle(fontSize: 24, color: _muted))],
      ),
      style: _style,
      maxLines: 1,
      semanticsLabel: data.money(data.balance),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget masked() => Text(r'$ ••••••', style: _style.copyWith(letterSpacing: 1.68), semanticsLabel: 'Saldo oculto');
    if (!animate) return hidden ? masked() : _parts(data.balance);
    // Count-up 650 ms ease-out cubic after 120 ms; stays mounted while masked
    // so revealing the balance never restarts the count.
    return BnCountUp(value: data.balance, builder: (context, v) => hidden ? masked() : _parts(v));
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _text(12, color: _label, height: 1.2)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            style: _text(16, weight: FontWeight.w600, height: 1.2).copyWith(fontFeatures: BnType.tabular),
          ),
        ],
      );
}
