import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/accounts_controller.dart';
import '../../../../app/routing/app_router.dart';
import '../../../../core/design_system/binova_widgets.dart';
import '../../domain/entities/insights.dart';
import '../providers/insights_controller.dart';
import '../widgets/insights_states.dart';
import '../widgets/insights_trend_chart.dart';

enum _Period { semana, mes, anio }

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  _Period _period = _Period.mes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InsightsController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InsightsController>();
    final insights = controller.insights;
    final loading = controller.status == InsightsStatus.idle ||
        controller.status == InsightsStatus.loading;

    final Widget body;
    if (insights == null && loading) {
      body = const SliverToBoxAdapter(child: InsightsSkeleton());
    } else if (insights == null) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: InsightsMessageState(
            glyph: _Glyphs.alert,
            title: controller.errorMessage ?? 'No pudimos cargar tus insights.',
            message: 'Revisa tu conexión e inténtalo de nuevo.',
            actionLabel: 'Reintentar',
            onAction: controller.load,
          ),
        ),
      );
    } else if (controller.status == InsightsStatus.empty) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: InsightsMessageState(
            glyph: _Glyphs.bars,
            title: 'Aún no hay suficientes movimientos.',
            message:
                'Cuando uses tus cuentas, verás aquí en qué gastas cada mes.',
          ),
        ),
      );
    } else {
      final data =
          _InsightsView.from(insights, controller.fetchedAt ?? DateTime.now());
      body = SliverToBoxAdapter(
        child: _Content(
          // Re-keyed per snapshot so the bars grow again after a refresh.
          key: ValueKey(controller.fetchedAt),
          data: data,
          offline: controller.status == InsightsStatus.offlineStale,
          fetchedAt: controller.fetchedAt,
          onRetry: controller.load,
        ),
      );
    }

    return BnTabScaffold(
      tab: BnTab.insights,
      onRefresh: insights == null ? null : controller.load,
      slivers: [
        SliverToBoxAdapter(
          child: _Header(
              period: _period, onPeriod: (p) => setState(() => _period = p)),
        ),
        body,
      ],
    );
  }
}

abstract final class _Glyphs {
  static final calendar = bnLine(
      '<rect x="3.5" y="5" width="17" height="15.5" rx="2.5"/><path d="M3.5 10h17M8 3v4M16 3v4"/>');
  static final up =
      bnLine('<path d="M7 17 17 7"/><path d="M9 7h8v8"/>', stroke: 2);
  static final down =
      bnLine('<path d="M7 7l10 10"/><path d="M17 9v8H9"/>', stroke: 2);
  static final trend =
      bnLine('<path d="M3 17l6-6 4 4 8-8"/><path d="M15 7h6v6"/>', stroke: 1.8);
  static final bars = bnLine(
      '<path d="M3 20h18"/><path d="M6 16v-5"/><path d="M11 16V6"/><path d="M16 16v-8"/>',
      stroke: 1.5);
  static final alert = bnLine(
      '<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5M12 16.5h.01"/>',
      stroke: 1.5);
}

/// Toolbar (calendar button), large title and the period segmented control.
class _Header extends StatelessWidget {
  const _Header({required this.period, required this.onPeriod});

  final _Period period;
  final ValueChanged<_Period> onPeriod;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerRight,
            child: BnPressable(
              semanticLabel: 'Elegir periodo',
              onTap: () {},
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                    child: BnSvg(_Glyphs.calendar,
                        size: 22, color: BnColors.carbon)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: const Text('Insights',
                      style: TextStyle(
                          fontFamily: BnType.family,
                          fontSize: 34,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1.19,
                          color: BnColors.carbon)),
                ),
                const SizedBox(height: 16),
                _PeriodSegmented(value: period, onChanged: onPeriod),
              ],
            ),
          ),
        ],
      );
}

/// `role="tablist"` segmented control: `#EBE9E4` track, `.seg` 220 ms ease.
class _PeriodSegmented extends StatelessWidget {
  const _PeriodSegmented({required this.value, required this.onChanged});

  static const _items = [
    (_Period.semana, 'Semana'),
    (_Period.mes, 'Mes'),
    (_Period.anio, 'Año')
  ];

  final _Period value;
  final ValueChanged<_Period> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: BnColors.rellenoCampo,
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(child: _segment(_items[i].$1, _items[i].$2)),
            ],
          ],
        ),
      );

  Widget _segment(_Period key, String label) {
    final selected = key == value;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!selected) onChanged(key);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.ease,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? BnColors.superficie : const Color(0x00FFFFFF),
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? const [
                    BoxShadow(
                        color: Color(0x1A141518),
                        blurRadius: 3,
                        offset: Offset(0, 1))
                  ]
                : const [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: BnType.family,
              fontSize: 14,
              color: BnColors.carbon,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content(
      {required this.data,
      required this.offline,
      required this.fetchedAt,
      required this.onRetry,
      super.key});

  final _InsightsView data;
  final bool offline;
  final DateTime? fetchedAt;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offline)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child:
                  InsightsOfflineBanner(fetchedAt: fetchedAt, onRetry: onRetry),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: _Total(data: data),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: InsightsTrendChart(points: data.trend, symbol: data.symbol),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: _Categories(data: data),
          ),
          if (data.observations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: _Observations(items: data.observations),
            ),
        ],
      );
}

