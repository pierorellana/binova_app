import 'bn_svg.dart';



class BnCategory {
  const BnCategory._(this.label, this.svg);

  final String label;
  final String svg;

  static final _car = BnGlyphs.transport;
  static final _cup = bnLine('<path d="M4 9h13v4a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5z"/><path d="M17 10h1.5a2.5 2.5 0 0 1 0 5H17"/><path d="M8 3v3M12 3v3"/>');
  static final _in = BnGlyphs.income;
  static final _out = bnLine('<path d="M7 17 17 7"/><path d="M9 7h8v8"/>', stroke: 1.7);
  static final _bag = BnGlyphs.shopping;
  static final _bolt = bnLine('<path d="M13 2 4 14h7l-1 8 9-12h-7z"/>');
  static final _card = BnGlyphs.card;
  static final _phone = BnGlyphs.phone;



  static BnCategory of(String key, {bool incoming = false}) {
    switch (key.trim().toLowerCase()) {
      case 'transport':
      case 'transporte':
        return BnCategory._('Transporte', _car);
      case 'food':
      case 'restaurants':
      case 'cafe':
        return BnCategory._('Alimentación', _cup);
      case 'groceries':
      case 'alimentación':
      case 'alimentacion':
        return BnCategory._('Alimentación', _bag);
      case 'transfer':
      case 'transferencia':
        return BnCategory._('Transferencia', incoming ? _in : _out);
      case 'card_payment':
        return BnCategory._('Transferencia', _card);
      case 'services':
      case 'servicios':
      case 'payment':
        return BnCategory._('Servicios', _bolt);
      case 'topup':
      case 'recarga':
        return BnCategory._('Recarga', _phone);
      case 'income':
      case 'salary':
      case 'ingreso':
        return BnCategory._('Ingreso', _in);
      case 'shopping':
      case 'compras':
        return BnCategory._('Compras', _bag);
      case 'other':
      case 'otros':
        return BnCategory._('Otros', _bag);
      default:
        final label = key.isEmpty ? 'Otros' : key[0].toUpperCase() + key.substring(1);
        return BnCategory._(label, incoming ? _in : _bag);
    }
  }
}
