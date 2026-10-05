import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';

import '../../../../core/design_system/binova_widgets.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/accounts_controller.dart';
import '../../domain/entities/card.dart';
import '../providers/cards_controller.dart';
import 'card_skin.dart';

abstract final class CardGlyphs {
  static final eye =
      bnLine('<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>');
  static final freeze = bnLine('<path d="M12 3v18M4.2 7.5l15.6 9M4.2 16.5l15.6-9"/>');
  static final limits =
      bnLine('<path d="M4 7h10M18 7h2M4 17h4M12 17h8"/><circle cx="16" cy="7" r="2"/><circle cx="10" cy="17" r="2"/>');
  static final wallet =
      bnLine('<rect x="3" y="6" width="18" height="13" rx="2.5"/><path d="M3 10h18"/><path d="M16 15h2"/>');
  static final swipe = bnLine('<path d="M8 7l-4 5 4 5M16 7l4 5-4 5"/>', stroke: 1.8);
  static final lock = bnLine(
      '<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8 10.5V7.5a4 4 0 0 1 8 0v3"/>',
      stroke: 2);
  static final faceId = bnLine(
    '<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2"/>'
    '<path d="M9 9v1.5M15 9v1.5"/><path d="M12 9v4h-1"/><path d="M9.5 16a4 4 0 0 0 5 0"/>',
  );
  static final plus = bnLine('<path d="M12 5v14M5 12h14"/>', stroke: 2);
}


class CardRise extends StatelessWidget {
  const CardRise({required this.child, this.delay = 0, super.key});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) => BnRise(
        delay: Duration(milliseconds: delay),
        duration: const Duration(milliseconds: 380),
        offset: 10,
        child: child,
      );
}



class CardFillScroll extends StatelessWidget {
  const CardFillScroll({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: IntrinsicHeight(child: child),
          ),
        ),
      );
}




mixin CardWalletMixin<T extends StatefulWidget> on State<T> {
  final List<String> walletOrder = <String>[];
  bool walletFlipped = false;
  final Map<String, Card> _updated = <String, Card>{};
  final Map<String, bool> _optimisticFrozen = <String, bool>{};
  ({String message, bool ok, int id})? _toast;


  CardDetailController detailControllerFor(Card card);

  Card latest(Card card) => _updated[card.id] ?? card;

  bool isFrozen(Card card) => _optimisticFrozen[card.id] ?? latest(card).status == CardStatus.frozen;


  void syncWalletOrder(Iterable<String> ids) {
    final present = ids.toList();
    walletOrder
      ..removeWhere((id) => !present.contains(id))
      ..addAll(present.where((id) => !walletOrder.contains(id)));
  }

  void bringToFront(String id) {
    setState(() {
      walletOrder
        ..remove(id)
        ..insert(0, id);
      walletFlipped = false;
    });
    BnHaptics.tap();
  }

  void cycleWallet(int dir) {
    if (walletOrder.length < 2) return;
    setState(() {
      if (dir > 0) {
        walletOrder.add(walletOrder.removeAt(0));
      } else {
        walletOrder.insert(0, walletOrder.removeLast());
      }
      walletFlipped = false;
    });
    BnHaptics.tap();
  }

  void toggleFlip() {
    setState(() => walletFlipped = !walletFlipped);
    BnHaptics.tap();
  }

  void showCardToast(String message, {bool ok = true}) =>
      setState(() => _toast = (message: message, ok: ok, id: (_toast?.id ?? 0) + 1));

  Future<void> toggleFreeze(Card card) async {
    final controller = detailControllerFor(card);
    if (controller.isUpdatingState) return;
    final current = latest(card);
    final wasFrozen = isFrozen(current);
    controller.card = current;
    setState(() => _optimisticFrozen[card.id] = !wasFrozen);
    BnHaptics.light();
    final title = CardSkin.of(current).title;
    showCardToast(wasFrozen ? '$title activa de nuevo' : '$title congelada');
    await controller.toggleFreeze();
    if (!mounted) return;
    setState(() {
      _optimisticFrozen.remove(card.id);
      final updated = controller.card;
      if (controller.actionError == null && updated != null) _updated[card.id] = updated;
    });
    if (controller.actionError != null) {
      BnHaptics.error();
      showCardToast(controller.actionError!, ok: false);
    }
  }

  Future<void> openLimits(Card card) async {
    final controller = detailControllerFor(card);
    await controller.loadLimits();
    if (!mounted) return;
    if (controller.limits == null) {
      showCardToast(controller.actionError ?? 'No pudimos cargar los límites.', ok: false);
      return;
    }
    await showBnSheet<void>(
      context,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      builder: (_) => CardLimitsSheet(card: latest(card), controller: controller),
    );
  }

  Future<void> addToWallet(Card card) async {
    final controller = detailControllerFor(card);
    await controller.provisionWallet();
    if (!mounted) return;
    if (controller.actionError != null) {
      showCardToast(controller.actionError!, ok: false);
    } else {
      BnHaptics.light();
      showCardToast('${CardSkin.of(latest(card)).title} agregada a Wallet');
    }
  }


  Widget buildCardToast() {
    final toast = _toast;


    if (toast == null) return const Positioned(left: 0, top: 0, child: SizedBox.shrink());
    return Positioned(
      left: 24,
      right: 24,
      bottom: 112,
      child: CardToast(
        key: ValueKey(toast.id),
        message: toast.message,
        ok: toast.ok,
        onDone: () {
          if (mounted && _toast?.id == toast.id) setState(() => _toast = null);
        },
      ),
    );
  }
}


