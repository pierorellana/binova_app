import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/binova_widgets.dart';
import '../providers/exchange_rate_controller.dart';


class _Currency {
  const _Currency(this.code, this.symbol, this.name);

  final String code;
  final String symbol;
  final String name;
}

const _currencies = <_Currency>[
  _Currency('USD', r'$', 'Dólar estadounidense'),
  _Currency('EUR', '€', 'Euro'),
  _Currency('GBP', '£', 'Libra esterlina'),
  _Currency('COP', r'$', 'Peso colombiano'),
  _Currency('PEN', 'S/', 'Sol peruano'),
  _Currency('MXN', r'$', 'Peso mexicano'),
];

enum _Side { from, to }

const _press = 0.96;
const _amountStyle = TextStyle(
  fontFamily: BnType.family,
  fontSize: 32,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.96,
  color: BnColors.carbon,
  fontFeatures: BnType.tabular,
);


String _formatRate(double value) {
  final fixed = value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
  final parts = fixed.split('.');
  final integer = BnFormat.number(double.parse(parts[0]), decimals: 0);
  return parts.length > 1 ? '$integer.${parts[1]}' : integer;
}

class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> {
  final _amount = TextEditingController(text: '1,000');
  _Currency _from = _currencies[0];
  _Currency _to = _currencies[1];
  int _turns = 0;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_from.code == _to.code) return;
    await context.read<ExchangeRateController>().load(base: _from.code, quote: _to.code);
  }

  void _swap() {
    setState(() {
      final from = _from;
      _from = _to;
      _to = from;
      _turns++;
    });
    _load();
  }

  Future<void> _pick(_Side side) async {
    final current = side == _Side.from ? _from : _to;
    final picked = await showBnSheet<_Currency>(
      context,
      builder: (_) => _CurrencySheet(
        title: side == _Side.from ? 'Moneda de origen' : 'Moneda de destino',
        selected: current,
      ),
    );
    if (picked == null || picked.code == current.code || !mounted) return;
    setState(() => side == _Side.from ? _from = picked : _to = picked);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ExchangeRateController>();
    final rate = controller.rate;
    final pairRate = rate != null && rate.base == _from.code && rate.quote == _to.code ? rate : null;
    final loading = _from.code != _to.code &&
        (controller.status == ExchangeRateStatus.loading || controller.status == ExchangeRateStatus.idle);
    final down = !loading &&
        _from.code != _to.code &&
        (controller.status == ExchangeRateStatus.failure || (pairRate?.stale ?? false));
    final factor = _from.code == _to.code ? 1.0 : double.tryParse(pairRate?.rate ?? '');
    final amount = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;

    final String updated;
    if (loading) {
      updated = 'Actualizando…';
    } else if (_from.code == _to.code) {
      updated = 'Hoy, ahora';
    } else if (pairRate == null) {
      updated = '—';
    } else {
      final when = BnFormat.relativeDay(pairRate.asOf.toLocal());
      updated = down ? '$when · referencial' : when;
    }

    return BnTabScaffold(
      tab: BnTab.home,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BnNavBar(backLabel: 'Inicio'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: const Text('Conversor', style: BnType.largeTitle)),
                    const SizedBox(height: 6),
                    _ServiceStatus(down: down),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _ConversionCard(
                  from: _from,
                  to: _to,
                  amount: _amount,
                  result: factor == null ? '—' : BnFormat.money(amount * factor, symbol: _to.symbol),
                  resultOpacity: loading ? 0.4 : (down ? 0.6 : 1),
                  turns: _turns,
                  onPickFrom: () => _pick(_Side.from),
                  onPickTo: () => _pick(_Side.to),
                  onSwap: _swap,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _RateCard(
                  rateText: '1 ${_from.code} = ${factor == null ? '—' : _formatRate(factor)} ${_to.code}',
                  updated: updated,
                  busy: loading,
                  onRefresh: _load,
                ),
              ),
              if (down)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: BnRise(
                    duration: const Duration(milliseconds: 300),
                    offset: 6,
                    child: _ServiceDown(onRetry: _load),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Text(
                  'Valores referenciales provistos por un servicio externo. El tipo de cambio final se confirma al realizar la operación.',
                  style: TextStyle(fontFamily: BnType.family, fontSize: 13, height: 1.45, color: BnColors.texto3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceStatus extends StatelessWidget {
  const _ServiceStatus({required this.down});

  final bool down;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: down ? BnColors.precaucionPunto : BnColors.positivoPunto,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                down ? 'Servicio externo con intermitencias' : 'Servicio de tipo de cambio conectado',
                style: const TextStyle(fontFamily: BnType.family, fontSize: 13, color: BnColors.texto2),
              ),
            ),
          ],
        ),
      );
}

