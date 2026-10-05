import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'binova_tokens.dart';
import 'bn_motion.dart';
import 'bn_svg.dart';

/// Presents a BInova sheet: spring `cubic-bezier(.32,.72,0,1)` 440 ms slide,
/// `rgba(20,21,24,.32)` dim with a progressive 6 px blur, drag to dismiss.
Future<T?> showBnSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
  Color background = BnColors.superficie,
  EdgeInsets padding = const EdgeInsets.fromLTRB(20, 8, 20, 0),
  bool showHandle = true,
}) {
  return Navigator.of(context).push<T>(
    BnSheetRoute<T>(
      builder: builder,
      dismissible: dismissible,
      background: background,
      padding: padding,
      showHandle: showHandle,
    ),
  );
}

class BnSheetRoute<T> extends PopupRoute<T> {
  BnSheetRoute({
    required this.builder,
    this.dismissible = true,
    this.background = BnColors.superficie,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 0),
    this.showHandle = true,
  });

  final WidgetBuilder builder;
  final bool dismissible;
  final Color background;
  final EdgeInsets padding;
  final bool showHandle;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => 'Cerrar';

  @override
  Duration get transitionDuration => BnMotion.sheet;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return _BnSheetFrame(route: this);
  }
}

class _BnSheetFrame extends StatefulWidget {
  const _BnSheetFrame({required this.route});

  final BnSheetRoute route;

  @override
  State<_BnSheetFrame> createState() => _BnSheetFrameState();
}

class _BnSheetFrameState extends State<_BnSheetFrame> {
  double _drag = 0;
  double _height = 1;

  void _close() {
    if (widget.route.dismissible) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final animation = route.animation!;
    final reduce = bnReduceMotion(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final dimT = Curves.ease.transform(animation.value.clamp(0, 1));
        final slide = animation.status == AnimationStatus.reverse
            ? BnMotion.salida.flipped.transform(animation.value)
            : BnMotion.springSuave.transform(animation.value);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6 * dimT * 0.5, sigmaY: 6 * dimT * 0.5),
                  child: ColoredBox(color: BnColors.carbon.withOpacity(.32 * dimT)),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: reduce
                  ? Opacity(opacity: animation.value, child: child)
                  : FractionalTranslation(
                      translation: Offset(0, 1 - slide),
                      child: Transform.translate(offset: Offset(0, _drag), child: child),
                    ),
            ),
          ],
        );
      },
      child: GestureDetector(
        onVerticalDragUpdate: route.dismissible
            ? (d) => setState(() => _drag = (_drag + d.delta.dy).clamp(0, double.infinity))
            : null,
        onVerticalDragEnd: route.dismissible
            ? (d) {
                if (_drag > _height * .25 || d.velocity.pixelsPerSecond.dy > 700) {
                  _close();
                } else {
                  setState(() => _drag = 0);
                }
              }
            : null,
        child: LayoutBuilder(builder: (context, c) {
          return Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: _MeasureSize(
              onChange: (s) => _height = s.height,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).top - 12),
                  decoration: BoxDecoration(
                    color: route.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(BnRadius.sheet)),
                  ),
                  padding: route.padding.copyWith(bottom: route.padding.bottom + (bottom > 0 ? bottom : 10) + 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (route.showHandle) const BnSheetHandle(),
                      Flexible(child: route.builder(context)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasure(onChange);
}

class _RenderMeasure extends RenderProxyBox {
  _RenderMeasure(this.onChange);

  final ValueChanged<Size> onChange;

  @override
  void performLayout() {
    super.performLayout();
    onChange(size);
  }
}

/// 36×5 grabber, `#D6D2CA`.
class BnSheetHandle extends StatelessWidget {
  const BnSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(color: BnColors.lineaFuerte, borderRadius: BorderRadius.circular(3)),
        ),
      );
}

/// Sheet title row: 20/600 title + 32 pt round close button.
class BnSheetHeader extends StatelessWidget {
  const BnSheetHeader({required this.title, this.onClose, this.topMargin = 12, super.key});

  final String title;
  final VoidCallback? onClose;
  final double topMargin;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: topMargin),
        child: Row(
          children: [
            Expanded(child: Semantics(header: true, child: Text(title, style: BnType.tituloSeccion))),
            BnCloseButton(onTap: onClose ?? () => Navigator.of(context).maybePop()),
          ],
        ),
      );
}

class BnCloseButton extends StatelessWidget {
  const BnCloseButton({this.onTap, this.size = 32, super.key});

  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) => BnPressable(
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        semanticLabel: 'Cerrar',
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: BnColors.relleno, shape: BoxShape.circle),
          child: BnSvg(BnGlyphs.close, size: 14, color: BnColors.texto2),
        ),
      );
}

/// Route helpers used by the app router.
abstract final class BnRoutes {
  /// Hierarchical push: native iOS slide with interactive swipe-back.
  static PageRoute<T> push<T>(Widget child, {RouteSettings? settings, bool fullscreenDialog = false}) =>
      CupertinoPageRoute<T>(builder: (_) => child, settings: settings, fullscreenDialog: fullscreenDialog);

  /// Tab switch / root replacement: quick cross-fade (180 ms).
  static PageRoute<T> fade<T>(Widget child, {RouteSettings? settings, Duration duration = BnMotion.fadePantalla}) =>
      PageRouteBuilder<T>(
        settings: settings,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        pageBuilder: (_, __, ___) => child,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.ease), child: child),
      );

  /// No animation at all (iOS tab bar switches are instant).
  static PageRoute<T> instant<T>(Widget child, {RouteSettings? settings}) => PageRouteBuilder<T>(
        settings: settings,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => child,
      );
}
