import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/design_system/binova_widgets.dart';
import 'operation_motion.dart';
import 'operation_parts.dart';



class OperationUnderLayer extends StatelessWidget {
  const OperationUnderLayer({required this.blurred, required this.child, super.key});

  final bool blurred;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = bnReduceMotion(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: blurred ? 1 : 0),
      duration: Duration(milliseconds: reduce ? 200 : 360),
      curve: BnMotion.entrada,
      child: child,
      builder: (context, t, child) {
        final sigma = 10 * t;
        Widget out = Opacity(opacity: 1 - .3 * t, child: child);
        if (!reduce) out = Transform.scale(scale: 1 - .015 * t, child: out);
        if (sigma > .01) {
          out = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.decal), child: out);
        }
        return IgnorePointer(ignoring: blurred, child: out);
      },
    );
  }
}


class OperationFaceIdLayer extends StatelessWidget {
  const OperationFaceIdLayer({
    required this.state,
    required this.message,
    required this.onRetry,
    required this.onBack,
    super.key,
  });

  final BnFaceIdState state;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => OperationFadeIn(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: switch (state) {
                    BnFaceIdState.ok => 'Identidad confirmada',
                    BnFaceIdState.err => 'No reconocido',
                    _ => 'Validando identidad',
                  },
                  child: BnFaceIdHud(state: state, size: 148),
                ),
                const SizedBox(height: 22),
                Semantics(
                  liveRegion: true,
                  child: Text(message, textAlign: TextAlign.center, style: opStyle(15, weight: FontWeight.w500)),
                ),
                if (state == BnFaceIdState.err)
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: rise(
                      Column(
                        children: [
                          BnPressable(
                            onTap: onRetry,
                            child: Container(
                              height: 46,
                              padding: const EdgeInsets.symmetric(horizontal: 22),
                              decoration: BoxDecoration(color: BnColors.carbon, borderRadius: BorderRadius.circular(14)),
                              child: Center(
                                widthFactor: 1,
                                child: Text('Intentar nuevamente', style: opStyle(16, weight: FontWeight.w600, color: BnColors.superficie)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          BnPressable(
                            onTap: onBack,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 44),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Center(
                                  widthFactor: 1,
                                  child: Text('Volver a la confirmación', style: opStyle(15, weight: FontWeight.w500)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
