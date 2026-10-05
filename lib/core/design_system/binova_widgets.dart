import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'binova_tokens.dart';
import 'bn_shell.dart';

export 'binova_tokens.dart';
export 'bn_balanced_text.dart';
export 'bn_category.dart';
export 'bn_face_id.dart';
export 'bn_format.dart';
export 'bn_motion.dart';
export 'bn_operation_indicator.dart';
export 'bn_sheet.dart';
export 'bn_shell.dart';
export 'bn_svg.dart';




class BnAssetIcon extends StatelessWidget {
  const BnAssetIcon(
    this.name, {
    this.size = 22,
    this.color,
    this.semanticsLabel,
    super.key,
  });

  final String name;
  final double size;
  final Color? color;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final picture = SvgPicture.asset(
      'assets/iconos/$name.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter:
          color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      semanticsLabel: semanticsLabel,
    );
    return ExcludeSemantics(
      excluding: semanticsLabel == null,
      child: picture,
    );
  }
}

class BnLogo extends StatelessWidget {
  const BnLogo({this.dark = false, this.width = 85, super.key});

  final bool dark;
  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
        dark
            ? 'assets/logo/binova-wordmark-blanco.png'
            : 'assets/logo/binova-wordmark.png',
        width: width,
        fit: BoxFit.contain,
        semanticLabel: 'BInova',
      );
}

class BnPageScaffold extends StatelessWidget {
  const BnPageScaffold({
    required this.body,
    this.currentTab,
    this.bottomNavigation = true,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    super.key,
  });

  final Widget body;
  final BnTab? currentTab;
  final bool bottomNavigation;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: BinovaColors.background,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: BinovaColors.background,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: BinovaColors.background,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: body,
        ),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigation && currentTab != null
            ? BnBottomNav(currentTab: currentTab!)
            : null,
      );
}

class BnBottomNav extends StatelessWidget {
  const BnBottomNav({required this.currentTab, super.key});

  final BnTab currentTab;

  @override
  Widget build(BuildContext context) => BnTabBar(current: currentTab);
}

class BnHeader extends StatelessWidget {
  const BnHeader({
    this.title,
    this.leading,
    this.leadingLabel,
    this.trailing,
    this.large = false,
    super.key,
  });

  final String? title;
  final Widget? leading;
  final String? leadingLabel;
  final Widget? trailing;
  final bool large;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: leading ??
                  (leadingLabel == null
                      ? const SizedBox.shrink()
                      : TextButton.icon(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          icon: const BnAssetIcon('atras', size: 16),
                          label: Text(leadingLabel!),
                        )),
            ),
            Expanded(
              child: Text(
                title ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: large ? 30 : 17,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: large ? -.7 : -.2,
                  color: BinovaColors.carbon,
                ),
              ),
            ),
            SizedBox(
                width: 110,
                child:
                    Align(alignment: Alignment.centerRight, child: trailing)),
          ],
        ),
      );
}

class BnSurfaceCard extends StatelessWidget {
  const BnSurfaceCard(
      {required this.child,
      this.padding,
      this.radius = BinovaRadii.card,
      this.color,
      super.key});

  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding ?? const EdgeInsets.all(BinovaSpacing.lg),
        decoration: BoxDecoration(
          color: color ?? BinovaColors.surface,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      );
}

class BnPrimaryButton extends StatelessWidget {
  const BnPrimaryButton(
      {required this.label,
      this.onPressed,
      this.icon,
      this.loading = false,
      super.key});

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : icon ?? const SizedBox.shrink(),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: BinovaColors.carbon,
            foregroundColor: BinovaColors.surface,
            disabledBackgroundColor: BinovaColors.carbon.withOpacity(.45),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BinovaRadii.input)),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      );
}

class BnOutlineButton extends StatelessWidget {
  const BnOutlineButton(
      {required this.label, this.onPressed, this.icon, super.key});

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon ?? const SizedBox.shrink(),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: BinovaColors.carbon,
            side: const BorderSide(color: BinovaColors.hairline),
            backgroundColor: BinovaColors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BinovaRadii.input)),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      );
}

class BnRoundAction extends StatelessWidget {
  const BnRoundAction(
      {required this.icon,
      required this.label,
      this.onPressed,
      this.enabled = true,
      super.key});

  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 72,
        child: Column(
          children: [
            Semantics(
              button: true,
              label: label,
              child: InkWell(
                onTap: enabled ? onPressed : null,
                customBorder: const CircleBorder(),
                child: AnimatedOpacity(
                  duration: BinovaMotion.fade,
                  opacity: enabled ? 1 : .42,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: BinovaColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: BinovaColors.hairline),
                    ),
                    child: Center(child: BnAssetIcon(icon, size: 22)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: BinovaColors.textSecondary)),
          ],
        ),
      );
}

class BnAvatar extends StatelessWidget {
  const BnAvatar({required this.initials, this.size = 44, super.key});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: BinovaColors.carbon, shape: BoxShape.circle),
        child: Text(initials,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      );
}

class BnStatusDot extends StatelessWidget {
  const BnStatusDot(
      {this.color = BinovaColors.positive, this.label, super.key});

  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(label!,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
        ],
      );
}

class BnBlurSheet extends StatelessWidget {
  const BnBlurSheet({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(BinovaRadii.sheet)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: BinovaColors.background.withOpacity(.96),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: child,
          ),
        ),
      );
}
