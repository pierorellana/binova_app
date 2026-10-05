/// Money / text formatting that matches the prototype copy:
/// `$5,430.20`, `−$8.50` (U+2212 minus), `+$150.00`.
abstract final class BnFormat {
  static const minus = '−';

  static String _group(String digits) {
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write(',');
      b.write(digits[i]);
    }
    return b.toString();
  }

  /// `1234.5` → `1,234.50`
  static String number(num value, {int decimals = 2}) {
    final fixed = value.abs().toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final integer = _group(parts[0]);
    return decimals == 0 ? integer : '$integer.${parts[1]}';
  }

  /// `$1,234.50` (no sign for positives unless [signed]).
  static String money(num value, {String symbol = r'$', bool signed = false, int decimals = 2}) {
    final body = '$symbol${number(value, decimals: decimals)}';
    if (value < 0) return '$minus$body';
    if (signed && value > 0) return '+$body';
    return body;
  }

  /// Splits `$5,430.20` into (`$5,430`, `.20`) for the large balance style.
  static (String, String) moneyParts(num value, {String symbol = r'$'}) {
    final s = money(value, symbol: symbol);
    final dot = s.lastIndexOf('.');
    if (dot < 0) return (s, '');
    return (s.substring(0, dot), s.substring(dot));
  }

  static String currencySymbol(String code) => switch (code.toUpperCase()) {
        'USD' => r'$',
        'EUR' => '€',
        'GBP' => '£',
        'COP' => r'$',
        'PEN' => 'S/',
        'MXN' => r'$',
        _ => r'$',
      };

  /// Initials from a display name: "Pierre Ortega" → "PO".
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  static String firstName(String name) => name.trim().split(RegExp(r'\s+')).first;

  /// "Buenos días," / "Buenas tardes," / "Buenas noches,"
  static String greeting([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 12) return 'Buenos días,';
    if (h < 19) return 'Buenas tardes,';
    return 'Buenas noches,';
  }

  static const months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
  static const monthsShort = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  static String two(int v) => v.toString().padLeft(2, '0');
  static String time(DateTime d) {
    final l = d.toLocal();
    return '${two(l.hour)}:${two(l.minute)}';
  }

  /// "10:43 AM" (local time).
  static String clock12(DateTime date) {
    final d = date.toLocal();
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${two(d.minute)} ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "Hoy, 08:43" · "Ayer, 18:20" · "28 sep, 10:12"
  static String relativeDay(DateTime date, [DateTime? now]) {
    final d = date.toLocal();
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoy, ${time(d)}';
    if (diff == 1) return 'Ayer, ${time(d)}';
    return '${d.day} ${monthsShort[d.month - 1]}, ${time(d)}';
  }

  /// "Hoy" · "Ayer" · "Lunes 28 de septiembre" style section headers.
  static String daySection(DateTime date, [DateTime? now]) {
    final d = date.toLocal();
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return '${d.day} de ${months[d.month - 1]}';
  }

  /// "3 oct 2026, 14:32"
  static String dateTime(DateTime date) {
    final d = date.toLocal();
    return '${d.day} ${monthsShort[d.month - 1]} ${d.year}, ${time(d)}';
  }
}
