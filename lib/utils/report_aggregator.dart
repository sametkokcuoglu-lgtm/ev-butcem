import '../models/category.dart';
import '../models/transaction.dart';

/// Income, expense and net balance for a single calendar month.
class MonthlyTotals {
  const MonthlyTotals({required this.income, required this.expense});

  final double income;
  final double expense;

  double get net => income - expense;

  static const empty = MonthlyTotals(income: 0, expense: 0);
}

/// One slice of a category distribution.
class CategoryShare {
  const CategoryShare({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.amount,
    required this.percentage,
  });

  final String categoryId;
  final String name;
  final String icon;
  final int colorValue;
  final double amount;

  /// Share of the positive category total, from 0 to 100.
  final double percentage;
}

/// Income and expense for one month in a short history list.
class MonthSnapshot {
  const MonthSnapshot({
    required this.month,
    required this.income,
    required this.expense,
  });

  /// The first day of the month.
  final DateTime month;
  final double income;
  final double expense;

  double get net => income - expense;
}

/// Sums income and expense for [month], ignoring other months.
MonthlyTotals monthlyTotals(List<Transaction> transactions, DateTime month) {
  final year = month.year;
  final monthNumber = month.month;
  var income = 0.0;
  var expense = 0.0;

  for (final transaction in transactions) {
    final date = transaction.date;
    if (date.year != year || date.month != monthNumber) continue;
    if (transaction.isIncome) {
      income += transaction.amount;
    } else {
      expense += transaction.amount;
    }
  }

  return MonthlyTotals(income: income, expense: expense);
}

/// Groups [transactions] in [month] by category for either income or expense.
///
/// Category sums that are not positive are omitted so they can be drawn on a
/// pie chart. Percentages are shares of the remaining total.
List<CategoryShare> categoryShares({
  required List<Transaction> transactions,
  required List<Category> categories,
  required DateTime month,
  required bool isIncome,
}) {
  final year = month.year;
  final monthNumber = month.month;
  final sums = <String, double>{};

  for (final transaction in transactions) {
    if (transaction.isIncome != isIncome) continue;
    final date = transaction.date;
    if (date.year != year || date.month != monthNumber) continue;
    sums.update(
      transaction.categoryId,
      (total) => total + transaction.amount,
      ifAbsent: () => transaction.amount,
    );
  }

  sums.removeWhere((_, amount) => amount <= 0);
  if (sums.isEmpty) return const [];

  final total = sums.values.fold<double>(0, (sum, amount) => sum + amount);
  final byId = {for (final category in categories) category.id: category};

  final shares = [
    for (final entry in sums.entries)
      CategoryShare(
        categoryId: entry.key,
        name: byId[entry.key]?.name ?? 'Bilinmeyen kategori',
        icon: byId[entry.key]?.icon ?? '📁',
        colorValue: byId[entry.key]?.colorValue ?? 0xFF64748B,
        amount: entry.value,
        percentage: total == 0 ? 0 : (entry.value / total) * 100,
      ),
  ]..sort((a, b) {
      final byAmount = b.amount.compareTo(a.amount);
      if (byAmount != 0) return byAmount;
      return a.name.compareTo(b.name);
    });

  return shares;
}

/// The [count] months ending at [month], oldest first.
List<MonthSnapshot> recentMonths(
  List<Transaction> transactions,
  DateTime month, {
  int count = 6,
}) {
  if (count <= 0) return const [];
  final selected = DateTime(month.year, month.month);
  return List.generate(count, (index) {
    final current = DateTime(
      selected.year,
      selected.month - (count - 1) + index,
    );
    final totals = monthlyTotals(transactions, current);
    return MonthSnapshot(
      month: current,
      income: totals.income,
      expense: totals.expense,
    );
  });
}
