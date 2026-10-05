import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/binova_widgets.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/money.dart';


abstract final class AccountGlyphs {
  static final cash = bnLine('<rect x="3" y="6" width="18" height="12" rx="2.5"/><circle cx="12" cy="12" r="2.5"/><path d="M6.5 9.5v.01M17.5 14.5v.01"/>');
  static final lock = bnLine('<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8 10.5V7.5a4 4 0 0 1 8 0v3"/>', stroke: 1.9);
  static final plus = bnLine('<path d="M12 5v14M5 12h14"/>', stroke: 1.8);
  static final copy = bnLine('<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/>', stroke: 1.7);
  static final list = bnLine('<path d="M8 6h12M8 12h12M8 18h12"/><path d="M4 6h.01M4 12h.01M4 18h.01"/>');
  static final transfer = bnLine('<path d="M7 17 17 7"/><path d="M9 7h8v8"/>', stroke: 1.7);
  static final share = bnLine('<path d="M12 3v12"/><path d="M8 7l4-4 4 4"/><path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7"/>');
  static final check = bnLine('<path d="M5 12.5l4.5 4.5L19 7.5"/>', stroke: 2.2);
  static final wifiOff = bnLine('<path d="M3 3l18 18"/><path d="M8.5 16.5a5 5 0 0 1 7 0"/><path d="M5 12.5a10 10 0 0 1 4.2-2.4M19 12.5a10 10 0 0 0-3-2"/><path d="M2 8.8A15 15 0 0 1 6.1 6.3M22 8.8A15 15 0 0 0 11 5"/><path d="M12 20h.01"/>', stroke: 1.8);
  static final chevron = BnGlyphs.chevronRight;
}

double parseAmount(String raw) => double.tryParse(raw.replaceAll(',', '')) ?? 0;

String formatMoney(Money money) =>
    BnFormat.money(parseAmount(money.amount), symbol: BnFormat.currencySymbol(money.currency));

String lastDigits(String masked) {
  final digits = masked.replaceAll(RegExp(r'\D'), '');
  return digits.length <= 4 ? digits : digits.substring(digits.length - 4);
}


String shortNumber(String masked) => '**** ${lastDigits(masked)}';


String accountTypeShort(AccountType type) => switch (type) {
      AccountType.savings => 'Ahorros',
      AccountType.current => 'Corriente',
      AccountType.credit => 'Crédito',
    };

String currencyName(String code) => switch (code.toUpperCase()) {
      'USD' => 'Dólares (USD)',
      'EUR' => 'Euros (EUR)',
      _ => code.toUpperCase(),
    };

String holderName(BuildContext context) {
  final name = context.read<AuthController>().session?.user.displayName.trim();
  return name == null || name.isEmpty ? '—' : name;
}


class AccountStatusLabel extends StatelessWidget {
  const AccountStatusLabel({required this.status, this.fontSize = 13, this.iconSize = 14, super.key});

  final AccountStatus status;
  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final (label, color, svg) = switch (status) {
      AccountStatus.active => ('Activa', BnColors.positivo, AccountGlyphs.check),
      AccountStatus.blocked => ('Bloqueada', BnColors.precaucion, AccountGlyphs.lock),
      AccountStatus.closed => ('Cerrada', BnColors.texto3, AccountGlyphs.lock),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BnSvg(svg, size: iconSize, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontFamily: BnType.family, fontSize: fontSize, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }
}



class ProductToast extends StatefulWidget {
  const ProductToast({
    required this.message,
    required this.onDone,
    this.duration = const Duration(milliseconds: 2200),
    this.width,
    super.key,
  });

  final String message;
  final VoidCallback onDone;
  final Duration duration;


  final double? width;

  @override
  State<ProductToast> createState() => _ProductToastState();
}

class _ProductToastState extends State<ProductToast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = BnTabBar.heightOf(context) + 20;
    final pill = Container(
      width: widget.width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xF017181B), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BnSvg(AccountGlyphs.check, size: 16, color: BnColors.blancoCalido),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: BnType.family, fontSize: 14, color: BnColors.blancoCalido),
            ),
          ),
        ],
      ),
    );
    return Positioned(
      left: widget.width == null ? 24 : 0,
      right: widget.width == null ? 24 : 0,
      bottom: bottom,
      child: IgnorePointer(
        child: Semantics(
          liveRegion: true,
          child: AnimatedBuilder(
            animation: _c,
            child: Center(child: pill),
            builder: (context, child) {
              final t = _c.value;
              var opacity = 1.0;
              var dy = 0.0;
              if (t < .12) {
                final p = Curves.ease.transform(t / .12);
                opacity = p;
                dy = 8 * (1 - p);
              } else if (t > .85) {
                opacity = 1 - Curves.ease.transform((t - .85) / .15);
              }
              return Opacity(opacity: opacity, child: Transform.translate(offset: Offset(0, dy), child: child));
            },
          ),
        ),
      ),
    );
  }
}