class _ConversionCard extends StatelessWidget {
  const _ConversionCard({
    required this.from,
    required this.to,
    required this.amount,
    required this.result,
    required this.resultOpacity,
    required this.turns,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSwap,
  });

  final _Currency from;
  final _Currency to;
  final TextEditingController amount;
  final String result;
  final double resultOpacity;
  final int turns;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onSwap;

  static final _swapIcon = bnLine('<path d="M8 4v16M8 4 4 8M8 4l4 4"/><path d="M16 20V4M16 20l-4-4M16 20l4-4"/>', stroke: 1.8);

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Conversión',
        container: true,
        child: Stack(
          children: [
            BnCard(
              radius: 20,
              child: Column(
                children: [
                  _CurrencyBlock(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
                    label: 'Tienes',
                    currency: from,
                    chipBackground: BnColors.grafito,
                    chipForeground: BnColors.blancoCalido,
                    semanticPrefix: 'Moneda de origen',
                    onPick: onPickFrom,
                    value: TextField(
                      controller: amount,
                      textAlign: TextAlign.right,
                      style: _amountStyle,
                      cursorColor: BnColors.brandNaranjaBi,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      decoration: InputDecoration.collapsed(hintText: '0', hintStyle: _amountStyle.copyWith(color: BnColors.piedra)),
                    ),
                  ),
                  const ColoredBox(color: BnColors.relleno, child: SizedBox(height: 1, width: double.infinity)),
                  _CurrencyBlock(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
                    label: 'Recibirías',
                    currency: to,
                    chipBackground: BnColors.brandNaranjaTinte,
                    chipForeground: BnColors.brandNaranjaTexto,
                    semanticPrefix: 'Moneda de destino',
                    onPick: onPickTo,
                    value: Semantics(
                      liveRegion: true,
                      child: AnimatedOpacity(
                        opacity: resultOpacity,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.ease,
                        child: Text(
                          result,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: _amountStyle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Center(
                child: BnPressable(
                  onTap: onSwap,
                  scale: _press,
                  semanticLabel: 'Intercambiar monedas',
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: BnColors.superficie,
                      shape: BoxShape.circle,
                      border: Border.all(color: BnColors.hairline),
                      boxShadow: const [BoxShadow(color: Color(0x0F141518), blurRadius: 2, offset: Offset(0, 1))],
                    ),
                    child: AnimatedRotation(
                      turns: turns * 0.5,
                      duration: const Duration(milliseconds: 300),
                      curve: BnMotion.entrada,
                      child: BnSvg(_swapIcon, size: 20, color: BnColors.carbon),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _CurrencyBlock extends StatelessWidget {
  const _CurrencyBlock({
    required this.padding,
    required this.label,
    required this.currency,
    required this.chipBackground,
    required this.chipForeground,
    required this.semanticPrefix,
    required this.onPick,
    required this.value,
  });

  final EdgeInsets padding;
  final String label;
  final _Currency currency;
  final Color chipBackground;
  final Color chipForeground;
  final String semanticPrefix;
  final VoidCallback onPick;
  final Widget value;

  static final _chevron = bnLine('<path d="M6 9l6 6 6-6"/>', stroke: 2.2);
  static const _caption = TextStyle(fontFamily: BnType.family, fontSize: 13, color: BnColors.texto3);

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: _caption),
            const SizedBox(height: 8),
            Row(
              children: [
                BnPressable(
                  onTap: onPick,
                  scale: _press,
                  semanticLabel: '$semanticPrefix: ${currency.name}',
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
                    decoration: BoxDecoration(
                      color: BnColors.blancoCalido,
                      border: Border.all(color: BnColors.hairline),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: chipBackground, shape: BoxShape.circle),
                          child: Text(
                            currency.symbol,
                            style: TextStyle(fontFamily: BnType.family, fontSize: 13, fontWeight: FontWeight.w600, color: chipForeground),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currency.code,
                          style: const TextStyle(fontFamily: BnType.family, fontSize: 16, fontWeight: FontWeight.w600, color: BnColors.carbon),
                        ),
                        const SizedBox(width: 8),
                        BnSvg(_chevron, size: 14, color: BnColors.carbon),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: value),
              ],
            ),
            const SizedBox(height: 6),
            Text(currency.name, textAlign: TextAlign.right, style: _caption),
          ],
        ),
      );
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.rateText, required this.updated, required this.busy, required this.onRefresh});

  final String rateText;
  final String updated;
  final bool busy;
  final VoidCallback onRefresh;

  static const _label = TextStyle(fontFamily: BnType.family, fontSize: 15, color: BnColors.texto2);

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Tipo de cambio',
        container: true,
        child: BnCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 52),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: BnColors.relleno))),
                child: Row(
                  children: [
                    const Text('Tipo de cambio', style: _label),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rateText,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: BnType.family,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: BnColors.carbon,
                          fontFeatures: BnType.tabular,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Row(
                  children: [
                    const Text('Actualizado', style: _label),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        updated,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: BnType.family,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: BnColors.carbon,
                          fontFeatures: BnType.tabular,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _RefreshButton(busy: busy, onTap: onRefresh),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}


class _RefreshButton extends StatefulWidget {
  const _RefreshButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton> with SingleTickerProviderStateMixin {
  static final _icon = bnLine('<path d="M20 11a8 8 0 1 0-2.3 5.7"/><path d="M20 5v6h-6"/>', stroke: 1.8);

  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_RefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busy != widget.busy) _sync();
  }

  void _sync() {
    if (widget.busy) {
      _spin.repeat();
    } else {
      _spin
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Actualizar tipo de cambio',
        button: true,
        enabled: !widget.busy,
        excludeSemantics: true,
        child: BnPressable(
          onTap: widget.busy ? null : widget.onTap,
          scale: _press,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: RotationTransition(
                turns: bnReduceMotion(context) ? const AlwaysStoppedAnimation(0) : _spin,
                child: BnSvg(_icon, size: 18, color: BnColors.texto2),
              ),
            ),
          ),
        ),
      );
}

class _ServiceDown extends StatelessWidget {
  const _ServiceDown({required this.onRetry});

  final VoidCallback onRetry;

  static final _warning = bnLine('<path d="M12 4 2.5 20h19z"/><path d="M12 10v4M12 17h.01"/>', stroke: 1.9);

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BnColors.superficie,
            border: Border.all(color: BnColors.hairline),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: BnColors.precaucionFondo, shape: BoxShape.circle),
                child: BnSvg(_warning, size: 18, color: BnColors.precaucion),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No pudimos actualizar el tipo de cambio.',
                      style: TextStyle(fontFamily: BnType.family, fontSize: 15, fontWeight: FontWeight.w600, color: BnColors.carbon),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Mostramos el último valor conocido. El resto de BInova sigue funcionando.',
                      style: TextStyle(fontFamily: BnType.family, fontSize: 14, height: 1.45, color: BnColors.texto2),
                    ),
                    const SizedBox(height: 12),
                    BnPressable(
                      onTap: onRetry,
                      scale: _press,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: BnColors.carbon, borderRadius: BorderRadius.circular(10)),
                        child: const Center(
                          widthFactor: 1,
                          child: Text(
                            'Reintentar',
                            style: TextStyle(fontFamily: BnType.family, fontSize: 14, fontWeight: FontWeight.w600, color: BnColors.superficie),
                          ),
                        ),
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


class _CurrencySheet extends StatelessWidget {
  const _CurrencySheet({required this.title, required this.selected});

  final String title;
  final _Currency selected;

  static const _check =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FF9000" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>';

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Seleccionar moneda',
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BnSheetHeader(title: title),
            const SizedBox(height: 12),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: BnColors.hairline),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        for (var i = 0; i < _currencies.length; i++)
                          _option(context, _currencies[i], divider: i > 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _option(BuildContext context, _Currency c, {required bool divider}) {
    final isSelected = c.code == selected.code;
    return Semantics(
      selected: isSelected,
      child: BnRowPressable(
        onTap: () {
          BnHaptics.tap();
          Navigator.of(context).pop(c);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: divider ? const Border(top: BorderSide(color: BnColors.relleno)) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: BnColors.blancoCalido, shape: BoxShape.circle),
                child: Text(
                  c.symbol,
                  style: const TextStyle(fontFamily: BnType.family, fontSize: 13, fontWeight: FontWeight.w600, color: BnColors.carbon),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.code, style: const TextStyle(fontFamily: BnType.family, fontSize: 16, fontWeight: FontWeight.w500, color: BnColors.carbon)),
                    Text(c.name, style: const TextStyle(fontFamily: BnType.family, fontSize: 13, color: BnColors.texto3)),
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 12),
                const BnSvg(_check, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
