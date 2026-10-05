import 'package:flutter/material.dart';

import '../../../../core/design_system/binova_widgets.dart';
import 'operation_copy.dart';
import 'operation_motion.dart';
import 'operation_parts.dart';



class OperationResultView extends StatelessWidget {
  const OperationResultView({
    required this.copy,
    required this.phase,
    required this.procTitle,
    required this.amount,
    required this.recipientName,
    required this.completedAt,
    required this.available,
    required this.originLabel,
    required this.onDone,
    required this.onReceipt,
    required this.onAgain,
    required this.onMovements,
    required this.onRetry,
    required this.onChange,
    super.key,
  });

  final OperationCopy copy;
  final BnOpPhase phase;
  final String procTitle;
  final double amount;
  final String recipientName;
  final DateTime? completedAt;
  final double? available;
  final String originLabel;
  final VoidCallback onDone;
  final VoidCallback onReceipt;
  final VoidCallback onAgain;
  final VoidCallback? onMovements;
  final VoidCallback onRetry;
  final VoidCallback onChange;

  String get _amount => BnFormat.money(amount);

  @override
  Widget build(BuildContext context) => OperationFadeIn(
        child: ColoredBox(
          color: BnColors.blancoCalido,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, bnTopInset(context), 24, 40),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: bnScrollPhysics,
                      child: Column(
                        children: [
                          Semantics(
                            label: switch (phase) {
                              BnOpPhase.ok => 'Operación completada',
                              BnOpPhase.warn => 'Operación pendiente',
                              BnOpPhase.err => 'Operación no completada',
                              BnOpPhase.proc => 'Procesando operación',
                            },
                            child: BnOperationIndicator(phase: phase),
                          ),
                          const SizedBox(height: 40),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 230),
                            child: KeyedSubtree(key: ValueKey(phase), child: _texts()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (phase != BnOpPhase.proc) KeyedSubtree(key: ValueKey('a$phase'), child: _actions()),
              ],
            ),
          ),
        ),
      );

  Widget _title(String text, int delay) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: rise(
          Semantics(
            liveRegion: true,
            child: BnBalancedText(text, textAlign: TextAlign.center, style: opStyle(22, weight: FontWeight.w600, letterSpacing: -.44, height: 1.25)),
          ),
          delay,
        ),
      );

  Widget _body(String text, int delay, {double top = 8}) => Padding(
        padding: EdgeInsets.only(top: top),
        child: rise(Text(text, textAlign: TextAlign.center, style: opStyle(15, color: BnColors.texto2, height: 1.35)), delay),
      );

  Widget _texts() => switch (phase) {
        BnOpPhase.proc => Column(
            children: [
              rise(Semantics(
                liveRegion: true,
                child: Text(procTitle, textAlign: TextAlign.center, style: opStyle(22, weight: FontWeight.w600, letterSpacing: -.44)),
              )),
              _body('Esto puede tomar unos segundos. No cierres la app.', 80),
              Padding(
                padding: const EdgeInsets.only(top: 28),
                child: rise(Text('$_amount · $recipientName', style: opStyle(14, color: BnColors.texto3, tabular: true)), 160),
              ),
            ],
          ),
        BnOpPhase.ok => Column(
            children: [
              rise(OperationStatusLabel(icon: BnGlyphs.check, label: 'Completada', color: BnColors.positivo), 420),
              _title(copy.okTitle, 480),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: rise(
                  BnCountUp(
                    value: amount,
                    delay: const Duration(milliseconds: 480),
                    builder: (context, v) =>
                        Text(BnFormat.money(v), style: opStyle(44, weight: FontWeight.w600, letterSpacing: -1.76, tabular: true)),
                  ),
                  520,
                ),
              ),
              _body(copy.okBody, 600),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: rise(
                  Text(
                    completedAt == null ? recipientName : '$recipientName · ${BnFormat.relativeDay(completedAt!.toLocal())}',
                    textAlign: TextAlign.center,
                    style: opStyle(13, color: BnColors.texto3, tabular: true),
                  ),
                  660,
                ),
              ),
            ],
          ),
        BnOpPhase.warn => Column(
            children: [
              rise(OperationStatusLabel(icon: BnGlyphs.clock, label: 'Pendiente', color: BnColors.precaucion), 420),
              _title(copy.warnTitle, 480),
              _body(copy.warnBody, 540),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: rise(
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: BnColors.superficie,
                      border: Border.all(color: BnColors.hairline),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '$_amount reservados', style: opStyle(14, weight: FontWeight.w600, height: 1.45, tabular: true)),
                        const TextSpan(text: ' de tu cuenta de ahorros. No repitas la operación: te avisaremos apenas se confirme.'),
                      ]),
                      style: opStyle(14, color: const Color(0xFF3A3936), height: 1.45),
                    ),
                  ),
                  600,
                ),
              ),
            ],
          ),
        BnOpPhase.err => Column(
            children: [
              rise(
                  OperationStatusLabel(
                      icon: BnGlyphs.exclamation.replaceAll('stroke-width="2.4"', 'stroke-width="2.2"'),
                      label: 'No completada',
                      color: BnColors.critico),
                  420),
              _title(copy.errTitle, 480),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: rise(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: BnColors.superficie,
                      border: Border.all(color: BnColors.hairline),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BnSvg(OpGlyphs.shieldCheck, size: 20, color: BnColors.positivo),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(text: 'Tu dinero no fue debitado.', style: opStyle(15, weight: FontWeight.w600, height: 1.4)),
                              if (available != null)
                                TextSpan(
                                  text: '\nTu saldo sigue en ${BnFormat.money(available!)}.',
                                  style: opStyle(15, color: BnColors.texto2, height: 1.4, tabular: true),
                                ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  560,
                ),
              ),
            ],
          ),
      };

  Widget _pair(Widget a, Widget b) => Row(children: [Expanded(child: a), const SizedBox(width: 10), Expanded(child: b)]);

  Widget _secondary(String label, VoidCallback onTap) =>
      BnButton(label: label, onTap: onTap, variant: BnButtonVariant.secondary, height: 50);

  Widget _actions() => rise(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: switch (phase) {
            BnOpPhase.ok => [
                BnButton(label: 'Listo', onTap: onDone),
                const SizedBox(height: 10),
                _pair(_secondary('Ver comprobante', onReceipt), _secondary(copy.again, onAgain)),
              ],
            BnOpPhase.warn => [
                BnButton(label: 'Entendido', onTap: onDone),
                if (onMovements != null) ...[
                  const SizedBox(height: 10),
                  BnButton(
                      label: 'Ver estado en movimientos', onTap: onMovements, variant: BnButtonVariant.ghost, height: 50, fontSize: 16),
                ],
              ],
            _ => [
                BnButton(label: 'Reintentar', onTap: onRetry),
                const SizedBox(height: 10),
                _pair(_secondary(copy.change, onChange), _secondary('Volver a $originLabel', onDone)),
              ],
          },
        ),
        700,
      );
}
