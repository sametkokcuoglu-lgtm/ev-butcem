import '../models/category.dart';
import '../models/transaction.dart';

/// Grafikler için salt okunur toplamlar. Kayıt yazmaz.
class MonthPoint {
  final DateTime month;
  final double income;
  final double expense;

  const MonthPoint({required this.month, required this.income, required this.expense});
}

class CategorySpend {
  final String id;
  final String name;
  final String icon;
  final int colorValue;
  final double amount;

  const CategorySpend({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.amount,
  });
}

class SpendingReport {
  SpendingReport._();

  static double roundMoney(double value) => (value * 100).roundToDouble() / 100;

  /// [anchor] ayı dahil, geriye doğru [count] ay. Soldan sağa kronolojik.
  static List<MonthPoint> months(
    Iterable<Transaction> transactions,
    DateTime anchor, {
    int count = 6,
  }) {
    final end = DateTime(anchor.year, anchor.month);
    return [
      for (var i = count - 1; i >= 0; i--)
        _month(transactions, DateTime(end.year, end.month - i)),
    ];
  }

  static MonthPoint _month(Iterable<Transaction> transactions, DateTime month) {
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
    return MonthPoint(month: month, income: roundMoney(income), expense: roundMoney(expense));
  }

  /// Seçili aydaki giderleri kategoriye göre, büyükten küçüğe.
  static List<CategorySpend> expensesByCategory(
    Iterable<Transaction> transactions,
    Map<String, Category> categories,
    DateTime month,
  ) {
    final totals = <String, double>{};
    for (final t in transactions) {
      if (t.isIncome) continue;
      if (t.date.year != month.year || t.date.month != month.month) continue;
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }
    final slices = [
      for (final entry in totals.entries)
        if (entry.value > 0)
          CategorySpend(
            id: entry.key,
            name: categories[entry.key]?.name ?? 'Kategorisiz',
            icon: categories[entry.key]?.icon ?? '❔',
            colorValue: categories[entry.key]?.colorValue ?? 0xFF94A3B8,
            amount: roundMoney(entry.value),
          ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return slices;
  }
}
