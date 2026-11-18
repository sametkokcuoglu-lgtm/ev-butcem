import '../models/account.dart';
import '../models/credit_card.dart';

abstract final class WalletTotals {
  static Map<String, double> balancesByCurrency(Iterable<Account> accounts) {
    final totals = <String, double>{};
    for (final account in accounts) {
      final code = account.currency.trim().isEmpty
          ? 'TRY'
          : account.currency.toUpperCase();
      totals[code] = (totals[code] ?? 0) + account.balance;
    }
    return totals;
  }

  static List<MapEntry<String, double>> sortedCurrencyTotals(
    Map<String, double> totals,
  ) {
    final entries = totals.entries.toList()
      ..sort((a, b) {
        if (a.key == b.key) return 0;
        if (a.key == 'TRY') return -1;
        if (b.key == 'TRY') return 1;
        return a.key.compareTo(b.key);
      });
    return entries;
  }

  static double totalDebt(Iterable<CreditCard> cards) =>
      cards.fold(0, (sum, card) => sum + card.currentDebt);

  static double totalAvailableLimit(Iterable<CreditCard> cards) =>
      cards.fold(0, (sum, card) => sum + card.availableLimit);
}
