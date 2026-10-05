import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/binova_widgets.dart';
import 'operation_parts.dart';



Future<void> showOperationReceipt(
  BuildContext context, {
  required String title,
  required double amount,
  required List<(String, String)> rows,
}) =>
    showBnSheet<void>(
      context,
      builder: (context) => _Receipt(title: title, amount: amount, rows: rows),
    );

class _Receipt extends StatelessWidget {
  const _Receipt({required this.title, required this.amount, required this.rows});

  final String title;
  final double amount;
  final List<(String, String)> rows;

  Future<void> _share(BuildContext context) async {
    final text = StringBuffer('BInova · $title\n${BnFormat.money(amount)}\n');
    for (final (k, v) in rows) {
      text.writeln('$k: $v');
    }
    await Clipboard.setData(ClipboardData(text: text.toString()));
    BnHaptics.light();
    if (context.mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        physics: bnScrollPhysics,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'BI', style: opStyle(17, weight: FontWeight.w700, letterSpacing: -.51)),
                      TextSpan(text: 'nova', style: opStyle(17, color: BnColors.texto2, letterSpacing: -.51)),
                    ]),
                  ),
                ),
                const BnCloseButton(),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: opStyle(14, color: BnColors.texto2)),
            const SizedBox(height: 2),
            Text(BnFormat.money(amount), style: opStyle(36, weight: FontWeight.w600, letterSpacing: -1.26, tabular: true)),
            const SizedBox(height: 16),
            const CustomPaint(size: Size(double.infinity, 1), painter: _DashedLine()),
            const SizedBox(height: 8),
            for (final (k, v) in rows)
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 38),
                child: OperationDetailRow(label: k, value: v, size: 14),
              ),
            const SizedBox(height: 20),
            BnButton(
              label: 'Compartir comprobante',
              icon: BnSvg(OpGlyphs.share, size: 18, color: BnColors.superficie),
              onTap: () => _share(context),
            ),
          ],
        ),
      );
}


class _DashedLine extends CustomPainter {
  const _DashedLine();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BnColors.lineaFuerte
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, .5), Offset((x + 3).clamp(0, size.width), .5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLine oldDelegate) => false;
}



Future<bool> showCancelOperationSheet(BuildContext context, {required String question}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x00000000),
    transitionDuration: BnMotion.sheet,
    pageBuilder: (context, _, __) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, __) => _CancelSheet(animation: animation, question: question),
  );
  return result ?? false;
}

class _CancelSheet extends StatelessWidget {
  const _CancelSheet({required this.animation, required this.question});

  final Animation<double> animation;
  final String question;

  @override
  Widget build(BuildContext context) {
    final reduce = bnReduceMotion(context);
    final bottom = bnBottomInset(context);
    void close(bool discard) => Navigator.of(context).pop(discard);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {

        final dim = Curves.ease.transform((animation.value * 440 / 300).clamp(0.0, 1.0));
        final slide = BnMotion.springSuave.transform(animation.value);
        return Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                label: 'Seguir',
                button: true,
                child: GestureDetector(
                  onTap: () => close(false),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6 * dim, sigmaY: 6 * dim),
                    child: ColoredBox(color: BnColors.carbon.withOpacity(.28 * dim)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: bottom > 0 ? bottom : 20,
              child: reduce
                  ? Opacity(opacity: animation.value, child: child)
                  : FractionalTranslation(translation: Offset(0, (1 - slide) * 1.4), child: child),
            ),
          ],
        );
      },
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: true,
        label: 'Cancelar operación',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColoredBox(
                color: const Color(0xF5FBFAF8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '$question Se perderán los datos ingresados.',
                        textAlign: TextAlign.center,
                        style: opStyle(13, color: BnColors.texto2, height: 1.45),
                      ),
                    ),
                    BnPressable(
                      onTap: () => close(true),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 56),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: BnColors.hairline))),
                        child: Text('Descartar', style: opStyle(17, weight: FontWeight.w500, color: BnColors.critico)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            BnPressable(
              onTap: () => close(false),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: BnColors.superficie, borderRadius: BorderRadius.circular(16)),
                child: Text('Seguir editando', style: opStyle(17, weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
