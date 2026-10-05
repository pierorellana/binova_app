import 'dart:ui';

import 'package:flutter/cupertino.dart' show CupertinoSliverRefreshControl;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'binova_tokens.dart';
import 'bn_motion.dart';
import 'bn_svg.dart';

enum BnTab { home, products, insights, profile }



const bnTabRoutes = <BnTab, String>{
  BnTab.home: '/home',
  BnTab.products: '/accounts',
  BnTab.insights: '/insights',
  BnTab.profile: '/profile',
};

const _darkStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarBrightness: Brightness.light,
  statusBarIconBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);


const bnScrollPhysics = BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());


double bnTopInset(BuildContext context) {
  final top = MediaQuery.paddingOf(context).top;
  return top > 0 ? top : 20;
}

double bnBottomInset(BuildContext context) => MediaQuery.paddingOf(context).bottom;



class BnScreen extends StatelessWidget {
  const BnScreen({
    required this.child,
    this.background = BnColors.blancoCalido,
    this.overlayStyle = _darkStatusBar,
    this.resizeToAvoidBottomInset = false,
    super.key,
  });

  final Widget child;
  final Color background;
  final SystemUiOverlayStyle overlayStyle;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: Scaffold(
          backgroundColor: background,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          body: child,
        ),
      );
}



class BnTabScaffold extends StatelessWidget {
  const BnTabScaffold({
    required this.tab,
    required this.slivers,
    this.overlays = const [],
    this.onRefresh,
    this.controller,
    super.key,
  });

  final BnTab tab;
  final List<Widget> slivers;
  final List<Widget> overlays;
  final Future<void> Function()? onRefresh;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final top = bnTopInset(context);
    final bottom = BnTabBar.heightOf(context) + 28;
    final scroll = CustomScrollView(
      controller: controller,
      physics: bnScrollPhysics,
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: top)),
        if (onRefresh != null) CupertinoSliverRefreshControlCompat(onRefresh: onRefresh!),
        ...slivers,
        SliverToBoxAdapter(child: SizedBox(height: bottom)),
      ],
    );
    return BnScreen(
      child: Stack(
        children: [
          Positioned.fill(child: scroll),
          Positioned(left: 0, right: 0, bottom: 0, child: BnTabBar(current: tab)),
          ...overlays,
        ],
      ),
    );
  }
}


class CupertinoSliverRefreshControlCompat extends StatelessWidget {
  const CupertinoSliverRefreshControlCompat({required this.onRefresh, super.key});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => CupertinoSliverRefreshControl(onRefresh: onRefresh);
}


class BnTabBar extends StatelessWidget {
  const BnTabBar({required this.current, super.key});

  final BnTab current;

  static double heightOf(BuildContext context) {
    final inset = bnBottomInset(context);
    return 50 + (inset > 0 ? inset : 12);
  }

  @override
  Widget build(BuildContext context) {
    final items = <(BnTab, String, String, String)>[
      (BnTab.home, 'Inicio', BnGlyphs.tabHome, BnGlyphs.tabHomeActive),
      (BnTab.products, 'Productos', BnGlyphs.card, BnGlyphs.tabProductsActive),
      (BnTab.insights, 'Insights', BnGlyphs.bars.replaceAll('stroke-width="1.8"', 'stroke-width="1.6"'), BnGlyphs.tabInsightsActive),
      (BnTab.profile, 'Perfil', BnGlyphs.tabProfile, BnGlyphs.tabProfileActive),
    ];
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: heightOf(context),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          decoration: const BoxDecoration(
            color: BnColors.tabBar,
            border: Border(top: BorderSide(color: BnColors.hairline)),
          ),
          child: Semantics(
            container: true,
            label: 'Navegación principal',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (tab, label, icon, active) in items)
                  Expanded(
                    child: Semantics(
                      selected: tab == current,
                      button: true,
                      label: label,
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: tab == current
                            ? null
                            : () {
                                BnHaptics.tap();
                                Navigator.of(context).pushReplacementNamed(bnTabRoutes[tab]!);
                              },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: SizedBox(
                            height: 48,
                            child: Column(
                              children: [
                                BnSvg(tab == current ? active : icon,
                                    size: 26, color: tab == current ? BnColors.carbon : BnColors.texto3),
                                const SizedBox(height: 3),
                                Text(
                                  label,
                                  style: BnType.tabBar.copyWith(
                                    height: 1.2,
                                    fontWeight: tab == current ? FontWeight.w600 : FontWeight.w500,
                                    color: tab == current ? BnColors.carbon : BnColors.texto3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class BnNavBar extends StatelessWidget {
  const BnNavBar({this.backLabel, this.onBack, this.title, this.trailing, this.showBack = true, super.key});

  final String? backLabel;
  final VoidCallback? onBack;
  final String? title;
  final Widget? trailing;
  final bool showBack;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 96),
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BnType.headline,
                  ),
                ),
              Row(
                children: [
                  if (showBack)
                    BnBackButton(label: backLabel, onTap: onBack ?? () => Navigator.of(context).maybePop()),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ],
          ),
        ),
      );
}

class BnBackButton extends StatelessWidget {
  const BnBackButton({this.label, this.onTap, super.key});

  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => BnPressable(
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        semanticLabel: label == null ? 'Atrás' : 'Volver a $label',
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BnSvg(BnGlyphs.back, size: 24, color: BnColors.carbon),
                if (label != null) ...[
                  const SizedBox(width: 2),
                  Text(label!, style: const TextStyle(fontFamily: BnType.family, fontSize: 17, color: BnColors.carbon)),
                ],
              ],
            ),
          ),
        ),
      );
}


