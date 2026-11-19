import '../models/budget_limit.dart';
import '../models/category.dart';
import '../models/transaction.dart';

/// Spending at or above this share of the limit is a near-limit warning.
const double nearLimitRatio = 0.8;

enum BudgetLevel { ok, near, exceeded }

/// Spent amount versus the monthly limit for one category.
class CategoryBudgetProgress {
  const CategoryBudgetProgress({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.spent,
    required this.limit,
  });

  final String categoryId;
  final String name;
  final String icon;
  final int colorValue;
  final double spent;
  final double limit;

  double get remaining => limit - spent;

  /// Spent divided by the limit. Greater than 1 when the limit is exceeded.
  double get ratio {
    if (limit <= 0) return spent > 0 ? double.infinity : 0;
    return spent / limit;
  }

  BudgetLevel get level {
    if (spent > limit) return BudgetLevel.exceeded;
    if (ratio >= nearLimitRatio) return BudgetLevel.near;
    return BudgetLevel.ok;
  }

  bool get isExceeded => level == BudgetLevel.exceeded;

  bool get isNearLimit => level == BudgetLevel.near;
}

/// Expense total for [categoryId] in [month]. Income and other months are ignored.
double spentInCategory({
  required List<Transaction> transactions,
  required String categoryId,
  required DateTime month,
}) {
  var spent = 0.0;
  for (final transaction in transactions) {
    if (transaction.isIncome) continue;
    if (transaction.categoryId != categoryId) continue;
    final date = transaction.date;
    if (date.year != month.year || date.month != month.month) continue;
    spent += transaction.amount;
  }
  return spent;
}

/// One row per positive limit. Later limits for the same category replace earlier ones.
List<CategoryBudgetProgress> budgetProgress({
  required List<BudgetLimit> limits,
  required List<Transaction> transactions,
  required List<Category> categories,
  required DateTime month,
}) {
  final byCategory = <String, double>{};
  for (final limit in limits) {
    if (limit.amount <= 0) continue;
    byCategory[limit.categoryId] = limit.amount;
  }
  if (byCategory.isEmpty) return const [];

  final categoriesById = {
    for (final category in categories) category.id: category
  };
  final rows = [
    for (final entry in byCategory.entries)
      CategoryBudgetProgress(
        categoryId: entry.key,
        name: categoriesById[entry.key]?.name ?? 'Bilinmeyen kategori',
        icon: categoriesById[entry.key]?.icon ?? '📁',
        colorValue: categoriesById[entry.key]?.colorValue ?? 0xFF64748B,
        spent: spentInCategory(
          transactions: transactions,
          categoryId: entry.key,
          month: month,
        ),
        limit: entry.value,
      ),
  ]..sort((a, b) {
      final byLevel = b.level.index.compareTo(a.level.index);
      if (byLevel != 0) return byLevel;
      final byRatio = b.ratio.compareTo(a.ratio);
      if (byRatio != 0) return byRatio;
      return a.name.compareTo(b.name);
    });
  return rows;
}

/// Snackbar copy when a new expense reaches 80% of its limit or goes over it.
String? budgetAlertMessage(CategoryBudgetProgress progress) {
  if (progress.isExceeded) {
    return 'Limit aşıldı: ${progress.name} kategorisinde bu ayki harcama limiti aşıldı.';
  }
  if (progress.isNearLimit) {
    return 'Limite yaklaşıldı: ${progress.name} harcaması limitin %80\'ine ulaştı.';
  }
  return null;
}

/// Alert for [transaction] using [transactions], including the new transaction
/// when the store has not published it yet.
String? budgetAlertForTransaction({
  required Transaction transaction,
  required List<Transaction> transactions,
  required List<BudgetLimit> limits,
  required List<Category> categories,
}) {
  if (transaction.isIncome) return null;
  final all = transactions.any((item) => item.id == transaction.id)
      ? transactions
      : [...transactions, transaction];
  for (final progress in budgetProgress(
    limits: limits,
    transactions: all,
    categories: categories,
    month: transaction.date,
  )) {
    if (progress.categoryId == transaction.categoryId) {
      return budgetAlertMessage(progress);
    }
  }
  return null;
}
