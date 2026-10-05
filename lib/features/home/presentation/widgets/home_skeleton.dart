import 'package:flutter/widgets.dart';

import '../../../../core/design_system/binova_widgets.dart';

/// `Estado-Carga.dc.html`: Home skeleton shown while the dashboard loads.
/// Light blocks use `.sk`, the ones on the grafito card use `.skd`.
class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({super.key});

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = _shimmer;
    Widget sk(double? w, double h, double r) => _Block(animation: a, width: w, height: h, radius: r);
    Widget skd(double? w, double h, double r) => _Block(animation: a, width: w, height: h, radius: r, dark: true);
    Widget circle(double s) => _Block(animation: a, width: s, height: s, radius: s / 2);

    Widget productRow(double nameWidth, {required bool divider}) => Container(
          constraints: const BoxConstraints(minHeight: 72),
          decoration: divider ? const BoxDecoration(border: Border(bottom: BorderSide(color: BnColors.relleno))) : null,
          child: Row(
            children: [
              sk(40, 40, 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [sk(nameWidth, 12, 6), const SizedBox(height: 6), sk(70, 10, 5)],
                ),
              ),
              const SizedBox(width: 12),
              sk(72, 14, 7),
            ],
          ),
        );

    return BnTabScaffold(
      tab: BnTab.home,
      slivers: [
        SliverToBoxAdapter(
          child: Semantics(
            label: 'Cargando tu información',
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        circle(44),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [sk(84, 10, 5), const SizedBox(height: 6), sk(120, 14, 7)],
                          ),
                        ),
                        circle(44),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 196,
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  padding: const EdgeInsets.all(20),
                  decoration:
                      BoxDecoration(color: BnColors.grafito, borderRadius: BorderRadius.circular(BnRadius.saldo)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      skd(80, 12, 6),
                      const SizedBox(height: 14),
                      skd(190, 38, 10),
                      const SizedBox(height: 14),
                      skd(130, 10, 5),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(child: skd(null, 28, 8)),
                          const SizedBox(width: 16),
                          Expanded(child: skd(null, 28, 8)),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    children: [
                      for (final (i, w) in const [52.0, 44.0, 52.0, 32.0].indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: Column(children: [circle(56), const SizedBox(height: 8), sk(w, 10, 5)])),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sk(130, 16, 8),
                      const SizedBox(height: 16),
                      BnCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(children: [productRow(140, divider: true), productRow(120, divider: false)]),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [sk(264, 140, 18), const SizedBox(width: 12), sk(264, 140, 18)]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.animation, required this.height, required this.radius, this.width, this.dark = false});

  final Animation<double> animation;
  final double? width;
  final double height;
  final double radius;
  final bool dark;

  static const _light = [Color(0xFFECEAE5), Color(0xFFF5F3EF)];
  static const _dark = [Color(0xFF24252A), Color(0xFF2E2F35)];

  @override
  Widget build(BuildContext context) {
    final reduce = bnReduceMotion(context);
    final (base, highlight) = dark ? (_dark[0], _dark[1]) : (_light[0], _light[1]);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // background-position 120% → -20% over a 300% wide gradient, ease-in-out.
        final p = reduce ? 0.5 : Curves.easeInOut.transform(animation.value);
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: [base, base, highlight, base, base],
              stops: const [0, .4, .5, .6, 1],
              transform: _Shimmer(1.2 - 1.4 * p),
            ),
          ),
        );
      },
    );
  }
}

class _Shimmer extends GradientTransform {
  const _Shimmer(this.position);

  final double position;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final w = bounds.width;
    return Matrix4.identity()
      ..translate(bounds.left - 2 * w * position, 0.0)
      ..scale(3.0, 1.0, 1.0)
      ..translate(-bounds.left, 0.0);
  }
}
