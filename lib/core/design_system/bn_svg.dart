import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders an inline SVG exactly as written in the prototype. `currentColor`
/// resolves to [color] (or the ambient text color), so glyphs inherit color
/// the same way they do in the HTML.
class BnSvg extends StatelessWidget {
  const BnSvg(this.svg, {this.size, this.width, this.height, this.color, super.key});

  final String svg;
  final double? size;
  final double? width;
  final double? height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final current = color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFF141518);
    return SvgPicture.string(
      svg,
      width: width ?? size,
      height: height ?? size,
      theme: SvgTheme(currentColor: current),
      excludeFromSemantics: true,
    );
  }
}

/// Builds a 24×24 line glyph using the prototype's stroke conventions.
String bnLine(String body, {double stroke = 1.6, String viewBox = '0 0 24 24'}) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="$viewBox" fill="none" stroke="currentColor" '
    'stroke-width="$stroke" stroke-linecap="round" stroke-linejoin="round">$body</svg>';

/// Glyphs copied verbatim from the prototype canvases (`fuente/canvas`).
abstract final class BnGlyphs {
  // Navigation / chrome
  static final back = bnLine('<path d="M15 5l-7 7 7 7"/>', stroke: 2);
  static final chevronRight = bnLine('<path d="M9 6l6 6-6 6"/>', stroke: 2);
  static final chevronDown = bnLine('<path d="M6 9l6 6 6-6"/>', stroke: 2);
  static final close = bnLine('<path d="M6 6l12 12M18 6 6 18"/>', stroke: 2.4);
  static final bell = bnLine('<path d="M6 16v-5a6 6 0 0 1 12 0v5l1.5 2h-15z"/><path d="M10 21h4"/>');
  static final eye = bnLine('<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>', stroke: 1.7);
  static final eyeOff = bnLine('<path d="M3 3l18 18"/><path d="M10.6 5.1A10 10 0 0 1 12 5c6.5 0 10 7 10 7a17 17 0 0 1-3.2 4.1"/><path d="M6.6 6.6C3.8 8.4 2 12 2 12s3.5 7 10 7a9.7 9.7 0 0 0 5.4-1.6"/><path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>', stroke: 1.7);
  static final share = bnLine('<path d="M12 3v12"/><path d="M8 7l4-4 4 4"/><path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7"/>', stroke: 1.7);
  static final check = bnLine('<path d="M5 12.5l4.5 4.5L19 7.5"/>', stroke: 2.4);
  static final clock = bnLine('<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>', stroke: 2.2);
  static final exclamation = bnLine('<path d="M12 6v8M12 18h.01"/>', stroke: 2.4);
  static const dots = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" stroke="none"><circle cx="5.5" cy="12" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="18.5" cy="12" r="1.5"/></svg>';

  // Quick actions
  static final transfer = bnLine('<path d="M7 17 17 7"/><path d="M9 7h8v8"/>');
  static final pay = bnLine('<path d="M6 3h12v18l-3-2-3 2-3-2-3 2z"/><path d="M9 8h6M9 12h6"/>');
  static final phone = bnLine('<rect x="7" y="2.5" width="10" height="19" rx="2.5"/><path d="M11 18.5h2"/>');

  // Products
  static final bank = bnLine('<path d="M3 9.5 12 4l9 5.5"/><path d="M5 10v8M9.5 10v8M14.5 10v8M19 10v8"/><path d="M3 20h18"/>');
  static final card = bnLine('<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M3 10h18"/><path d="M7 15h3"/>');
  static final income = bnLine('<path d="M17 7 7 17"/><path d="M15 17H7V9"/>', stroke: 1.7);
  static final trend = bnLine('<path d="M3 17l6-6 4 4 8-8"/><path d="M15 7h6v6"/>', stroke: 1.8);
  static final bars = bnLine('<path d="M3 20h18"/><path d="M6 16v-5"/><path d="M11 16V6"/><path d="M16 16v-8"/>', stroke: 1.8);
  static final globe = bnLine('<circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>', stroke: 1.8);

  // Categories
  static final transport = bnLine('<path d="M5 15.5V11l2-5h10l2 5v4.5"/><path d="M3.5 15.5h17v2.5a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-1h-9v1a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1z"/><path d="M5 11h14"/>');
  static final shopping = bnLine('<path d="M5 8h14l-1 12H6z"/><path d="M9 8V6a3 3 0 0 1 6 0v2"/>');

  // "Más servicios"
  static final cardlessWithdrawal = bnLine('<rect x="4" y="3" width="16" height="18" rx="2.5"/><path d="M8 8h8M8 12h5"/><path d="M14 17h2"/>');
  static final goals = bnLine('<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="4.5"/><circle cx="12" cy="12" r="0.8" fill="currentColor"/>');
  static final investments = bnLine('<path d="M3 17l6-6 4 4 8-8"/><path d="M15 7h6v6"/>');
  static final shield = bnLine('<path d="M12 3l7 3v5.5c0 4.5-3 7.8-7 9.5-4-1.7-7-5-7-9.5V6z"/>');

  // Tab bar (26 px)
  static const tabHomeActive = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="M3.5 10.5 12 3.5l8.5 7V20a1 1 0 0 1-1 1H15v-6H9v6H4.5a1 1 0 0 1-1-1z"/></svg>';
  static final tabHome = bnLine('<path d="M3.5 10.5 12 3.5l8.5 7V20a1 1 0 0 1-1 1H15v-6H9v6H4.5a1 1 0 0 1-1-1z"/>');
  static const tabProductsActive = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M3 10h18"/><path d="M7 15h3"/></svg>';
  static final tabInsightsActive = bnLine('<path d="M3 20h18"/><path d="M6 16v-5"/><path d="M11 16V6"/><path d="M16 16v-8"/>', stroke: 2);
  static final tabProfile = bnLine('<circle cx="12" cy="8" r="4"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"/>');
  static const tabProfileActive = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" fill-opacity="0.12" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"/></svg>';
}
