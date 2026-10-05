import '../../../../core/design_system/binova_widgets.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../dashboard/domain/entities/dashboard_config.dart';
import '../../../transactions/domain/entities/transaction.dart';

/// Glyphs used only by Home that are not part of [BnGlyphs].
abstract final class HomeGlyphs {
  static final wifiOff = bnLine(
    '<path d="M3 3l18 18"/><path d="M8.5 16.5a5 5 0 0 1 7 0"/><path d="M5 12.5a10 10 0 0 1 4.2-2.4M19 12.5a10 10 0 0 0-3-2"/>'
    '<path d="M2 8.8A15 15 0 0 1 6.1 6.3M22 8.8A15 15 0 0 0 11 5"/><path d="M12 20h.01"/>',
    stroke: 1.8,
  );
  static final clock = bnLine('<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>', stroke: 2);
}

/// Mask used for every amount while the balance is hidden.
const homeMask = '••••';

double? _parse(Object? raw) => raw is num ? raw.toDouble() : double.tryParse('${raw ?? ''}'.replaceAll(',', ''));

double homeAmount(String raw) => _parse(raw) ?? 0;

/// Everything the Home layout needs, derived from the existing controllers.
class HomeData {
  const HomeData({
    required this.symbol,
    required this.balance,
    required this.income,
    required this.expense,
    required this.accounts,
    required this.movements,
    required this.fetchedAt,
  });

  factory HomeData.from({
    required DashboardConfig? config,
    required List<Account> accounts,
    required List<Transaction> transactions,
    required DateTime? fetchedAt,
  }) {
    final payload = <String, dynamic>{
      for (final s in config?.sections ?? const <DashboardSection>[])
        if (s.type == DashboardSectionType.balance) ...s.payload,
    };
    final currency = payload['currency'] as String? ?? (accounts.isEmpty ? 'USD' : accounts.first.currency);

    // Month totals: the dashboard payload when present, otherwise the
    // movements of the current month.
    final now = DateTime.now();
    final month = transactions.where((t) {
      final at = t.occurredAt.toLocal();
      return at.year == now.year && at.month == now.month;
    });
    double sum(TransactionKind kind) =>
        month.where((t) => t.kind == kind).fold(0, (acc, t) => acc + homeAmount(t.amount.amount));

    final balance = _parse(payload['amount']) ??
        accounts
            .where((a) => a.type != AccountType.credit)
            .fold<double>(0, (acc, a) => acc + homeAmount(a.availableBalance.amount));

    return HomeData(
      symbol: BnFormat.currencySymbol(currency),
      balance: balance,
      income: _parse(payload['income']) ?? sum(TransactionKind.income),
      expense: (_parse(payload['expense']) ?? sum(TransactionKind.expense)).abs(),
      accounts: _featured(accounts),
      movements: transactions.take(3).toList(growable: false),
      fetchedAt: fetchedAt,
    );
  }

  /// "Mis productos" on Inicio (Home.dc.html): the main account plus the
  /// credit card; the full list lives in the Productos tab.
  static List<Account> _featured(List<Account> accounts) {
    final main = accounts.where((a) => a.type != AccountType.credit).take(1);
    final credit = accounts.where((a) => a.type == AccountType.credit).take(1);
    final featured = [...main, ...credit];
    return featured.isEmpty ? accounts.take(2).toList(growable: false) : List.unmodifiable(featured);
  }

  final String symbol;
  final double balance;
  final double income;
  final double expense;
  final List<Account> accounts;
  final List<Transaction> movements;
  final DateTime? fetchedAt;

  String money(num value, {bool signed = false}) => BnFormat.money(value, symbol: symbol, signed: signed);

  static String monthName([DateTime? now]) => BnFormat.months[(now ?? DateTime.now()).month - 1];

  /// "Actualizado hace 1 min"
  static String updatedLabel(DateTime? at, [DateTime? now]) {
    if (at == null) return 'Actualizado hace un momento';
    final diff = (now ?? DateTime.now()).difference(at);
    if (diff.inMinutes < 1) return 'Actualizado hace un momento';
    if (diff.inMinutes < 60) return 'Actualizado hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Actualizado hace ${diff.inHours} h';
    return 'Actualizado el ${BnFormat.dateTime(at)}';
  }

  /// "10:43 AM"
  static String clock(DateTime at) => BnFormat.clock12(at);
}