String? _creditAvailable(BuildContext context) {
  final credit = context
      .watch<AccountsController>()
      .accounts
      .where((a) => a.type == AccountType.credit)
      .firstOrNull;
  final amount = double.tryParse(credit?.availableBalance.amount ?? '');
  if (credit == null || amount == null) return null;
  return 'Disponible ${BnFormat.money(amount, symbol: BnFormat.currencySymbol(credit.currency))}';
}



class CardWalletPanel extends StatelessWidget {
  const CardWalletPanel({
    required this.card,
    required this.frozen,
    required this.flipped,
    required this.onFlip,
    required this.onFreeze,
    required this.onLimits,
    required this.onWallet,
    required this.onDone,
    this.createdMessage,
    this.offline = false,
    super.key,
  });

  final Card card;
  final bool frozen;
  final bool flipped;
  final VoidCallback onFlip;
  final VoidCallback onFreeze;
  final VoidCallback onLimits;
  final VoidCallback onWallet;
  final VoidCallback onDone;
  final String? createdMessage;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final skin = CardSkin.of(card);
    final sub = card.type == CardType.credit ? _creditAvailable(context) ?? skin.sub : skin.sub;
    final (statusText, statusColor, statusIcon) = frozen
        ? ('Bloqueada temporalmente', BnColors.precaucion, CardGlyphs.lock)
        : switch (card.status) {
            CardStatus.pending => ('Pendiente', BnColors.precaucion, BnGlyphs.clock),
            CardStatus.blocked => ('Bloqueada', BnColors.critico, CardGlyphs.lock),
            _ => ('Activa', BnColors.positivo, BnGlyphs.check),
          };
    final canFreeze = card.status == CardStatus.active || card.status == CardStatus.frozen;
    return CardFillScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (createdMessage != null)
            CardRise(child: _Notice(icon: BnGlyphs.check, text: createdMessage!, color: BnColors.positivo))
          else if (offline)
            CardRise(
              child: _Notice(
                icon: BnGlyphs.clock,
                text: 'Sin conexión · mostrando la última información disponible.',
                color: BnColors.precaucion,
              ),
            ),
          CardRise(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CardSkin.of(card).title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BnType.tituloResultado,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '•••• ${cardLast4(card.maskedPan)}${sub == null ? '' : ' · $sub'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: BnType.family,
                          fontSize: 14,
                          color: BnColors.texto2,
                          fontFeatures: BnType.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BnSvg(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                          fontFamily: BnType.family, fontSize: 13, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          CardRise(
            delay: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RoundAction(icon: CardGlyphs.eye, label: flipped ? 'Ocultar' : 'Ver datos', onTap: onFlip),
                const SizedBox(width: 8),
                _RoundAction(
                    icon: CardGlyphs.freeze,
                    label: frozen ? 'Descongelar' : 'Congelar',
                    onTap: canFreeze ? onFreeze : null),
                const SizedBox(width: 8),
                _RoundAction(icon: CardGlyphs.limits, label: 'Límites', onTap: onLimits),
                const SizedBox(width: 8),
                _RoundAction(icon: CardGlyphs.wallet, label: 'A Wallet', onTap: onWallet),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CardRise(
            delay: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BnSvg(CardGlyphs.swipe, size: 16, color: BnColors.texto3),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Toca una tarjeta o desliza para cambiar',
                    style: TextStyle(fontFamily: BnType.family, fontSize: 13, color: BnColors.texto3),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          CardRise(delay: 180, child: BnButton(label: 'Listo', onTap: onDone)),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.color});

  final String icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              BnSvg(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(fontFamily: BnType.family, fontSize: 13, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
        ),
      );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.label, required this.onTap});

