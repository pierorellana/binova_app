import 'package:flutter/material.dart';

/// BInova design tokens, generated from the prototype
/// (`assets/tokens/binova-tokens.json`). The `Bn*` classes are the source of
/// truth; the `Binova*` classes are kept as aliases for older call sites.
abstract final class BnColors {
  static const brandNaranjaBi = Color(0xFFFF9000);
  static const brandNaranjaTinte = Color(0xFFFFF1DF);
  static const brandNaranjaTexto = Color(0xFFA85A00);
  static const carbon = Color(0xFF141518);
  static const grafito = Color(0xFF17181B);
  static const grafitoAlto = Color(0xFF2C2D33);
  static const grafitoBajo = Color(0xFF0E0F11);
  static const blancoCalido = Color(0xFFF6F5F2);
  static const superficie = Color(0xFFFFFFFF);
  static const superficieAlt = Color(0xFFFBFAF8);
  static const relleno = Color(0xFFEFEDE9);
  static const rellenoCampo = Color(0xFFEBE9E4);
  static const hairline = Color(0xFFE4E1DB);
  static const divisorSuave = Color(0xFFE9E6E1);
  static const lineaFuerte = Color(0xFFD6D2CA);
  static const texto2 = Color(0xFF5F5E5A);
  static const texto3 = Color(0xFF6F6D68);
  static const texto4 = Color(0xFF8E8B85);
  static const texto5 = Color(0xFFA8A59E);
  static const piedra = Color(0xFFC9C6BF);
  static const placeholder = Color(0xFF77756F);
  static const rowPressed = Color(0xFFF1EFEB);
  static const tabBar = Color(0xE6FAF9F7);
  static const skeleton = Color(0xFFECEAE5);
  static const skeletonHighlight = Color(0xFFF5F3EF);
  static const positivo = Color(0xFF177245);
  static const positivoFondo = Color(0xFFE6F2EB);
  static const positivoPunto = Color(0xFF3FB27F);
  static const precaucion = Color(0xFF8A510A);
  static const precaucionFondo = Color(0xFFF7EEDF);
  static const precaucionPunto = Color(0xFFC27A12);
  static const critico = Color(0xFFB3261E);
  static const criticoFondo = Color(0xFFF9E9E7);
  static const criticoBorde = Color(0xFFE0B4AF);
  static const criticoTexto = Color(0xFF8C1D18);
  static const chip = Color(0xFFD8CDB6);
  static const scrim = Color(0x52141518);
}

abstract final class BnSpacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double screen = 20;
  static const double safeTop = 59;
  static const double safeBottom = 34;
  static const double tabBar = 84;
}

abstract final class BnRadius {
  static const double chip = 9;
  static const double segmento = 8;
  static const double segmented = 10;
  static const double tileIcono = 12;
  static const double input = 16;
  static const double boton = 16;
  static const double card = 18;
  static const double cardGrande = 20;
  static const double saldo = 24;
  static const double sheet = 28;
  static const double tarjetaBancaria = 20;
  static const double pantalla = 55;
}

/// Text styles. Letter spacing in the prototype is expressed in `em`; the
/// values here are already converted to logical pixels.
abstract final class BnType {
  static const String family = 'Geist';
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static const saldo = TextStyle(fontFamily: family, fontSize: 42, fontWeight: FontWeight.w600, letterSpacing: -1.47, height: 1.1, color: BnColors.carbon, fontFeatures: tabular);
  static const montoOperacion = TextStyle(fontFamily: family, fontSize: 68, fontWeight: FontWeight.w600, letterSpacing: -2.72, color: BnColors.carbon, fontFeatures: tabular);
  static const largeTitle = TextStyle(fontFamily: family, fontSize: 34, fontWeight: FontWeight.w600, letterSpacing: -1.19, height: 1.2, color: BnColors.carbon);
  static const tituloPantalla = TextStyle(fontFamily: family, fontSize: 30, fontWeight: FontWeight.w600, letterSpacing: -0.90, height: 1.12, color: BnColors.carbon);
  static const tituloResultado = TextStyle(fontFamily: family, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.44, color: BnColors.carbon);
  static const tituloSeccion = TextStyle(fontFamily: family, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.40, color: BnColors.carbon);
  static const headline = TextStyle(fontFamily: family, fontSize: 17, fontWeight: FontWeight.w600, color: BnColors.carbon);
  static const body = TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w500, color: BnColors.carbon);
  static const subhead = TextStyle(fontFamily: family, fontSize: 15, fontWeight: FontWeight.w400, color: BnColors.carbon);
  static const footnote = TextStyle(fontFamily: family, fontSize: 13, fontWeight: FontWeight.w400, color: BnColors.texto3);
  static const caption = TextStyle(fontFamily: family, fontSize: 12, fontWeight: FontWeight.w500, color: BnColors.texto3);
  static const tabBar = TextStyle(fontFamily: family, fontSize: 10, fontWeight: FontWeight.w500);
}

