import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';

import '../../../../app/routing/app_router.dart';
import '../../../../core/design_system/binova_widgets.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/accounts_controller.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/card.dart';
import '../../domain/repositories/card_repository.dart';
import '../providers/cards_controller.dart';
import '../widgets/card_skin.dart';
import '../widgets/card_stack.dart';
import '../widgets/card_wallet.dart';

String _holderName(BuildContext context) =>
    (context.read<AuthController>().session?.user.displayName ?? '').toUpperCase();

/// Back to the screen that opened the wallet (Productos by default).
void _leave(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
  } else {
    navigator.pushReplacementNamed(AppRoute.accounts);
  }
}

/// "Tus tarjetas": interactive 3D stack + wallet panel (canvas `modo: ver`).
class CardsPage extends StatefulWidget {
  const CardsPage({this.focus, super.key});

  /// Card brought to the front on open: a card id or a type name
  /// (`credit`, `debit`, `virtual`), like the canvas `cardsFront`.
  final String? focus;

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> with CardWalletMixin {
  final _detail = <String, CardDetailController>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CardsController>().load();
    });
  }

  @override
  void dispose() {
    for (final c in _detail.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _focused = false;

  void _applyFocus(List<Card> cards) {
    final focus = widget.focus;
    if (_focused || focus == null || cards.isEmpty) return;
    _focused = true;
    final match = cards.where((c) => c.id == focus || c.type.name == focus).firstOrNull;
    if (match == null) return;
    walletOrder
      ..remove(match.id)
      ..insert(0, match.id);
  }

  @override
  CardDetailController detailControllerFor(Card card) =>
      _detail.putIfAbsent(card.id, () => CardDetailController(context.read<CardRepository>(), card.id));

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CardsController>();
    final cards = controller.cards.map(latest).toList();
    syncWalletOrder(cards.map((c) => c.id));
    _applyFocus(cards);
    final loading =
        cards.isEmpty && (controller.status == CardsStatus.idle || controller.status == CardsStatus.loading);
    final offset = CardStackMetrics.frameOffset(context);

    return BnScreen(
      child: Stack(
        children: [
          if (loading)
            const _StackSkeleton()
          else if (cards.isEmpty && controller.status == CardsStatus.error)
            Positioned(
              left: 24,
              right: 24,
              top: offset + CardStackMetrics.y0,
              bottom: 40,
              child: CardsLoadError(
                title: 'No pudimos cargar tus tarjetas',
                message: 'Revisa tu conexión e inténtalo de nuevo.',
                actionLabel: 'Reintentar',
                onAction: controller.load,
              ),
            )
          else if (cards.isEmpty)
            ..._emptyWallet(offset)
          else
            ..._wallet(cards, offline: controller.status == CardsStatus.offlineStale),
          Positioned(
            top: bnTopInset(context),
            left: 0,
            right: 0,
            child: BnNavBar(
              backLabel: 'Productos',
              title: 'Tus tarjetas',
              onBack: () => _leave(context),
            ),
          ),
          buildCardToast(),
        ],
      ),
    );
  }

  List<Widget> _wallet(List<Card> cards, {required bool offline}) {
    final holder = _holderName(context);
    final byId = {for (final c in cards) c.id: c};
    final front = byId[walletOrder.first]!;
    return [
      Positioned.fill(
        key: const ValueKey('stack'),
        child: CardStackLayer(
          entries: layoutCardStack(
            present: [for (final c in cards) CardVisual.of(c, holder)],
            docked: walletOrder,
            order: walletOrder,
            interactive: true,
            flipped: walletFlipped,
            isFrozen: (v) => isFrozen(byId[v.id]!),
          ),
          onTapCard: (e) => e.isFront ? toggleFlip() : bringToFront(e.visual.id),
          onSwipe: cycleWallet,
        ),
      ),
      Positioned(
        left: 24,
        right: 24,
        top: CardStackMetrics.frameOffset(context) + CardStackMetrics.panelTop(cards.length),
        bottom: 40,
        child: CardWalletPanel(
          card: front,
          frozen: isFrozen(front),
          flipped: walletFlipped,
          offline: offline,
          onFlip: toggleFlip,
          onFreeze: () => toggleFreeze(front),
          onLimits: () => openLimits(front),
          onWallet: () => addToWallet(front),
          onDone: () => _leave(context),
        ),
      ),
    ];
  }

  List<Widget> _emptyWallet(double offset) => [
        const CardSlot(),
        Positioned(
          left: 24,
          right: 24,
          top: offset + 372,
          bottom: 40,
          child: _IntroBlock(
            title: 'Aún no tienes tarjetas',
            body: 'Crea tus tarjetas en segundos y empieza a usarlas al instante.',
            rows: const [],
            cta: 'Crear mis tarjetas',
            onStart: () => Navigator.of(context).pushReplacementNamed(AppRoute.createVirtualCard),
          ),
        ),
      ];
}