class BnNavTextButton extends StatelessWidget {
  const BnNavTextButton({required this.label, this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => BnPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              widthFactor: 1,
              child: Text(label, style: const TextStyle(fontFamily: BnType.family, fontSize: 17, color: BnColors.carbon)),
            ),
          ),
        ),
      );
}


class BnLargeTitle extends StatelessWidget {
  const BnLargeTitle(this.text, {this.padding = const EdgeInsets.symmetric(horizontal: 20), super.key});

  final String text;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Semantics(header: true, child: Text(text, style: BnType.largeTitle)),
      );
}


class BnSectionHeader extends StatelessWidget {
  const BnSectionHeader(this.title, {this.subtitle, this.action, this.onAction, super.key});

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, style: BnType.tituloSeccion)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: BnType.footnote),
                  ),
              ],
            ),
          ),
          if (action != null)
            BnPressable(
              onTap: onAction,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Center(
                  widthFactor: 1,
                  child: Text(action!, style: const TextStyle(fontFamily: BnType.family, fontSize: 15, fontWeight: FontWeight.w500, color: BnColors.carbon)),
                ),
              ),
            ),
        ],
      );
}

enum BnButtonVariant { primary, secondary, ghost, disabled }


class BnButton extends StatelessWidget {
  const BnButton({
    required this.label,
    this.onTap,
    this.variant = BnButtonVariant.primary,
    this.icon,
    this.height = 54,
    this.fontSize,
    this.loading = false,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final BnButtonVariant variant;
  final Widget? icon;
  final double height;
  final double? fontSize;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading && variant != BnButtonVariant.disabled;
    final (bg, fg, border, weight) = switch (variant) {
      BnButtonVariant.primary => (BnColors.carbon, BnColors.superficie, null, FontWeight.w600),
      BnButtonVariant.secondary => (BnColors.superficie, BnColors.carbon, BnColors.hairline, FontWeight.w500),
      BnButtonVariant.ghost => (const Color(0x00FFFFFF), BnColors.carbon, null, FontWeight.w500),
      BnButtonVariant.disabled => (BnColors.hairline, BnColors.texto3, null, FontWeight.w600),
    };
    final size = fontSize ?? (height >= 54 ? 17.0 : height >= 52 ? 16.0 : 15.0);
    return BnPressable(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: BnMotion.press,
        height: height,
        width: expand ? double.infinity : null,
        padding: expand ? null : const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: border == null ? null : Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator.adaptive(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(fg)))
            else if (icon != null) ...[
              IconTheme(data: IconThemeData(color: fg), child: DefaultTextStyle.merge(style: TextStyle(color: fg), child: icon!)),
              const SizedBox(width: 10),
            ],
            if (!loading)
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: BnType.family, fontSize: size, fontWeight: weight, color: fg),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class BnSegmented<T> extends StatelessWidget {
  const BnSegmented({required this.items, required this.value, required this.onChanged, super.key});

  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: BnColors.rellenoCampo, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: Semantics(
                  selected: items[i].$1 == value,
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (items[i].$1 != value) {
                        BnHaptics.tap();
                        onChanged(items[i].$1);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: BnMotion.entrada,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: items[i].$1 == value ? BnColors.superficie : const Color(0x00FFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: items[i].$1 == value
                            ? const [BoxShadow(color: Color(0x1A141518), blurRadius: 3, offset: Offset(0, 1))]
                            : const [],
                      ),
                      child: Text(
                        items[i].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: BnType.family,
                          fontSize: 13,
                          color: BnColors.carbon,
                          fontWeight: items[i].$1 == value ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}


class BnCard extends StatelessWidget {
  const BnCard({required this.child, this.padding, this.radius = 18, this.color = BnColors.superficie, this.border = true, super.key});

  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final Color color;
  final bool border;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: border ? Border.all(color: BnColors.hairline) : null,
        ),
        child: child,
      );
}


class BnIconTile extends StatelessWidget {
  const BnIconTile({
    required this.svg,
    this.size = 40,
    this.iconSize = 20,
    this.radius = 12,
    this.background = BnColors.relleno,
    this.color = BnColors.carbon,
    this.circle = false,
    super.key,
  });

  final String svg;
  final double size;
  final double iconSize;
  final double radius;
  final Color background;
  final Color color;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
        ),
        child: BnSvg(svg, size: iconSize, color: color),
      );
}


class BnDivider extends StatelessWidget {
  const BnDivider({this.indent = 0, this.color = BnColors.relleno, super.key});

  final double indent;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: indent),
        child: SizedBox(height: 1, width: double.infinity, child: ColoredBox(color: color)),
      );
}


class BnInitialsAvatar extends StatelessWidget {
  const BnInitialsAvatar({required this.initials, this.size = 48, this.fontSize = 15, super.key});

  final String initials;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: BnColors.grafito, shape: BoxShape.circle),
        child: Text(initials,
            style: TextStyle(fontFamily: BnType.family, fontSize: fontSize, fontWeight: FontWeight.w600, color: BnColors.blancoCalido)),
      );
}