class _Total extends StatelessWidget {
  const _Total({required this.data});

  final _InsightsView data;

  @override
  Widget build(BuildContext context) {
    final (integer, decimals) =
        BnFormat.moneyParts(data.expense, symbol: data.symbol);
    final change = data.change;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gastos de este mes',
            style: TextStyle(
                fontFamily: BnType.family,
                fontSize: 14,
                color: BnColors.texto2)),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: integer),
            TextSpan(
                text: decimals,
                style: const TextStyle(fontSize: 24, color: BnColors.texto4)),
          ]),
          style: BnType.saldo,
        ),
        if (change != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              BnSvg(change < 0 ? _Glyphs.down : _Glyphs.up,
                  size: 15, color: BnColors.texto2),
              const SizedBox(width: 6),
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text:
                        '${change < 0 ? BnFormat.minus : '+'}${change.abs().round()}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: BnColors.carbon,
                        fontFeatures: BnType.tabular),
                  ),
                  const TextSpan(text: ' vs. mes anterior'),
                ]),
                style: const TextStyle(
                    fontFamily: BnType.family,
                    fontSize: 14,
                    color: BnColors.texto2),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.data});

  final _InsightsView data;

  @override
  Widget build(BuildContext context) {
    final slices = data.slices;
    final summary = slices.map((s) => '${s.label} ${s.pctLabel}').join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
            header: true,
            child: const Text('Por categoría', style: BnType.tituloSeccion)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BnColors.superficie,
            border: Border.all(color: BnColors.hairline),
            borderRadius: BorderRadius.circular(BnRadius.cardGrande),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: 'Distribución: $summary',
                image: true,
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      for (var i = 0; i < slices.length; i++) ...[
                        if (i > 0) const SizedBox(width: 3),
                        Expanded(
                          flex: (slices[i].pct * 100).round().clamp(1, 1 << 20),
                          child: Container(
                            decoration: BoxDecoration(
                                color: slices[i].color,
                                borderRadius: BorderRadius.circular(5)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < slices.length; i++)
                _CategoryRow(
                    slice: slices[i], symbol: data.symbol, divider: i > 0),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow(
      {required this.slice, required this.symbol, required this.divider});

  final _Slice slice;
  final String symbol;
  final bool divider;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
            border: divider
                ? const Border(top: BorderSide(color: BnColors.relleno))
                : null),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: slice.color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(slice.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: BnType.family,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: BnColors.carbon)),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 40,
              child: Text(slice.pctLabel,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontFamily: BnType.family,
                      fontSize: 13,
                      color: BnColors.texto3,
                      fontFeatures: BnType.tabular)),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: Text(
                BnFormat.money(slice.amount, symbol: symbol),
                textAlign: TextAlign.right,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                    fontFamily: BnType.family,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: BnColors.carbon,
                    fontFeatures: BnType.tabular),
              ),
            ),
          ],
        ),
      );
}

class _Observations extends StatelessWidget {
  const _Observations({required this.items});

  final List<_Observation> items;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
              header: true,
              child: const Text('Lo que vemos', style: BnType.tituloSeccion)),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _ObservationCard(item: items[i]),
          ],
        ],
      );
}

class _ObservationCard extends StatelessWidget {
  const _ObservationCard({required this.item});