enum _Phase { intro, face, build, fail, pending, done }

/// "Crear tarjeta virtual" (and the first-time "Crear tarjetas" flow):
/// intro → Face ID → construction → wallet, or the error state.
class VirtualCardCreationPage extends StatefulWidget {
  const VirtualCardCreationPage({super.key});

  @override
  State<VirtualCardCreationPage> createState() => _VirtualCardCreationPageState();
}

class _VirtualCardCreationPageState extends State<VirtualCardCreationPage> with CardWalletMixin {
  static const _failedId = '_virtual-card-failed';
  static const _maxPolls = 8;

  late final CardCreationController _creation;
  final _timers = <Timer>[];
  final _detail = <String, CardDetailController>{};

  _Phase _phase = _Phase.intro;
  BnFaceIdState _face = BnFaceIdState.idle;
  String? _faceError;
  bool _first = false;
  bool _authPassed = false;
  bool _awaitingOutcome = false;
  bool _failing = false;
  int _polls = 0;
  int _expected = 1;
  DateTime _phaseStart = DateTime.now();
  List<Card> _base = const [];
  final _present = <CardVisual>[];
  final _docked = <String>[];
  final _queue = <String>[];
  final _created = <String, Card>{};

  @override
  void initState() {
    super.initState();
    _creation = context.read<CardCreationController>()..addListener(_onCreation);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cards = context.read<CardsController>();
      if (cards.status == CardsStatus.idle) cards.load();
      final accounts = context.read<AccountsController>();
      if (accounts.status == AccountsStatus.idle) accounts.load();
    });
  }

  @override
  void dispose() {
    _creation.removeListener(_onCreation);
    _clearTimers();
    for (final c in _detail.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  CardDetailController detailControllerFor(Card card) =>
      _detail.putIfAbsent(card.id, () => CardDetailController(context.read<CardRepository>(), card.id));

  void _later(int ms, VoidCallback fn) => _timers.add(Timer(Duration(milliseconds: ms), () {
        if (mounted) fn();
      }));

  void _clearTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  int get _elapsed => DateTime.now().difference(_phaseStart).inMilliseconds;

  static bool _isFirstRun(CardsController c) =>
      (c.status == CardsStatus.loaded || c.status == CardsStatus.offlineStale) && c.cards.isEmpty;

  static bool _isTerminal(CardCreationStatus s) =>
      s == CardCreationStatus.completed || s == CardCreationStatus.failure || s == CardCreationStatus.pending;

  // ---- State machine (port of start() / build() in the canvas script) ----

  void _onCreation() {
    if (!mounted) return;
    final status = _creation.status;
    if (_phase == _Phase.face && !_authPassed) {
      if (status == CardCreationStatus.creating) {
        _authPassed = true;
        _confirmFace();
      } else if (status == CardCreationStatus.failure) {
        _faceFailed();
      }
      return;
    }
    if (_phase == _Phase.build && _awaitingOutcome && _isTerminal(status)) _resolveOutcome();
  }

  void _start() {
    if (_phase == _Phase.face || _phase == _Phase.build) return;
    _clearTimers();
    final cards = context.read<CardsController>();
    _first = _isFirstRun(cards);
    _base = cards.cards.map(latest).toList();
    syncWalletOrder(_base.map((c) => c.id));
    _authPassed = false;
    _faceError = null;
    _polls = 0;
    setState(() {
      _phase = _Phase.face;
      _face = BnFaceIdState.idle;
    });
    _phaseStart = DateTime.now();
    _later(350, () {
      if (_phase == _Phase.face && _face == BnFaceIdState.idle) setState(() => _face = BnFaceIdState.scan);
    });
    unawaited(_creation.start());
  }

  /// Real Face ID passed: keep the scan visible until 1.6 s, then `ok`
  /// for 800 ms before the construction starts.
  void _confirmFace() {
    _later(math.max(0, 1600 - _elapsed), () {
      setState(() => _face = BnFaceIdState.ok);
      BnHaptics.light();
      _later(800, _beginBuild);
    });
  }

  void _faceFailed() {
    final message = _creation.errorMessage ?? 'No pudimos validar tu identidad.';
    setState(() {
      _face = BnFaceIdState.err;
      _faceError = message;
    });
    BnHaptics.error();
    _later(1400, () {
      setState(() {
        _phase = _Phase.intro;
        _face = BnFaceIdState.idle;
        _faceError = null;
      });
      showCardToast(message, ok: false);
    });
  }

  void _beginBuild() {
    setState(() {
      _phase = _Phase.build;
      _present
        ..clear()
        ..addAll(_base.map((c) => CardVisual.of(c, _holderName(context))));
      _docked
        ..clear()
        ..addAll(_base.map((c) => c.id));
      _queue.clear();
      _expected = _first ? 3 : 1;
      _failing = false;
      walletFlipped = false;
    });
    _phaseStart = DateTime.now();
    _awaitingOutcome = true;
    if (_isTerminal(_creation.status)) _resolveOutcome();
  }

  Future<void> _resolveOutcome() async {
    _awaitingOutcome = false;
    switch (_creation.status) {
      case CardCreationStatus.completed:
        var cards = <Card>[_creation.card!];
        if (_first) {
          // The first request may provision the whole set; stack every new card.
          final list = context.read<CardsController>();
          await list.load();
          if (!mounted || _phase != _Phase.build) return;
          final known = _base.map((c) => c.id).toSet();
          final fresh = list.cards.where((c) => !known.contains(c.id)).toList()
            ..sort((a, b) => _firstRank(a).compareTo(_firstRank(b)));
          if (fresh.isNotEmpty) cards = fresh;
        }
        _runTimeline(cards);
      case CardCreationStatus.failure:
        _runFailure();
      case CardCreationStatus.pending:
        if (_polls < _maxPolls) {
          _polls++;
          _later(1500, () {
            _awaitingOutcome = true;
            unawaited(_creation.refresh());
          });
        } else {
          setState(() => _phase = _Phase.pending);
        }
      case CardCreationStatus.idle || CardCreationStatus.authenticating || CardCreationStatus.creating:
        _awaitingOutcome = true;
    }
  }

  /// Canvas order for the first set: débito, virtual, crédito.
  static int _firstRank(Card c) => switch (CardSkin.of(c)) {
        CardSkin.debit => 0,
        CardSkin.virtual => 1,
        CardSkin.credit => 2,
      };

  void _runTimeline(List<Card> cards) {
    final holder = _holderName(context);
    setState(() {
      _expected = cards.length;
      _queue
        ..clear()
        ..addAll(cards.map((c) => c.id));
      for (final c in cards) {
        _created[c.id] = c;
      }
    });
    var t = math.max(0, 260 - _elapsed);
    for (final card in cards) {
      _later(t, () {
        setState(() => _present.add(CardVisual.of(card, holder)));
        BnHaptics.tap();
      });
      t += 1520;
      _later(t, () {
        setState(() {
          _docked.add(card.id);
          walletOrder.remove(card.id);
          // The new virtual card lands in front; the first set stacks behind.
          _first ? walletOrder.add(card.id) : walletOrder.insert(0, card.id);
        });
      });
      t += 520;
    }
    _later(t + 260, () {
      setState(() => _phase = _Phase.done);
      BnHaptics.success();
      if (!_first) unawaited(context.read<CardsController>().load());
    });
  }

  void _runFailure() {
    final visual = CardVisual(id: _failedId, skin: CardSkin.virtual, last4: '••••', holder: _holderName(context));
    setState(() {
      _expected = 1;
      _queue
        ..clear()
        ..add(_failedId);
    });
    final t = math.max(0, 260 - _elapsed);
    _later(t, () {
      setState(() => _present.add(visual));
      BnHaptics.tap();
    });
    _later(t + 1000, () {
      setState(() => _failing = true);
      BnHaptics.error();
    });
    _later(t + 1700, () {
      setState(() {
        _phase = _Phase.fail;
        _failing = false;
        _present.removeWhere((v) => v.id == _failedId);
      });
    });
  }

  void _checkAgain() {
    setState(() => _phase = _Phase.build);
    _phaseStart = DateTime.now();
    _polls = 0;
    _awaitingOutcome = true;
    unawaited(_creation.refresh());
  }

  // ---- View ----

  String get _caption {
    if (_failing) return 'No se pudo completar';
    for (final v in _present) {
      if (!_docked.contains(v.id)) return 'Creando tu tarjeta ${v.skin.name.toLowerCase()}';
    }
    if (_queue.isEmpty) return 'Creando tu tarjeta ${_first ? 'débito' : 'virtual'}';
    return _doneCount < _expected ? 'Agregando a tu billetera' : 'Ordenando tus tarjetas';
  }

  int get _doneCount => _docked.where(_queue.contains).length;

  Card? _cardById(String id) => _created[id] ?? _base.where((c) => c.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final cardsController = context.watch<CardsController>();
    final savings =
        context.watch<AccountsController>().accounts.where((a) => a.type == AccountType.savings).firstOrNull;
    final live = _phase == _Phase.intro || _phase == _Phase.face;
    final first = _phase == _Phase.intro ? _isFirstRun(cardsController) : _first;
    final offset = CardStackMetrics.frameOffset(context);

    final List<CardVisual> present;
    final List<String> docked;
    if (live) {
      final cards = cardsController.cards.map(latest).toList();
      syncWalletOrder(cards.map((c) => c.id));
      final holder = _holderName(context);
      present = [for (final c in cards) CardVisual.of(c, holder)];
      docked = List.of(walletOrder);
    } else {
      present = _present;
      docked = _docked;
    }
    final k = docked.length;
    final entries = layoutCardStack(
      present: present,
      docked: docked,
      order: walletOrder,
      interactive: _phase == _Phase.done,
      buildPhase: _phase == _Phase.build,
      failing: _failing,
      flipped: walletFlipped,
      isFrozen: (v) => v.card != null && isFrozen(v.card!),
    );
    final loadingStack =
        live && !first && cardsController.cards.isEmpty && cardsController.status == CardsStatus.loading;

    return BnScreen(
      child: Stack(
        children: [
          if (live)
            Positioned.fill(
              key: const ValueKey('under'),
              child: _Under(
                blurred: _phase == _Phase.face,
                child: Stack(
                  children: [
                    if (first) const _FadeIn(child: SizedBox.expand(child: Stack(children: [CardSlot()]))),
                    Positioned(
                      left: 24,
                      right: 24,
                      top: offset + (first ? 372 : math.max(414.0, CardStackMetrics.bottomOf(k) + 24)),
                      bottom: 40,
                      child: first ? _firstIntro(savings) : _virtualIntro(),
                    ),
                  ],
                ),
              ),
            ),
          if (loadingStack) const _StackSkeleton(panel: false),
          if (_phase == _Phase.fail || _phase == _Phase.pending)
            Positioned(
              left: 24,
              right: 24,
              top: offset + 440,
              bottom: 40,
              child: _phase == _Phase.fail ? _failPanel() : _pendingPanel(),
            ),
          if (_phase == _Phase.done) _donePanel(offset, k, first),
          Positioned.fill(
            key: const ValueKey('stack'),
            child: CardStackLayer(
              entries: entries,
              onTapCard: (e) => e.isFront ? toggleFlip() : bringToFront(e.visual.id),
              onSwipe: cycleWallet,
            ),
          ),
          if (_phase == _Phase.build)
            Positioned(
              left: 24,
              right: 24,
              top: offset + 716,
              child: Column(
                children: [
                  _FadeIn(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(_caption, style: BnType.headline.copyWith(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  CardBuildBars(total: _expected, done: _doneCount),
                ],
              ),
            ),
          Positioned(
            key: const ValueKey('nav'),
            top: bnTopInset(context),
            left: 0,
            right: 0,
            child: BnNavBar(
              showBack: _phase != _Phase.build && _phase != _Phase.face,
              backLabel: 'Productos',
              title: _phase == _Phase.done
                  ? 'Tus tarjetas'
                  : first
                      ? 'Crear tarjetas'
                      : 'Tarjeta virtual',
              onBack: () => _leave(context),
            ),
          ),
          if (_phase == _Phase.face)
            Positioned.fill(
              child: _FadeIn(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BnFaceIdHud(state: _face, size: 148),
                      const SizedBox(height: 22),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _faceError ??
                              switch (_face) {
                                BnFaceIdState.ok => 'Identidad confirmada',
                                BnFaceIdState.scan => 'Validando identidad…',
                                _ => 'Confirma tu identidad para continuar.',
                              },
                          textAlign: TextAlign.center,
                          style: BnType.subhead.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          buildCardToast(),
        ],
      ),
    );
  }

  Widget _virtualIntro() => _IntroBlock(
        title: 'Crea tu tarjeta virtual',
        body: 'Úsala en compras en línea mientras tu tarjeta física se queda guardada.',
        rows: const [
          (Color(0xFF7A7772), 'Lista al instante', 'Sin costo de emisión ni envío'),
          (BnColors.relleno, 'Datos protegidos', 'Número visible solo con Face ID'),
          (BnColors.relleno, 'Bajo tu control', 'Congélala o elimínala cuando quieras'),
        ],
        cta: 'Confirmar con Face ID',
        onStart: _start,
      );

  Widget _firstIntro(Account? savings) {
    final number = savings == null ? null : cardLast4(savings.maskedNumber);
    return _IntroBlock(
      title: 'Tus tarjetas, listas en segundos',
      body: number == null
          ? 'Crearemos tres tarjetas vinculadas a tu cuenta de ahorros.'
          : 'Crearemos tres tarjetas vinculadas a tu cuenta de ahorros **** $number.',
      rows: [
        for (final s in const [CardSkin.debit, CardSkin.virtual, CardSkin.credit]) (s.swatch, s.title, s.desc),
      ],
      cta: 'Crear mis tarjetas',
      onStart: _start,
    );
  }

  Widget _donePanel(double offset, int k, bool first) {
    final frontId = walletOrder.firstWhere(_docked.contains, orElse: () => '');
    final front = _cardById(frontId);
    if (front == null) return const Positioned(left: 0, top: 0, child: SizedBox.shrink());
    final card = latest(front);
    return Positioned(
      left: 24,
      right: 24,
      top: offset + CardStackMetrics.panelTop(k),
      bottom: 40,
      child: CardWalletPanel(
        card: card,
        frozen: isFrozen(card),
        flipped: walletFlipped,
        createdMessage: first ? 'Tus tarjetas están listas' : 'Tarjeta virtual creada',
        onFlip: toggleFlip,
        onFreeze: () => toggleFreeze(card),
        onLimits: () => openLimits(card),
        onWallet: () => addToWallet(card),
        onDone: () => _leave(context),
      ),
    );
  }

  Widget _failPanel() => _OutcomePanel(
        tileColor: BnColors.criticoFondo,
        tileBorder: const Color(0xFFEBC9C5),
        icon: BnGlyphs.exclamation,
        iconColor: BnColors.critico,
        title: 'No pudimos crear tu tarjeta',
        body: 'No se realizó ningún cargo. Tus tarjetas actuales siguen activas.',
        action: 'Reintentar',
        onAction: _start,
        onBack: () => _leave(context),
      );

  Widget _pendingPanel() => _OutcomePanel(
        tileColor: BnColors.precaucionFondo,
        tileBorder: const Color(0xFFEBD9BC),
        icon: BnGlyphs.clock,
        iconColor: BnColors.precaucion,
        title: 'Solicitud en proceso',
        body: 'La tarjeta aún no está lista. Consulta nuevamente cuando quieras.',
        action: 'Consultar estado',
        onAction: _checkAgain,
        onBack: () => _leave(context),
      );
}

/// Single card opened from a notification: same wallet UI, one card.
class CardDetailPage extends StatefulWidget {
  const CardDetailPage({required this.cardId, super.key});

  final String cardId;

  @override
  State<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> with CardWalletMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CardDetailController>().load();
    });
  }

  @override
  CardDetailController detailControllerFor(Card card) => context.read<CardDetailController>();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CardDetailController>();
    final loaded = controller.card;
    final offset = CardStackMetrics.frameOffset(context);
    final children = <Widget>[];
    if (loaded == null) {
      if (controller.status == CardDetailStatus.idle || controller.status == CardDetailStatus.loading) {
        children.add(const _StackSkeleton());
      } else {
        children.add(Positioned(
          left: 24,
          right: 24,
          top: offset + CardStackMetrics.y0,
          bottom: 40,
          child: CardsLoadError(
            title: 'No pudimos cargar la tarjeta',
            message: controller.errorMessage ?? 'Tarjeta no encontrada.',
            actionLabel: 'Reintentar',
            onAction: controller.load,
          ),
        ));
      }
    } else {
      final card = latest(loaded);
      syncWalletOrder([card.id]);
      children
        ..add(Positioned.fill(
          child: CardStackLayer(
            entries: layoutCardStack(
              present: [CardVisual.of(card, _holderName(context))],
              docked: walletOrder,
              order: walletOrder,
              interactive: true,
              flipped: walletFlipped,
              isFrozen: (_) => isFrozen(card),
            ),
            onTapCard: (_) => toggleFlip(),
          ),
        ))
        ..add(Positioned(
          left: 24,
          right: 24,
          top: offset + CardStackMetrics.panelTop(1),
          bottom: 40,
          child: CardWalletPanel(
            card: card,
            frozen: isFrozen(card),
            flipped: walletFlipped,
            offline: controller.status == CardDetailStatus.offlineStale,
            onFlip: toggleFlip,
            onFreeze: () => toggleFreeze(card),
            onLimits: () => openLimits(card),
            onWallet: () => addToWallet(card),
            onDone: () => _leave(context),
          ),
        ));
    }
    return BnScreen(
      child: Stack(
        children: [
          ...children,
          Positioned(
            top: bnTopInset(context),
            left: 0,
            right: 0,
            child: BnNavBar(title: 'Tus tarjetas', onBack: () => _leave(context)),
          ),
          buildCardToast(),
        ],
      ),
    );
  }
}

/// Intro copy block: title, body, swatch rows and the primary CTA.
class _IntroBlock extends StatelessWidget {
  const _IntroBlock({
    required this.title,
    required this.body,
    required this.rows,
    required this.cta,
    required this.onStart,
  });

  final String title;
  final String body;
  final List<(Color, String, String)> rows;
  final String cta;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => CardFillScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardRise(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: BnType.family,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.98,
                  height: 1.12,
                  color: BnColors.carbon,
                ),
              ),
            ),
            const SizedBox(height: 8),
            CardRise(
              delay: 60,
              child: Text(
                body,
                style: const TextStyle(fontFamily: BnType.family, fontSize: 15, height: 1.45, color: BnColors.texto2),
              ),
            ),
            const SizedBox(height: 14),
            for (var n = 0; n < rows.length; n++)
              CardRise(delay: 100 + n * 50, child: _IntroRow(swatch: rows[n].$1, title: rows[n].$2, desc: rows[n].$3)),
            const Spacer(),
            CardRise(
              delay: 220,
              child: BnButton(
                label: cta,
                icon: BnSvg(CardGlyphs.faceId, size: 22, color: BnColors.superficie),
                onTap: onStart,
              ),
            ),
          ],
        ),
      );
}

