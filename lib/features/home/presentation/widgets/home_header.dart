import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';



class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.displayName,
    this.onAvatar,
    this.onAvatarLongPress,
    this.onBell,
    this.hasUnread = false,
    super.key,
  });

  final String displayName;
  final VoidCallback? onAvatar;
  final VoidCallback? onAvatarLongPress;
  final VoidCallback? onBell;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final first = BnFormat.firstName(displayName);
    Widget avatar = BnInitialsAvatar(initials: BnFormat.initials(displayName));
    if (onAvatar != null) {
      avatar = BnPressable(onTap: onAvatar, scale: .96, semanticLabel: 'Perfil de $first', child: avatar);
    }
    if (onAvatarLongPress != null) {
      avatar = GestureDetector(onLongPress: onAvatarLongPress, child: avatar);
    }
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(BnFormat.greeting(), style: BnType.footnote.copyWith(height: 1.2)),
                  Text(
                    first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: BnType.family,
                      fontSize: 18,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.36,
                      color: BnColors.carbon,
                    ),
                  ),
                ],
              ),
            ),
            if (onBell != null) _Bell(onTap: onBell!, hasUnread: hasUnread),
          ],
        ),
      ),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.onTap, required this.hasUnread});

  final VoidCallback onTap;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) => BnPressable(
        onTap: onTap,
        scale: .96,
        semanticLabel: hasUnread ? 'Notificaciones, sin leer' : 'Notificaciones',
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: BnColors.superficie,
            shape: BoxShape.circle,
            border: Border.all(color: BnColors.hairline),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(child: BnSvg(BnGlyphs.bell, size: 22, color: BnColors.carbon)),
              if (hasUnread)
                Positioned(
                  top: 10,
                  right: 11,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: BnColors.brandNaranjaBi,
                      shape: BoxShape.circle,
                      border: Border.all(color: BnColors.superficie, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}
