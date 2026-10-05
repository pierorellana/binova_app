import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';




class ProfileSwitch extends StatelessWidget {
  const ProfileSwitch({
    required this.value,
    required this.onChanged,
    required this.label,
    this.trackDuration = const Duration(milliseconds: 220),
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final Duration trackDuration;

  @override
  Widget build(BuildContext context) {
    final reduce = bnReduceMotion(context);
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1 : .5,
          child: AnimatedContainer(
            duration: reduce ? Duration.zero : trackDuration,
            curve: Curves.ease,
            width: 51,
            height: 31,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value ? BnColors.brandNaranjaBi : BnColors.hairline,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedAlign(
              duration: reduce ? Duration.zero : const Duration(milliseconds: 260),
              curve: BnMotion.entrada,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 27,
                height: 27,
                decoration: const BoxDecoration(
                  color: BnColors.superficie,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 2))],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
