import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../domain/entities/card.dart';



enum CardSkin {
  debit(
    name: 'Débito',
    fg: Color(0xFFF6F5F2),
    muted: Color(0xFFA8A59E),
    chip: Color(0xFFD8CDB6),
    swatch: Color(0xFF17181B),
    desc: 'Compras y retiros con tu saldo',
    sub: 'Vinculada a Ahorros',
  ),
  credit(
    name: 'Crédito',
    fg: Color(0xFF141518),
    muted: Color(0xFF5F5E5A),
    chip: Color(0xFFD2C6AE),
    swatch: Color(0xFFECE7DE),
    desc: r'Cupo de $3,000',
    sub: null,
  ),
  virtual(
    name: 'Virtual',
    fg: Color(0xFFFFFFFF),
    muted: Color(0xC7FFFFFF),
    chip: Color(0xFFC9C6BF),
    swatch: Color(0xFF7A7772),
    desc: 'Para compras en línea, al instante',
    sub: 'Para compras en línea',
  );

  const CardSkin({
    required this.name,
    required this.fg,
    required this.muted,
    required this.chip,
    required this.swatch,
    required this.desc,
    required this.sub,
  });

  final String name;
  final Color fg;
  final Color muted;
  final Color chip;
  final Color swatch;
  final String desc;



  final String? sub;

  String get title => 'Tarjeta $name';

  static CardSkin of(Card card) {
    if (card.isVirtual || card.type == CardType.virtual) return CardSkin.virtual;
    return card.type == CardType.credit ? CardSkin.credit : CardSkin.debit;
  }
}


class CardVisual {
  const CardVisual({
    required this.id,
    required this.skin,
    required this.last4,
    required this.holder,
    this.card,
  });

  factory CardVisual.of(Card card, String holder) => CardVisual(
        id: card.id,
        skin: CardSkin.of(card),
        last4: cardLast4(card.maskedPan),
        holder: holder,
        card: card,
      );

  final String id;
  final CardSkin skin;
  final String last4;
  final String holder;
  final Card? card;
}


String cardLast4(String maskedPan) {
  final digits = maskedPan.replaceAll(RegExp(r'\D'), '');
  final last = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
  return last.padLeft(4, '•');
}


class CardSkinPainter extends CustomPainter {
  const CardSkinPainter(this.skin, {this.texture = true});

  final CardSkin skin;
  final bool texture;

  @override
  void paint(Canvas canvas, Size size) {

    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final paint = Paint();
    switch (skin) {
      case CardSkin.debit:

        final rx = size.width * 1.3;
        final ry = size.height * 1.4;
        final m = Matrix4.identity()
          ..translate(size.width * .22, size.height * .12)
          ..scale(1.0, ry / rx);
        paint.shader = ui.Gradient.radial(
          Offset.zero,
          rx,
          const [Color(0xFF2E2F35), Color(0xFF17181B), Color(0xFF0E0F11)],
          const [0, .5, 1],
          TileMode.clamp,
          Float64List.fromList(m.storage),
        );
      case CardSkin.credit:
        final (a, b) = _cssLinear(140, size);
        paint.shader =
            ui.Gradient.linear(a, b, const [Color(0xFFF6F3ED), Color(0xFFECE7DE), Color(0xFFE2DCD1)], const [0, .6, 1]);
      case CardSkin.virtual:
        final (a, b) = _cssLinear(150, size);
        paint.shader = ui.Gradient.linear(
            a, b, const [Color(0xFF8E8B85), Color(0xFF6F6D68), Color(0xFF5A5853)], const [0, .55, 1]);
    }
    canvas.drawRect(rect, paint);
    if (!texture) return;
    canvas.save();
    canvas.clipRect(rect);
    switch (skin) {
      case CardSkin.debit:
        break;
      case CardSkin.credit:

        final center = Offset(size.width * 1.15, size.height * 1.2);
        final reach = center.distance;
        final ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x0D141518);
        for (var r = 0.5; r < reach; r += 9) {
          canvas.drawCircle(center, r, ring);
        }
      case CardSkin.virtual:

        final dot = Paint()..color = const Color(0x24FFFFFF);
        for (var y = 5.0; y < size.height; y += 10) {
          for (var x = 5.0; x < size.width; x += 10) {
            canvas.drawCircle(Offset(x, y), 1.1, dot);
          }
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CardSkinPainter oldDelegate) =>
      oldDelegate.skin != skin || oldDelegate.texture != texture;
}



class CardGlarePainter extends CustomPainter {
  const CardGlarePainter({required this.center, required this.alpha});


  final Offset center;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || alpha <= 0) return;
    final c = Offset(center.dx * size.width, center.dy * size.height);
    final reach = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((p) => (p - c).distance).reduce(math.max);
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        c,
        reach,
        [const Color(0xFFFFFFFF).withOpacity(alpha), const Color(0x00FFFFFF)],
        const [0, .55],
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CardGlarePainter oldDelegate) =>
      oldDelegate.center != center || oldDelegate.alpha != alpha;
}


(Offset, Offset) _cssLinear(double degrees, Size size) {
  final a = degrees * math.pi / 180;
  final dir = Offset(math.sin(a), -math.cos(a));
  final length = (size.width * math.sin(a)).abs() + (size.height * math.cos(a)).abs();
  final c = size.center(Offset.zero);
  return (c - dir * (length / 2), c + dir * (length / 2));
}
