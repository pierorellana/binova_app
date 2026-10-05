import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routing/app_router.dart';
import '../../../../core/design_system/binova_widgets.dart';
import '../../../../core/storage/onboarding_store.dart';



class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _steps = <_Step>[
    _Step(
      title: 'Todo tu banco, en un solo lugar.',
      body: 'Cuentas, tarjetas y servicios conectados en una sola experiencia.',
      illustration: _ProductsIllustration(),
    ),
    _Step(
      title: 'Una experiencia que se adapta a ti.',
      body: 'Recomendaciones y accesos que cambian según tus hábitos y metas.',
      illustration: _AdaptiveIllustration(),
    ),
    _Step(
      title: 'Tus finanzas, siempre bajo control.',
      body: 'Entiende en qué gastas y toma mejores decisiones cada mes.',
      illustration: _SpendingIllustration(),
    ),
  ];

  int _step = 0;
  bool _leaving = false;

  bool get _isLast => _step == _steps.length - 1;

  void _go(int step) {
    final target = step.clamp(0, _steps.length - 1);
    if (target != _step) setState(() => _step = target);
  }

  void _onSwipe(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v < -250) _go(_step + 1);
    if (v > 250) _go(_step - 1);
  }

  Future<void> _complete() async {
    if (_leaving) return;
    _leaving = true;
    await context.read<OnboardingStore>().markCompleted();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoute.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final top = bnTopInset(context);
    final step = _steps[_step];
    return BnScreen(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: _onSwipe,
        child: Stack(
          children: [
            Positioned(
              top: top,
              left: 0,
              right: 0,
              height: 44,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _Wordmark(size: 19, nova: BnColors.texto2),
                    BnPressable(
                      onTap: _complete,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        child: Text('Omitir', style: _text(15, color: BnColors.texto2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: top + 61,
              left: 0,
              right: 0,
              bottom: 0,
              child: _PageEnter(
                key: ValueKey<int>(_step),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: SizedBox(width: 390, height: 400, child: step.illustration)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: BnBalancedText(step.title, style: BnType.tituloPantalla.copyWith(letterSpacing: -0.9)),
                          ),
                          const SizedBox(height: 12),
                          Text(step.body, style: _text(16, color: BnColors.texto2, height: 1.45)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 44,
              child: Column(
                children: [
                  Semantics(
                    label: 'Paso ${_step + 1} de ${_steps.length}',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < _steps.length; i++)
                          _Dot(active: i == _step, label: 'Ir al paso ${i + 1}', onTap: () => _go(i)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  BnButton(
                    label: _isLast ? 'Comenzar' : 'Continuar',
                    onTap: _isLast ? _complete : () => _go(_step + 1),
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

TextStyle _text(double size, {FontWeight weight = FontWeight.w400, Color color = BnColors.carbon, double? height, double? spacing, bool tabular = false}) =>
    TextStyle(
      fontFamily: BnType.family,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
      fontFeatures: tabular ? BnType.tabular : null,
    );

class _Step {
  const _Step({required this.title, required this.body, required this.illustration});

  final String title;
  final String body;
  final Widget illustration;
}


class _PageEnter extends StatefulWidget {
  const _PageEnter({required this.child, super.key});

  final Widget child;

  @override
  State<_PageEnter> createState() => _PageEnterState();
}

class _PageEnterState extends State<_PageEnter> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (bnReduceMotion(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final t = BnMotion.entrada.transform(_c.value);
          return Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(16 * (1 - t), 0), child: child),
          );
        },
      );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active, required this.label, required this.onTap});

  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = bnReduceMotion(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: 28,
          child: Center(
            child: AnimatedContainer(
              duration: reduce ? Duration.zero : const Duration(milliseconds: 280),
              curve: BnMotion.entrada,
              width: active ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? BnColors.brandNaranjaBi : BnColors.piedra,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.size, required this.nova, this.bi = BnColors.carbon});

  final double size;
  final Color bi;
  final Color nova;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          style: _text(size, spacing: -0.03 * size),
          children: [
            TextSpan(text: 'BI', style: TextStyle(fontWeight: FontWeight.w700, color: bi)),
            TextSpan(text: 'nova', style: TextStyle(color: nova)),
          ],
        ),
        semanticsLabel: 'BInova',
      );
}

const _soft = [
  BoxShadow(color: Color(0x0A141518), offset: Offset(0, 1), blurRadius: 2),
  BoxShadow(color: Color(0x0F141518), offset: Offset(0, 10), blurRadius: 28),
];





final _bankGlyph = bnLine('<path d="M3 9.5 12 4l9 5.5"/><path d="M5 10v8M9.5 10v8M14.5 10v8M19 10v8"/><path d="M3 20h18"/>');
final _cardGlyph = bnLine('<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M3 10h18"/><path d="M7 15h3"/>');

class _ProductsIllustration extends StatelessWidget {
  const _ProductsIllustration();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Stack(
          children: [
            Positioned(
              left: 48,
              top: 36,
              width: 294,
              height: 176,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: BnColors.grafito, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Saldo total', style: _text(13, color: BnColors.texto5)),
                        const _Wordmark(size: 15, bi: BnColors.blancoCalido, nova: BnColors.texto5),
                      ],
                    ),
                    Text.rich(
                      TextSpan(
                        style: _text(34, weight: FontWeight.w600, color: BnColors.blancoCalido, spacing: -1.02, tabular: true),
                        children: [
                          const TextSpan(text: r'$5,430'),
                          TextSpan(text: '.20', style: _text(20, color: BnColors.texto4, spacing: -0.6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 40,
              top: 186,
              child: _ProductRow(
                glyph: _bankGlyph,
                title: 'Cuenta de ahorros',
                mask: '**** 4821',
                trailing: Text(r'$3,840.20', style: _text(15, weight: FontWeight.w600, tabular: true)),
              ),
            ),
            Positioned(
              left: 44,
              right: 24,
              top: 268,
              child: _ProductRow(
                glyph: _cardGlyph,
                title: 'Tarjeta de crédito',
                mask: '**** 9284',
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(r'$2,180.00', style: _text(15, weight: FontWeight.w600, tabular: true)),
                    Text('Disponible', style: _text(12, color: BnColors.texto3)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.glyph, required this.title, required this.mask, required this.trailing});

  final String glyph;
  final String title;
  final String mask;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: BnColors.superficie, borderRadius: BorderRadius.circular(18), boxShadow: _soft),
        child: Row(
          children: [
            BnIconTile(svg: glyph),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _text(15, weight: FontWeight.w500)),
                  Text(mask, style: _text(13, color: BnColors.texto3, tabular: true)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      );
}





final _trendGlyph = bnLine('<path d="M3 17l6-6 4 4 8-8"/><path d="M15 7h6v6"/>', stroke: 1.8);
final _globeGlyph = bnLine('<circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>', stroke: 1.8);
final _boltGlyph = bnLine('<path d="M13 2 4 14h7l-1 8 9-12h-7z"/>', stroke: 1.8);

class _AdaptiveIllustration extends StatelessWidget {
  const _AdaptiveIllustration();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Stack(
          children: [
            const _Ring(left: 35, top: 30, size: 320, color: Color(0xFFE2DFD9)),
            const _Ring(left: 85, top: 80, size: 220, color: Color(0xFFE2DFD9)),
            const _Ring(left: 135, top: 130, size: 120, color: BnColors.lineaFuerte),
            Positioned(
              left: 163,
              top: 158,
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: BnColors.grafito, shape: BoxShape.circle),
                child: Text('PO', style: _text(18, weight: FontWeight.w600, color: BnColors.blancoCalido)),
              ),
            ),
            Positioned(
              left: 196,
              top: 48,
              child: _Chip(glyph: _trendGlyph, label: 'Ahorro +14%', background: BnColors.positivoFondo, color: BnColors.positivo),
            ),
            Positioned(
              left: 20,
              top: 214,
              child: _Chip(glyph: _globeGlyph, label: 'Tipo de cambio', background: BnColors.brandNaranjaTinte, color: BnColors.brandNaranjaTexto),
            ),
            Positioned(
              left: 214,
              top: 300,
              child: _Chip(glyph: _boltGlyph, label: 'Servicios al día', background: BnColors.relleno, color: BnColors.carbon),
            ),
          ],
        ),
      );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.left, required this.top, required this.size, required this.color});

  final double left;
  final double top;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Positioned(
        left: left,
        top: top,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color)),
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.glyph, required this.label, required this.background, required this.color});

  final String glyph;
  final String label;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: BnColors.superficie, borderRadius: BorderRadius.circular(14), boxShadow: _soft),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BnIconTile(svg: glyph, size: 28, iconSize: 16, circle: true, background: background, color: color),
            const SizedBox(width: 8),
            Text(label, style: _text(13, weight: FontWeight.w500)),
          ],
        ),
      );
}





class _SpendingIllustration extends StatelessWidget {
  const _SpendingIllustration();

  static const _bars = <(String, double)>[('May', 62), ('Jun', 76), ('Jul', 58), ('Ago', 70), ('Sep', 66), ('Oct', 92)];

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Center(
          child: Container(
            width: 318,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: BnColors.superficie, borderRadius: BorderRadius.circular(24), boxShadow: _soft),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gastos de octubre', style: _text(13, color: BnColors.texto3)),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: _text(30, weight: FontWeight.w600, spacing: -0.9, tabular: true),
                    children: [
                      const TextSpan(text: r'$1,240'),
                      TextSpan(text: '.50', style: _text(18, color: BnColors.texto4, spacing: -0.54)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < _bars.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(child: _Bar(label: _bars[i].$1, height: _bars[i].$2, current: i == _bars.length - 1)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: BnColors.relleno))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Presupuesto usado', style: _text(14, color: BnColors.texto2)),
                      Text('62%', style: _text(14, weight: FontWeight.w600, tabular: true)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.height, required this.current});

  final String label;
  final double height;
  final bool current;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: current ? BnColors.brandNaranjaBi : BnColors.hairline,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: _text(11, weight: current ? FontWeight.w600 : FontWeight.w400, color: current ? BnColors.carbon : BnColors.texto3),
          ),
        ],
      );
}
