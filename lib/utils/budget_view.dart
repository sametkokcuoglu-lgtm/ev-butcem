import '../demo/demo_finance.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import 'spending_report.dart';

/// Bütçe kartları için kategori + bu ayın harcaması + örnek limit.
class BudgetLine {
  final Category category;
  final double spent;
  final double? limit;

  const BudgetLine({required this.category, required this.spent, required this.limit});

  bool get hasLimit => limit != null && limit! > 0;

  bool get over => hasLimit && spent > limit!;

  double get ratio {
    if (!hasLimit) return 0;
    return spent / limit!;
  }

  double get remaining => (limit ?? 0) - spent;
}

class BudgetView {
  BudgetView._();

  static List<BudgetLine> lines(
    Iterable<Category> categories,
    Iterable<Transaction> transactions,
    DateTime month,
  ) {
    final spent = <String, double>{};
    for (final t in transactions) {
      if (t.isIncome) continue;
      if (t.date.year != month.year || t.date.month != month.month) continue;
      spent[t.categoryId] = (spent[t.categoryId] ?? 0) + t.amount;
    }

    final result = [
      for (final category in categories)
        if (!category.isIncome)
          BudgetLine(
            category: category,
            spent: SpendingReport.roundMoney(spent[category.id] ?? 0),
            limit: DemoFinance.budgetLimitFor(category),
          ),
    ];

    result.sort((a, b) {
      if (a.hasLimit != b.hasLimit) return a.hasLimit ? -1 : 1;
      final byRatio = b.ratio.compareTo(a.ratio);
      if (byRatio != 0) return byRatio;
      return b.spent.compareTo(a.spent);
    });
    return result;
  }

  static double totalLimit(Iterable<BudgetLine> lines) =>
      SpendingReport.roundMoney(lines.fold(0, (sum, line) => sum + (line.limit ?? 0)));

  static double totalSpent(Iterable<BudgetLine> lines) =>
      SpendingReport.roundMoney(lines.fold(0, (sum, line) => sum + (line.hasLimit ? line.spent : 0)));
}