  final String icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: BnPressable(
          onTap: onTap,
          semanticLabel: label,
          child: Opacity(
            opacity: onTap == null ? .4 : 1,
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BnColors.superficie,
                    shape: BoxShape.circle,
                    border: Border.all(color: BnColors.hairline),
                  ),
                  child: BnSvg(icon, size: 21, color: BnColors.carbon),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                      fontFamily: BnType.family, fontSize: 12, fontWeight: FontWeight.w500, color: BnColors.carbon),
                ),
              ],
            ),
          ),
        ),
      );
}


class CardToast extends StatefulWidget {
  const CardToast({required this.message, required this.onDone, this.ok = true, super.key});

  final String message;
  final bool ok;
  final VoidCallback onDone;

  @override
  State<CardToast> createState() => _CardToastState();
}

class _CardToastState extends State<CardToast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..forward().whenComplete(() => widget.onDone());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final v = _c.value;
          double opacity;
          var dy = 0.0;
          if (v < .12) {
            final t = Curves.ease.transform(v / .12);
            opacity = t;
            dy = 8 * (1 - t);
          } else if (v < .85) {
            opacity = 1;
          } else {
            opacity = 1 - Curves.ease.transform((v - .85) / .15);
          }
          return Opacity(opacity: opacity, child: Transform.translate(offset: Offset(0, dy), child: child));
        },
        child: Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xF017181B), borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.ok) ...[
                  BnSvg(BnGlyphs.check, size: 14, color: BnColors.blancoCalido),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: BnType.family, fontSize: 14, color: BnColors.blancoCalido),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}



class CardLimitsSheet extends StatefulWidget {
  const CardLimitsSheet({required this.card, required this.controller, super.key});

  final Card card;
  final CardDetailController controller;

  @override
  State<CardLimitsSheet> createState() => _CardLimitsSheetState();
}

