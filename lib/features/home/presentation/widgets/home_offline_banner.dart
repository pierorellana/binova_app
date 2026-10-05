import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';
import 'home_data.dart';

/// `Estado-SinConexion.dc.html` status banner (drops in: 300 ms, −8 px).
class HomeOfflineBanner extends StatelessWidget {
  const HomeOfflineBanner({
    required this.title,
    required this.message,
    required this.onRetry,
    this.updatedAt,
    super.key,
  });

  final String title;
  final String message;
  final DateTime? updatedAt;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => BnRise(
        duration: const Duration(milliseconds: 300),
        offset: -8,
        child: Semantics(
          liveRegion: true,
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: BnColors.superficie,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BnColors.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BnIconTile(svg: HomeGlyphs.wifiOff, size: 32, iconSize: 17, circle: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: BnType.subhead.copyWith(fontWeight: FontWeight.w600, height: 1.2)),
                            const SizedBox(height: 2),
                            Text(
                              message,
                              style: const TextStyle(
                                  fontFamily: BnType.family, fontSize: 14, height: 1.4, color: BnColors.texto2),
                            ),
                            if (updatedAt != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Última actualización: ${HomeData.clock(updatedAt!)}.',
                                style: BnType.footnote.copyWith(height: 1.2, fontFeatures: BnType.tabular),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                BnPressable(
                  onTap: onRetry,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: BnColors.carbon, borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                      'Reintentar',
                      style: TextStyle(
                        fontFamily: BnType.family,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BnColors.superficie,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
