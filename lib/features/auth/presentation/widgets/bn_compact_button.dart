import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_tokens.dart';
import '../../../../core/design_system/bn_motion.dart';

/// Hugging primary button of the access flow
/// (`height: 46px; padding: 0 22px; border-radius: 14px; 16/600`).
class BnCompactButton extends StatelessWidget {
  const BnCompactButton({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => BnPressable(
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(color: BnColors.carbon, borderRadius: BorderRadius.circular(14)),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: BnType.family,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: BnColors.superficie,
              ),
            ),
          ),
        ),
      );
}