class _CardLimitsSheetState extends State<CardLimitsSheet> {
  late final CardLimits _limits = widget.controller.limits!;
  late final TextEditingController _purchase = TextEditingController(text: _limits.dailyPurchaseLimit.amount);
  late final TextEditingController _withdrawal = TextEditingController(text: _limits.dailyWithdrawalLimit.amount);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _purchase.dispose();
    _withdrawal.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    final changed = _purchase.text.trim() != _limits.dailyPurchaseLimit.amount ||
        _withdrawal.text.trim() != _limits.dailyWithdrawalLimit.amount;
    if (!changed) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await widget.controller.updateLimits(purchase: _purchase.text.trim(), withdrawal: _withdrawal.text.trim());
    if (!mounted) return;
    if (widget.controller.actionError == null) {
      BnHaptics.success();
      Navigator.of(context).maybePop();
    } else {
      BnHaptics.error();
      setState(() {
        _saving = false;
        _error = widget.controller.actionError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = CardSkin.of(widget.card);
    final rows = <(String, TextEditingController, String)>[
      (
        skin == CardSkin.virtual ? 'Compras en línea' : 'Compras',
        _purchase,
        _limits.dailyPurchaseLimit.currency,
      ),
      if (skin != CardSkin.virtual)
        (
          skin == CardSkin.credit ? 'Avances de efectivo' : 'Retiros en cajero',
          _withdrawal,
          _limits.dailyWithdrawalLimit.currency,
        ),
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BnSheetHeader(title: 'Límites · ${CardSkin.of(widget.card).title}'),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: Listenable.merge([_purchase, _withdrawal]),
            builder: (context, _) {
              final values = rows.map((r) => double.tryParse(r.$2.text) ?? 0).toList();
              final max = values.fold<double>(0, (m, v) => v > m ? v : m);
              return Column(
                children: [
                  for (var i = 0; i < rows.length; i++)
                    _LimitRow(
                      label: rows[i].$1,
                      controller: rows[i].$2,
                      symbol: BnFormat.currencySymbol(rows[i].$3),
                      fraction: max <= 0 ? 0 : values[i] / max,
                    ),
                ],
              );
            },
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(fontFamily: BnType.family, fontSize: 13, color: BnColors.critico),
              ),
            ),
          const SizedBox(height: 20),
          BnButton(label: 'Listo', loading: _saving, onTap: _done),
        ],
      ),
    );
  }
}

class _LimitRow extends StatefulWidget {
  const _LimitRow({required this.label, required this.controller, required this.symbol, required this.fraction});

  final String label;
  final TextEditingController controller;
  final String symbol;
  final double fraction;

  @override
  State<_LimitRow> createState() => _LimitRowState();
}

class _LimitRowState extends State<_LimitRow> {
  final _focus = FocusNode();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) setState(() => _editing = false);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  static const _value = TextStyle(
    fontFamily: BnType.family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: BnColors.carbon,
    fontFeatures: BnType.tabular,
  );

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(widget.controller.text);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: BnColors.relleno))),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.label,
                    style: const TextStyle(fontFamily: BnType.family, fontSize: 15, color: BnColors.carbon)),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _editing = true),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_editing)
                      IntrinsicWidth(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focus,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.right,
                          style: _value,
                          cursorColor: BnColors.carbon,
                          decoration: const InputDecoration.collapsed(hintText: '0.00'),
                        ),
                      )
                    else
                      Text(amount == null ? widget.controller.text : BnFormat.money(amount, symbol: widget.symbol),
                          style: _value),
                    const Text(
                      ' / día',
                      style: TextStyle(fontFamily: BnType.family, fontSize: 15, color: BnColors.texto3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 6,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: BnColors.relleno, borderRadius: BorderRadius.circular(3)),
            child: FractionallySizedBox(
              widthFactor: widget.fraction.clamp(0.0, 1.0),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: BnColors.carbon, borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class CardsLoadError extends StatelessWidget {
  const CardsLoadError(
      {required this.title, required this.message, required this.actionLabel, required this.onAction, super.key});

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => CardFillScroll(
        child: Column(
          children: [
            CardRise(
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: BnColors.criticoFondo,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEBC9C5)),
                    ),
                    child: BnSvg(BnGlyphs.exclamation, size: 26, color: BnColors.critico),
                  ),
                  const SizedBox(height: 14),
                  Text(title, textAlign: TextAlign.center, style: BnType.tituloSeccion),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontFamily: BnType.family, fontSize: 15, color: BnColors.texto2, height: 1.35),
                  ),
                ],
              ),
            ),
            const Spacer(),
            CardRise(delay: 100, child: BnButton(label: actionLabel, onTap: onAction)),
          ],
        ),
      );
}
