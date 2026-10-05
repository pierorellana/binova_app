import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/routing/app_router.dart';
import '../../../../core/design_system/binova_widgets.dart';
import '../../../accounts/domain/entities/account.dart';
import '../providers/operation_flow_controller.dart';
import 'operation_copy.dart';
import 'operation_face_id_layer.dart';
import 'operation_motion.dart';
import 'operation_parts.dart';
import 'operation_result_view.dart';
import 'operation_sheets.dart';

enum OperationStep { pick, amount, confirm, face, op }

/// Shared state machine of Transferir · Pagar · Recargar
/// (`Transferir.dc.html`): selección → monto → confirmación → Face ID →
/// procesamiento → resultado. Each page owns its domain input (recipient,
/// amount, bill) and the submission; this widget owns steps, timers,
/// transitions, overlays and maps [OperationFlowController] to visuals.
class OperationFlowView extends StatefulWidget {
  const OperationFlowView({
    required this.copy,
    required this.targets,
    required this.targetsLoading,
    required this.selected,
    required this.onSelect,
    required this.amountBody,
    required this.source,
    required this.sourceLoading,
    required this.canContinue,
    required this.amount,
    required this.confirmRows,
    required this.onSubmit,
    required this.onReset,
    this.targetsError,
    this.onReloadTargets,
    this.sourceError,
    this.keypad,
    this.noteController,
    super.key,
  });

  final OperationCopy copy;
  final List<OperationTarget> targets;
  final bool targetsLoading;
  final String? targetsError;
  final VoidCallback? onReloadTargets;
  final OperationTarget? selected;
  final ValueChanged<OperationTarget> onSelect;

  /// Middle area of the amount step (keypad display, bill card, chips).
  final Widget amountBody;
  final Widget? keypad;
  final Account? source;
  final bool sourceLoading;
  final String? sourceError;
  final bool canContinue;
  final double amount;
  final List<(String, String)> confirmRows;
  final TextEditingController? noteController;

  /// Calls [OperationFlowController.submit] with the page's repository call.
  final Future<void> Function() onSubmit;

  /// Clears the page's input for "Otra transferencia / pago / recarga".
  final VoidCallback onReset;

  @override
  State<OperationFlowView> createState() => _OperationFlowViewState();
}

class _OperationFlowViewState extends State<OperationFlowView> {
  static const _originLabel = 'Inicio';

  final _search = TextEditingController();
  final _timers = <Timer>[];
  late final OperationFlowController _flow = context.read<OperationFlowController>();
  late OperationFlowStatus _lastStatus;

