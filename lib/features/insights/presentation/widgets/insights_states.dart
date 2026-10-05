import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';


class InsightsOfflineBanner extends StatelessWidget {
  const InsightsOfflineBanner({required this.fetchedAt, required this.onRetry, super.key});

  static final _wifiOff = bnLine(
    '<path d="M3 3l18 18"/><path d="M8.5 16.5a5 5 0 0 1 7 0"/><path d="M5 12.5a10 10 0 0 1 4.2-2.4M19 12.5a10 10 0 0 0-3-2"/>'
    '<path d="M2 8.8A15 15 0 0 1 6.1 6.3M22 8.8A15 15 0 0 0 11 5"/><path d="M12 20h.01"/>',
    stroke: 1.8,
  );

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
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: BnColors.relleno, shape: BoxShape.circle),
                child: BnSvg(_wifiOff, size: 17, color: BnColors.carbon),
              ),
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
                    child: const Text('Reintentar',
                        style: TextStyle(fontFamily: BnType.family, fontSize: 14, fontWeight: FontWeight.w600, color: BnColors.superficie)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}


class InsightsMessageState extends StatelessWidget {
  const InsightsMessageState({
    required this.glyph,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String glyph;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
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
                  Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: BnColors.hairline))),
                  Container(
                    margin: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BnColors.superficie,
                      border: Border.all(color: BnColors.hairline),
                    ),
                  ),
                  BnSvg(glyph, size: 28, color: BnColors.texto2),
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
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              BnPressable(
                onTap: onAction,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BnColors.superficie,
                    border: Border.all(color: BnColors.lineaFuerte),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(actionLabel!,
                      style: const TextStyle(fontFamily: BnType.family, fontSize: 16, fontWeight: FontWeight.w600, color: BnColors.carbon)),
                ),
              ),
            ],
          ],
        ),
      );
}


class InsightsSkeleton extends StatelessWidget {
  const InsightsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Cargando tus insights',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const BnSkeleton(width: 130, height: 12),
              const SizedBox(height: 10),
              const BnSkeleton(width: 190, height: 38, radius: 10),
              const SizedBox(height: 10),
              const BnSkeleton(width: 160, height: 12),
              const SizedBox(height: 20),
              const BnSkeleton(width: double.infinity, height: 188, radius: BnRadius.cardGrande),
              const SizedBox(height: 28),
              const BnSkeleton(width: 130, height: 16, radius: 8),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BnColors.superficie,
                  border: Border.all(color: BnColors.hairline),
                  borderRadius: BorderRadius.circular(BnRadius.cardGrande),
                ),
                child: Column(
                  children: [
                    const BnSkeleton(width: double.infinity, height: 10, radius: 5),
                    for (final w in [120.0, 96.0, 108.0]) ...[
                      const SizedBox(height: 21),
                      Row(children: [
                        const BnSkeleton(width: 10, height: 10, radius: 3),
                        const SizedBox(width: 12),
                        BnSkeleton(width: w, height: 12),
                        const Spacer(),
                        const BnSkeleton(width: 72, height: 14, radius: 7),
                      ]),
                      const SizedBox(height: 19),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