class ProductOfflineBanner extends StatelessWidget {
  const ProductOfflineBanner({required this.fetchedAt, required this.onRetry, super.key});

  final DateTime? fetchedAt;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: BnColors.superficie,
            border: Border.all(color: BnColors.hairline),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BnIconTile(svg: AccountGlyphs.wifiOff, size: 32, iconSize: 17, circle: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sin conexión.', style: TextStyle(fontFamily: BnType.family, fontSize: 15, fontWeight: FontWeight.w600, color: BnColors.carbon)),
                    const SizedBox(height: 2),
                    const Text(
                      'Mostrando la última información disponible.',
                      style: TextStyle(fontFamily: BnType.family, fontSize: 14, height: 1.4, color: BnColors.texto2),
                    ),
                    if (fetchedAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Última actualización: ${BnFormat.clock12(fetchedAt!)}.',
                        style: const TextStyle(fontFamily: BnType.family, fontSize: 13, color: BnColors.texto3, fontFeatures: BnType.tabular),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Align(
                heightFactor: 1,
                child: BnPressable(
                  onTap: onRetry,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: BnColors.carbon, borderRadius: BorderRadius.circular(10)),
                    child: const Text('Reintentar', style: TextStyle(fontFamily: BnType.family, fontSize: 14, fontWeight: FontWeight.w600, color: BnColors.superficie)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}



class ProductMessageState extends StatelessWidget {
  const ProductMessageState({
    required this.svg,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.actionSvg,
    super.key,
  });

  final String svg;
  final String title;
  final String message;
  final String actionLabel;
  final String? actionSvg;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => BnRise(
        duration: const Duration(milliseconds: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: BnColors.hairline)),
                      ),
                    ),
                    Positioned.fill(
                      left: 14,
                      top: 14,
                      right: 14,
                      bottom: 14,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: BnColors.superficie,
                          border: Border.all(color: BnColors.hairline),
                        ),
                      ),
                    ),
                    BnSvg(svg, size: 28, color: BnColors.texto2),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: BnType.family, fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: -0.38, color: BnColors.carbon),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: BnType.family, fontSize: 15, height: 1.45, color: BnColors.texto2),
              ),
              const SizedBox(height: 24),
              BnPressable(
                onTap: onAction,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: BnColors.superficie,
                    border: Border.all(color: BnColors.lineaFuerte),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (actionSvg != null) ...[
                        BnSvg(actionSvg!, size: 18, color: BnColors.carbon),
                        const SizedBox(width: 8),
                      ],
                      Text(actionLabel, style: const TextStyle(fontFamily: BnType.family, fontSize: 16, fontWeight: FontWeight.w600, color: BnColors.carbon)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}


class DashedBorder extends StatelessWidget {
  const DashedBorder({required this.child, required this.color, this.strokeWidth = 1, this.radius = 16, super.key});

  final Widget child;
  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  Widget build(BuildContext context) => CustomPaint(
        foregroundPainter: _DashedRRectPainter(color: color, strokeWidth: strokeWidth, radius: radius),
        child: child,
      );
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.strokeWidth, required this.radius});

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius - inset),
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final dash = strokeWidth * 3;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash * 2;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth || old.radius != radius;
}



Future<bool> showAccountShareSheet(BuildContext context, Account account) async {
  final copied = await showBnSheet<bool>(
    context,
    builder: (_) => _AccountShareSheet(account: account, holder: holderName(context)),
  );
  return copied ?? false;
}

class _AccountShareSheet extends StatelessWidget {
  const _AccountShareSheet({required this.account, required this.holder});

  final Account account;
  final String holder;

  static const _bank = 'Banco Internacional';
  static const _identification = '[CÉDULA]';

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(
      text: '$_bank\nTitular: $holder\nTipo: ${accountTypeShort(account.type)}\nNúmero: ${account.maskedNumber}',
    ));
    BnHaptics.light();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Banco', _bank, false),
      ('Titular', holder, false),
      ('Tipo', accountTypeShort(account.type), false),
      ('Número', account.maskedNumber, true),
      ('Identificación', _identification, true),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BnSheetHeader(title: 'Compartir datos'),
        const SizedBox(height: 6),
        const Text(
          'Envía estos datos para recibir transferencias.',
          style: TextStyle(fontFamily: BnType.family, fontSize: 14, color: BnColors.texto2),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: BnColors.blancoCalido, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Row(
                  children: [
                    Text(rows[i].$1, style: const TextStyle(fontFamily: BnType.family, fontSize: 15, color: BnColors.texto2)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rows[i].$2,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontFamily: BnType.family,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: BnColors.carbon,
                          fontFeatures: rows[i].$3 ? BnType.tabular : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: BnButton(label: 'Copiar', height: 52, variant: BnButtonVariant.secondary, onTap: () => _copy(context)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BnButton(label: 'Compartir', height: 52, onTap: () => Navigator.of(context).pop(false)),
            ),
          ],
        ),
      ],
    );
  }
}