  final _Observation item;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BnColors.superficie,
          border: Border.all(color: BnColors.hairline),
          borderRadius: BorderRadius.circular(BnRadius.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BnIconTile(
                svg: item.glyph,
                size: 36,
                iconSize: 18,
                circle: true,
                background: item.tint,
                color: item.ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.text,
                      style: const TextStyle(
                          fontFamily: BnType.family,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          color: BnColors.carbon)),
                  if (item.detail != null) ...[
                    const SizedBox(height: 4),
                    Text(item.detail!,
                        style: const TextStyle(
                            fontFamily: BnType.family,
                            fontSize: 14,
                            color: BnColors.texto2)),
                  ],
                  if (item.link != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: BnPressable(
                        onTap: () => _openMovements(context),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 32),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: 1,
                            child: Text(
                              item.link!,
                              style: const TextStyle(
                                fontFamily: BnType.family,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: BnColors.carbon,
                                decoration: TextDecoration.underline,
                                decorationColor: BnColors.lineaFuerte,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// View data derived from the monthly [Insights] snapshot.

class _Slice {
  const _Slice(
      {required this.label,
      required this.svg,
      required this.amount,
      required this.pct,
      required this.color});

  final String label;
  final String svg;
  final double amount;
  final double pct;
  final Color color;

  String get pctLabel => '${pct.round()}%';
}

class _Observation {
  const _Observation(
      {required this.glyph,
      required this.tint,
      required this.ink,
      required this.text,
      this.detail,
      this.link});

  final String glyph;
  final Color tint;
  final Color ink;
  final String text;
  final String? detail;
  final String? link;
}

class _InsightsView {
  const _InsightsView({
    required this.symbol,
    required this.expense,
    required this.change,
    required this.trend,
    required this.slices,
    required this.observations,
  });

  /// Legend colors in prototype order (largest category first).
  static const _palette = [
    BnColors.brandNaranjaBi,
    BnColors.carbon,
    BnColors.texto3,
    BnColors.texto5,
    BnColors.lineaFuerte
  ];
  static const _months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic'
  ];

  final String symbol;
  final double expense;
  final double? change;
  final List<InsightsTrendPoint> trend;
  final List<_Slice> slices;
  final List<_Observation> observations;

  factory _InsightsView.from(Insights insights, DateTime at) {
    final symbol = BnFormat.currencySymbol(insights.totalExpense.currency);
    final expense = double.tryParse(insights.totalExpense.amount) ?? 0;
    final income = double.tryParse(insights.totalIncome.amount) ?? 0;
    final change = double.tryParse(insights.comparisonPercentage ?? '');

    // Six-period trend from the API; older APIs only report the current month
    // and its change, so fall back to the two months derivable from it.
    final trend = insights.trend.isNotEmpty
        ? [
            for (var i = 0; i < insights.trend.length; i++)
              InsightsTrendPoint(
                label: _months[insights.trend[i].start.month - 1],
                value:
                    double.tryParse(insights.trend[i].totalExpense.amount) ?? 0,
                current: i == insights.trend.length - 1,
              ),
          ]
        : <InsightsTrendPoint>[
            if (change != null && change > -100)
              InsightsTrendPoint(
                  label: _months[(at.month + 10) % 12],
                  value: expense / (1 + change / 100),
                  current: false),
            InsightsTrendPoint(
                label: _months[at.month - 1], value: expense, current: true),
          ];

    final slices = _slices(insights.categories);
    final top = slices.isEmpty ? null : slices.first;
    final observations = <_Observation>[
      if (top != null)
        _Observation(
          glyph: top.svg,
          tint: BnColors.brandNaranjaTinte,
          ink: BnColors.brandNaranjaTexto,
          text:
              'Tus gastos en ${top.label.toLowerCase()} representan el ${top.pctLabel} de este mes.',
          link: 'Ver mis gastos en ${top.label.toLowerCase()}',
        ),
      if (income > expense)
        _Observation(
          glyph: _Glyphs.trend,
          tint: BnColors.positivoFondo,
          ink: BnColors.positivo,
          text:
              'Este mes has ahorrado ${BnFormat.money(income - expense, symbol: symbol)}.',
          detail: 'Tus ingresos superan a tus gastos del mes.',
        ),
    ];

    return _InsightsView(
      symbol: symbol,
      expense: expense,
      change: change,
      trend: trend,
      slices: slices,
      observations: observations,
    );
  }

  /// Groups API categories by their Spanish label (e.g. food + groceries →
  /// Alimentación) and folds everything past the fourth into «Otros».
  static List<_Slice> _slices(List<InsightCategory> categories) {
    final grouped = <String, ({String svg, double amount, double pct})>{};
    for (final c in categories) {
      final meta = BnCategory.of(c.category);
      final prev = grouped[meta.label];
      grouped[meta.label] = (
        svg: meta.svg,
        amount: (prev?.amount ?? 0) + (double.tryParse(c.amount.amount) ?? 0),
        pct: (prev?.pct ?? 0) + (double.tryParse(c.percentage) ?? 0),
      );
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));
    final limit = _palette.length;
    final kept =
        entries.length > limit ? entries.sublist(0, limit - 1) : entries;
    final rest = entries.length > limit
        ? entries.sublist(limit - 1)
        : const <MapEntry<String, ({String svg, double amount, double pct})>>[];
    return [
      for (var i = 0; i < kept.length; i++)
        _Slice(
            label: kept[i].key,
            svg: kept[i].value.svg,
            amount: kept[i].value.amount,
            pct: kept[i].value.pct,
            color: _palette[i]),
      if (rest.isNotEmpty)
        _Slice(
          label: 'Otros',
          svg: BnGlyphs.shopping,
          amount: rest.fold(0, (s, e) => s + e.value.amount),
          pct: rest.fold(0, (s, e) => s + e.value.pct),
          color: _palette.last,
        ),
    ];
  }
}

/// Opens the movements of the main (first non-credit) account, as the
/// prototype's "Ver mis gastos" link does.
void _openMovements(BuildContext context) {
  final accounts = context.read<AccountsController>().accounts;
  final main = accounts.where((a) => a.type != AccountType.credit).firstOrNull;
  Navigator.of(context).pushNamed(
    main == null ? AppRoute.accounts : AppRoute.transactions,
    arguments: main?.id,
  );
}