abstract final class BnMotion {
  static const Curve entrada = Cubic(0.2, 0.8, 0.2, 1.0);
  static const Curve cambioEstado = Cubic(0.65, 0.0, 0.35, 1.0);
  static const Curve salida = Cubic(0.4, 0.0, 1.0, 1.0);
  static const Curve springSuave = Cubic(0.32, 0.72, 0.0, 1.0);
  static const Curve entradaExpresiva = Cubic(0.16, 1.0, 0.3, 1.0);
  static const Curve vibracion = Cubic(0.36, 0.07, 0.19, 0.97);
  static const Curve estandar = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Duration press = Duration(milliseconds: 160);
  static const Duration pushNavegacion = Duration(milliseconds: 280);
  static const Duration staggerEntreFilas = Duration(milliseconds: 40);
  static const Duration fadePantalla = Duration(milliseconds: 180);
  static const Duration sheet = Duration(milliseconds: 440);
  static const Duration veloSheet = Duration(milliseconds: 300);
  static const Duration sharedElement = Duration(milliseconds: 340);
  static const Duration morphResultado = Duration(milliseconds: 460);
  static const Duration conteoMonto = Duration(milliseconds: 650);
  static const Duration tarjetaAlApilar = Duration(milliseconds: 720);
  static const Duration construccionTarjeta = Duration(milliseconds: 1500);
  static const Duration loaderInclinacion = Duration(milliseconds: 2400);
  static const Duration loaderTrazo = Duration(milliseconds: 1600);
  static const Duration faceIdEscaneo = Duration(milliseconds: 1300);
  static const Duration procesamientoMinimo = Duration(milliseconds: 1200);
  static const Duration splash = Duration(milliseconds: 2470);
  static const double pressScale = 0.97;
}

// ---------------------------------------------------------------------------
// Legacy aliases (kept so non-UI code and older widgets keep compiling).
// ---------------------------------------------------------------------------
abstract final class BinovaColors {
  static const background = BnColors.blancoCalido;
  static const surface = BnColors.superficie;
  static const carbon = BnColors.carbon;
  static const graphite = BnColors.grafito;
  static const orange = BnColors.brandNaranjaBi;
  static const orangeTint = BnColors.brandNaranjaTinte;
  static const orangeText = BnColors.brandNaranjaTexto;
  static const positive = BnColors.positivo;
  static const positiveTint = BnColors.positivoFondo;
  static const warning = BnColors.precaucion;
  static const warningTint = BnColors.precaucionFondo;
  static const critical = BnColors.critico;
  static const criticalTint = BnColors.criticoFondo;
  static const textSecondary = BnColors.texto2;
  static const textTertiary = BnColors.texto3;
  static const textQuaternary = BnColors.texto4;
  static const hairline = BnColors.hairline;
  static const muted = BnColors.texto3;
  static const border = BnColors.hairline;
  static const chip = BnColors.chip;
}

abstract final class BinovaSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;
}

abstract final class BinovaRadii {
  static const input = BnRadius.input;
  static const card = BnRadius.card;
  static const balance = BnRadius.saldo;
  static const sheet = BnRadius.sheet;
  static const largeCard = BnRadius.cardGrande;
  static const bankCard = BnRadius.tarjetaBancaria;
  static const screen = BnRadius.pantalla;
}

abstract final class BinovaMotion {
  static const press = BnMotion.press;
  static const navigation = BnMotion.pushNavegacion;
  static const fade = BnMotion.fadePantalla;
  static const sheet = BnMotion.sheet;
  static const shared = BnMotion.sharedElement;
  static const result = BnMotion.morphResultado;
  static const cardStack = BnMotion.tarjetaAlApilar;
  static const cardConstruction = BnMotion.construccionTarjeta;
}