  OperationStep _step = OperationStep.pick;
  StepDirection _dir = StepDirection.fwd;
  BnFaceIdState _face = BnFaceIdState.idle;
  BnOpPhase _phase = BnOpPhase.proc;
  BnOpPhase? _result;
  DateTime _opStartedAt = DateTime.now();
  bool _secondProcMessage = false;
  bool _retried = false;
  bool _refreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _lastStatus = _flow.status;
    _flow.addListener(_onFlow);
  }

  @override
  void dispose() {
    _flow.removeListener(_onFlow);
    _clear();
    _search.dispose();
    super.dispose();
  }

  void _clear() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  void _later(int ms, VoidCallback f) => _timers.add(Timer(Duration(milliseconds: ms), () {
        if (mounted) f();
      }));

  void _go(OperationStep step, StepDirection dir) => setState(() {
        _step = step;
        _dir = dir;
      });

  // ---------------------------------------------------------------------------
  // Controller → visual state
  // ---------------------------------------------------------------------------

  void _onFlow() {
    final status = _flow.status;
    if (status == _lastStatus) return;
    final previous = _lastStatus;
    _lastStatus = status;
    switch (status) {
      case OperationFlowStatus.submitting:
        if (_step == OperationStep.face && previous == OperationFlowStatus.authenticating) {
          setState(() => _face = BnFaceIdState.ok);
          BnHaptics.light();
          _later(850, _enterProcessing);
        }
      case OperationFlowStatus.failed:
        if (_flow.authenticationFailed) {
          _clear();
          setState(() {
            _step = OperationStep.face;
            _face = BnFaceIdState.err;
          });
          BnHaptics.error();
        } else {
          _resolve(BnOpPhase.err);
        }
      case OperationFlowStatus.succeeded:
        _resolve(BnOpPhase.ok);
      case OperationFlowStatus.pending:
        _resolve(BnOpPhase.warn);
      case OperationFlowStatus.idle:
      case OperationFlowStatus.authenticating:
        break;
    }
  }

  void _resolve(BnOpPhase result) {
    _result = result;
    if (_step != OperationStep.op) return;
    if (_phase != BnOpPhase.proc) {
      _show(result);
      return;
    }
    final elapsed = DateTime.now().difference(_opStartedAt).inMilliseconds;
    final wait = BnMotion.procesamientoMinimo.inMilliseconds - elapsed;
    if (wait <= 0) {
      _show(result);
    } else {
      _later(wait, () => _show(result));
    }
  }

  void _show(BnOpPhase result) {
    if (_phase == result) return;
    setState(() => _phase = result);
    if (result == BnOpPhase.ok) {
      BnHaptics.success();
    } else {
      BnHaptics.error();
    }
    // A pending operation is checked again once ("te avisaremos apenas se confirme").
    if (result == BnOpPhase.warn && !_refreshScheduled) {
      _refreshScheduled = true;
      _later(5000, _flow.refresh);
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _pick(OperationTarget target) {
    FocusScope.of(context).unfocus();
    widget.onSelect(target);
    _go(OperationStep.amount, StepDirection.fwd);
  }

  void _startFace() {
    _clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _step = OperationStep.face;
      _face = BnFaceIdState.idle;
    });
    _later(350, () {
      setState(() => _face = BnFaceIdState.scan);
      widget.onSubmit();
    });
  }

  void _enterProcessing() {
    _clear();
    setState(() {
      _step = OperationStep.op;
      _phase = BnOpPhase.proc;
      _secondProcMessage = false;
      _opStartedAt = DateTime.now();
    });
    _later(1400, () {
      if (_phase == BnOpPhase.proc) setState(() => _secondProcMessage = true);
    });
    final result = _result;
    if (result != null) _resolve(result);
  }

  void _retry() {
    _result = null;
    _retried = true;
    _enterProcessing();
    widget.onSubmit();
  }

  void _restart({required OperationStep step, required StepDirection dir}) {
    _clear();
    _flow.reset();
    _lastStatus = _flow.status;
    _result = null;
    _refreshScheduled = false;
    _phase = BnOpPhase.proc;
    _face = BnFaceIdState.idle;
    _go(step, dir);
  }

  void _again() {
    widget.onReset();
    _retried = false;
    _search.clear();
    _restart(step: OperationStep.pick, dir: StepDirection.fwd);
  }

  void _change() => _restart(
        step: widget.copy.changeGoesToPick ? OperationStep.pick : OperationStep.amount,
        dir: StepDirection.back,
      );

  Future<void> _askCancel() async {
    if (await showCancelOperationSheet(context, question: widget.copy.cancelQ) && mounted) _leave();
  }

  void _leave() => Navigator.of(context).pop();

  void _openReceipt() {
    final op = _flow.operation;
    showOperationReceipt(
      context,
      title: widget.copy.okTitle,
      amount: widget.amount,
      rows: [
        ...widget.confirmRows,
        if (op != null) ('Fecha', BnFormat.dateTime(op.createdAt.toLocal())),
        if (op != null) ('Referencia', op.providerReference ?? op.id),
      ],
    );
  }

  void _openMovements() => Navigator.of(context).pushReplacementNamed(AppRoute.transactions, arguments: widget.source!.id);

  bool get _canPop => _step == OperationStep.pick || (_step == OperationStep.op && _phase != BnOpPhase.proc);

  void _onBackGesture() {
    switch (_step) {
      case OperationStep.amount:
        _clear();
        _go(OperationStep.pick, StepDirection.back);
      case OperationStep.confirm:
        _go(OperationStep.amount, StepDirection.back);
      case OperationStep.face when _face == BnFaceIdState.err:
        _go(OperationStep.confirm, StepDirection.back);
      default:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final step = _step;
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackGesture();
      },
      child: BnScreen(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (step == OperationStep.pick) OperationStepIn(key: ValueKey('pick$_dir'), direction: _dir, child: _pickStep()),
            if (step == OperationStep.amount) OperationStepIn(key: ValueKey('amount$_dir'), direction: _dir, child: _amountStep()),
            if (step == OperationStep.confirm || step == OperationStep.face)
              OperationUnderLayer(
                blurred: step == OperationStep.face,
                child: OperationStepIn(key: ValueKey('confirm$_dir'), direction: _dir, child: _confirmStep()),
              ),
            if (step == OperationStep.face)
              Positioned.fill(
                child: OperationFaceIdLayer(
                  state: _face,
                  message: switch (_face) {
                    BnFaceIdState.ok => 'Identidad confirmada',
                    BnFaceIdState.err => _flow.errorMessage ?? 'No pudimos verificar tu identidad.',
                    BnFaceIdState.scan => 'Validando identidad…',
                    BnFaceIdState.idle => 'Confirma tu identidad para continuar.',
                  },
                  onRetry: _startFace,
                  onBack: () {
                    _clear();
                    setState(() => _face = BnFaceIdState.idle);
                    _go(OperationStep.confirm, StepDirection.back);
                  },
                ),
              ),
            if (step == OperationStep.op) Positioned.fill(child: _resultStep()),
          ],
        ),
      ),
    );
  }

  Widget _pickStep() {
    final query = _search.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? widget.targets
        : widget.targets.where((t) => t.name.toLowerCase().contains(query) || t.subtitle.toLowerCase().contains(query)).toList();
    return CustomScrollView(
      physics: bnScrollPhysics,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: bnTopInset(context))),
        SliverToBoxAdapter(
          child: OperationNavRow(
            leading: OperationTextButton(label: 'Cancelar', onTap: _leave),
            center: Semantics(
              header: true,
              child: Text(widget.copy.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: opStyle(17, weight: FontWeight.w600)),
            ),
            trailing: const SizedBox(width: 76),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: OperationSearchField(controller: _search, hint: widget.copy.search),
          ),
        ),
        SliverToBoxAdapter(child: OperationListTitle(widget.copy.listTitle)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          sliver: SliverList.list(
            children: [
              if (widget.targetsLoading)
                for (var i = 0; i < 4; i++) const OperationTargetSkeleton()
              else if (widget.targetsError != null)
                _TargetsError(message: widget.targetsError!, onRetry: widget.onReloadTargets)
              else
                for (var i = 0; i < visible.length; i++)
                  rise(OperationTargetRow(target: visible[i], onTap: () => _pick(visible[i])), i * 40),
              if (!widget.targetsLoading) OperationComingSoonRow(label: widget.copy.newLabel),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountStep() {
    final target = widget.selected;
    return Padding(
      padding: EdgeInsets.only(top: bnTopInset(context)),
      child: Column(
        children: [
          OperationNavRow(
            leading: OperationBackButton(onTap: () {
              _clear();
              _go(OperationStep.pick, StepDirection.back);
            }),
            center: target == null ? const SizedBox.shrink() : OperationRecipientHeader(target: target),
            trailing: const SizedBox(width: 44),
          ),
          Expanded(child: widget.amountBody),
          OperationSourceCard(account: widget.source, loading: widget.sourceLoading, error: widget.sourceError),
          if (widget.keypad != null) widget.keypad!,
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            child: BnButton(
              label: 'Continuar',
              variant: widget.canContinue ? BnButtonVariant.primary : BnButtonVariant.disabled,
              onTap: widget.canContinue ? () => _go(OperationStep.confirm, StepDirection.fwd) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmStep() => CustomScrollView(
        physics: bnScrollPhysics,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: bnTopInset(context))),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OperationNavRow(
                  leading: OperationBackButton(onTap: () => _go(OperationStep.amount, StepDirection.back)),
                  center: Semantics(header: true, child: Text('Confirmación', style: opStyle(17, weight: FontWeight.w600))),
                  trailing: OperationTextButton(label: 'Cancelar', onTap: _askCancel),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      Text(widget.copy.verb, style: opStyle(14, color: BnColors.texto2)),
                      const SizedBox(height: 6),
                      Text(
                        BnFormat.money(widget.amount),
                        style: opStyle(48, weight: FontWeight.w600, letterSpacing: -1.92, height: 1.05, tabular: true),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  child: rise(OperationDetailCard(rows: widget.confirmRows), 60),
                ),
                if (widget.noteController != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: rise(_NoteField(controller: widget.noteController!), 120),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BnSvg(OpGlyphs.lock, size: 13, color: BnColors.texto3),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text('Al confirmar, la operación ya no se puede modificar.', style: opStyle(13, color: BnColors.texto3)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BnButton(
                        label: 'Confirmar con Face ID',
                        icon: const BnFaceIdGlyph(size: 22, color: BnColors.superficie),
                        onTap: _startFace,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _resultStep() {
    final copy = widget.copy;
    final source = widget.source;
    return OperationResultView(
      copy: copy,
      phase: _phase,
      procTitle: _retried && !_secondProcMessage ? 'Reintentando…' : (_secondProcMessage ? copy.proc.$2 : copy.proc.$1),
      amount: widget.amount,
      recipientName: widget.selected?.name ?? '',
      completedAt: _flow.operation?.updatedAt,
      available: source == null ? null : accountAvailable(source),
      originLabel: _originLabel,
      onDone: _leave,
      onReceipt: _openReceipt,
      onAgain: _again,
      onMovements: source == null ? null : _openMovements,
      onRetry: _retry,
      onChange: _change,
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: BnColors.superficie,
          border: Border.all(color: BnColors.hairline),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Descripción (opcional)', style: opStyle(12, weight: FontWeight.w500, color: BnColors.texto3)),
            const SizedBox(height: 4),
            TextField(
              controller: controller,
              cursorColor: BnColors.carbon,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(160)],
              style: opStyle(16),
              decoration: InputDecoration.collapsed(
                hintText: 'Ej. Cena del viernes',
                hintStyle: opStyle(16, color: BnColors.placeholder),
              ),
            ),
          ],
        ),
      );
}

class _TargetsError extends StatelessWidget {
  const _TargetsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: opStyle(15, color: BnColors.texto2, height: 1.35)),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              BnButton(label: 'Reintentar', onTap: onRetry, variant: BnButtonVariant.secondary, height: 50),
            ],
          ],
        ),
      );
}
