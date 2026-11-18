import '../models/transaction.dart';

/// Bir aya ait gelir, gider ve fark toplamları.
class TransactionSummary {
  final double income;
  final double expense;

  const TransactionSummary({this.income = 0, this.expense = 0});

  double get difference => income - expense;

  /// [transactions] içinden [month] ile aynı yıl/aydaki işlemleri toplar.
  factory TransactionSummary.forMonth(
    Iterable<Transaction> transactions,
    DateTime month,
  ) {
    var income = 0.0;
    var expense = 0.0;
    for (final t in transactions) {
      if (t.date.year != month.year || t.date.month != month.month) continue;
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    // Kayan nokta artıklarını kuruşa yuvarla.
    return TransactionSummary(
      income: (income * 100).roundToDouble() / 100,
      expense: (expense * 100).roundToDouble() / 100,
    );
  }
}

/// İşlemleri en yeniden eskiye sıralar (önce işlem tarihi, sonra kayıt anı).
List<Transaction> sortNewestFirst(Iterable<Transaction> transactions) {
  final list = transactions.toList();
  list.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
  });
  return list;
}
