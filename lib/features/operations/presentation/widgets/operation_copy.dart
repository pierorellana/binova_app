import 'dart:ui' show Color;

import '../../../../core/design_system/binova_tokens.dart';

enum OperationKind { transfer, pay, topup }



class OperationCopy {
  const OperationCopy({
    required this.kind,
    required this.title,
    required this.search,
    required this.listTitle,
    required this.newLabel,
    required this.verb,
    required this.proc,
    required this.okTitle,
    required this.okBody,
    required this.warnTitle,
    required this.warnBody,
    required this.errTitle,
    required this.again,
    required this.change,
    required this.cancelQ,
  });

  final OperationKind kind;
  final String title;
  final String search;
  final String listTitle;
  final String newLabel;
  final String verb;
  final (String, String) proc;
  final String okTitle;
  final String okBody;
  final String warnTitle;
  final String warnBody;
  final String errTitle;
  final String again;
  final String change;
  final String cancelQ;

  static const transfer = OperationCopy(
    kind: OperationKind.transfer,
    title: 'Transferir',
    search: 'Nombre, cuenta o cédula',
    listTitle: 'Contactos',
    newLabel: 'Nuevo destinatario',
    verb: 'Vas a transferir',
    proc: ('Estamos enviando tu dinero', 'Confirmando con el banco destino'),
    okTitle: 'Transferencia realizada',
    okBody: 'Tu transferencia fue enviada correctamente.',
    warnTitle: 'Transferencia en proceso',
    warnBody: 'Estamos esperando confirmación del servicio.',
    errTitle: 'No pudimos completar la transferencia',
    again: 'Otra transferencia',
    change: 'Cambiar monto',
    cancelQ: '¿Cancelar la transferencia?',
  );

  static const pay = OperationCopy(
    kind: OperationKind.pay,
    title: 'Pagar servicios',
    search: 'Buscar servicio o empresa',
    listTitle: 'Tus servicios',
    newLabel: 'Agregar servicio',
    verb: 'Vas a pagar',
    proc: ('Procesando tu pago', 'Confirmando con la empresa'),
    okTitle: 'Pago realizado',
    okBody: 'Tu planilla quedó pagada.',
    warnTitle: 'Pago en proceso',
    warnBody: 'La empresa aún no confirma el pago.',
    errTitle: 'No pudimos completar el pago',
    again: 'Otro pago',
    change: 'Cambiar servicio',
    cancelQ: '¿Cancelar el pago?',
  );

  static const topup = OperationCopy(
    kind: OperationKind.topup,
    title: 'Recargar',
    search: 'Nombre o número',
    listTitle: 'Tus números',
    newLabel: 'Otro número',
    verb: 'Vas a recargar',
    proc: ('Enviando tu recarga', 'Confirmando con la operadora'),
    okTitle: 'Recarga realizada',
    okBody: 'El saldo ya está disponible en la línea.',
    warnTitle: 'Recarga en proceso',
    warnBody: 'La operadora aún no confirma la recarga.',
    errTitle: 'No pudimos completar la recarga',
    again: 'Otra recarga',
    change: 'Cambiar monto',
    cancelQ: '¿Cancelar la recarga?',
  );


  bool get changeGoesToPick => kind == OperationKind.pay;
}


class OperationTarget {
  const OperationTarget({
    required this.id,
    required this.name,
    required this.subtitle,
    this.initials,
    this.icon,
    this.compactLabel,
    this.background = BnColors.relleno,
    this.foreground = BnColors.carbon,
  });

  final String id;
  final String name;
  final String subtitle;


  final String? initials;


  final String? icon;


  final String? compactLabel;
  final Color background;
  final Color foreground;



  String get compactInitials => compactLabel ?? initials ?? '·';


  static (Color, Color) paletteAt(int index) => switch (index) {
        0 => (BnColors.grafito, BnColors.blancoCalido),
        1 => (BnColors.brandNaranjaTinte, BnColors.brandNaranjaTexto),
        _ => (BnColors.relleno, BnColors.carbon),
      };
}