class _IntroRow extends StatelessWidget {
  const _IntroRow({required this.swatch, required this.title, required this.desc});

  final Color swatch;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 50),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: BnColors.divisorSuave))),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 26,
              decoration: BoxDecoration(
                color: swatch,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x14141518)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontFamily: BnType.family,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: BnColors.carbon)),
                  Text(desc, style: const TextStyle(fontFamily: BnType.family, fontSize: 13, color: BnColors.texto3)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Fail / pending panel (`top: 440px`): alert tile, copy, primary + ghost.
class _OutcomePanel extends StatelessWidget {
  const _OutcomePanel({
    required this.tileColor,
    required this.tileBorder,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
    required this.onBack,
  });

  final Color tileColor;
  final Color tileBorder;
  final String icon;
  final Color iconColor;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => CardFillScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardRise(
              delay: 700,
              child: Semantics(
                liveRegion: true,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: tileBorder),
                      ),
                      child: BnSvg(icon, size: 26, color: iconColor),
                    ),
                    const SizedBox(height: 14),
                    Text(title, textAlign: TextAlign.center, style: BnType.tituloSeccion),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: BnType.family, fontSize: 15, color: BnColors.texto2),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            CardRise(
              delay: 800,
              child: Column(
                children: [
                  BnButton(label: action, onTap: onAction),
                  const SizedBox(height: 10),
                  BnButton(
                    label: 'Volver a Productos',
                    variant: BnButtonVariant.ghost,
                    height: 50,
                    fontSize: 16,
                    onTap: onBack,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// `.under` / `.under.blur`: the intro softens (blur 8 px, opacity .6)
/// behind the Face ID HUD in 360 ms.
class _Under extends StatelessWidget {
  const _Under({required this.blurred, required this.child});

  final bool blurred;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: blurred ? 1 : 0),
        duration: const Duration(milliseconds: 360),
        curve: BnMotion.entrada,
        child: child,
        builder: (context, b, child) => Opacity(
          opacity: 1 - .4 * b,
          child: ImageFiltered(
            enabled: b > 0,
            imageFilter: ImageFilter.blur(sigmaX: 8 * b, sigmaY: 8 * b),
            child: child,
          ),
        ),
      );
}

/// `.fade`: 300 ms opacity on mount.
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: bnReduceMotion(context) ? 200 : 300),
        curve: Curves.ease,
        child: child,
        builder: (context, v, child) => Opacity(opacity: v, child: child),
      );
}

/// Loading placeholder: card silhouette at Y0 plus the panel lines.
class _StackSkeleton extends StatelessWidget {
  const _StackSkeleton({this.panel = true});

  final bool panel;

  @override
  Widget build(BuildContext context) {
    final offset = CardStackMetrics.frameOffset(context);
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            left: CardStackMetrics.side,
            right: CardStackMetrics.side,
            top: offset + CardStackMetrics.y0,
            height: CardStackMetrics.cardHeight,
            child: const BnSkeleton(
                width: double.infinity, height: CardStackMetrics.cardHeight, radius: BnRadius.tarjetaBancaria),
          ),
          if (panel)
            Positioned(
              left: 24,
              right: 24,
              top: offset + CardStackMetrics.panelTop(1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BnSkeleton(width: 180, height: 22),
                  const SizedBox(height: 8),
                  const BnSkeleton(width: 220, height: 14),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [for (var i = 0; i < 4; i++) const BnSkeleton(height: 52, circle: true)],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
