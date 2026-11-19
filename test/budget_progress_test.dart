import 'package:ev_butcem/models/budget_limit.dart';
import 'package:ev_butcem/models/category.dart';
import 'package:ev_butcem/models/transaction.dart';
import 'package:ev_butcem/utils/budget_progress.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction expense({
  required double amount,
  required String categoryId,
  required DateTime date,
  bool isIncome = false,
}) {
  return Transaction(
    amount: amount,
    categoryId: categoryId,
    date: date,
    isIncome: isIncome,
  );
}

Category category({
  required String id,
  required String name,
  bool isIncome = false,
}) {
  return Category(
    id: id,
    name: name,
    icon: '🛒',
    colorValue: 0xFF16A34A,
    isIncome: isIncome,
  );
}

void main() {
  final market = category(id: 'market', name: 'Market');
  final rent = category(id: 'rent', name: 'Kira');
  final month = DateTime(2026, 11, 18);

  test('spent total ignores income and other months', () {
    final spent = spentInCategory(
      transactions: [
        expense(amount: 40, categoryId: 'market', date: DateTime(2026, 11, 1)),
        expense(amount: 10, categoryId: 'market', date: DateTime(2026, 11, 30)),
        expense(
          amount: 99,
          categoryId: 'market',
          date: DateTime(2026, 11, 2),
          isIncome: true,
        ),
        expense(amount: 70, categoryId: 'market', date: DateTime(2026, 10, 31)),
        expense(amount: 15, categoryId: 'rent', date: DateTime(2026, 11, 3)),
      ],
      categoryId: 'market',
      month: month,
    );

    expect(spent, 50);
  });

  test('progress levels mark 80 percent and amounts over the limit', () {
    final rows = budgetProgress(
      limits: [
        BudgetLimit(id: 'ok', categoryId: 'rent', amount: 200),
        BudgetLimit(id: 'near', categoryId: 'market', amount: 100),
        BudgetLimit(id: 'over', categoryId: 'food', amount: 50),
      ],
      transactions: [
        expense(amount: 100, categoryId: 'rent', date: DateTime(2026, 11, 1)),
        expense(amount: 80, categoryId: 'market', date: DateTime(2026, 11, 2)),
        expense(amount: 30, categoryId: 'food', date: DateTime(2026, 11, 3)),
        expense(amount: 25, categoryId: 'food', date: DateTime(2026, 11, 4)),
      ],
      categories: [
        market,
        rent,
        category(id: 'food', name: 'Yemek'),
      ],
      month: month,
    );

    final byId = {for (final row in rows) row.categoryId: row};

    expect(byId['rent']!.spent, 100);
    expect(byId['rent']!.remaining, 100);
    expect(byId['rent']!.ratio, 0.5);
    expect(byId['rent']!.level, BudgetLevel.ok);
    expect(budgetAlertMessage(byId['rent']!), isNull);

    expect(byId['market']!.ratio, 0.8);
    expect(byId['market']!.isNearLimit, isTrue);
    expect(byId['market']!.isExceeded, isFalse);
    expect(byId['market']!.remaining, 20);
    expect(
      budgetAlertMessage(byId['market']!),
      'Limite yaklaşıldı: Market harcaması limitin %80\'ine ulaştı.',
    );

    expect(byId['food']!.spent, 55);
    expect(byId['food']!.remaining, closeTo(-5, 0.001));
    expect(byId['food']!.isExceeded, isTrue);
    expect(
      budgetAlertMessage(byId['food']!),
      'Limit aşıldı: Yemek kategorisinde bu ayki harcama limiti aşıldı.',
    );
    expect(rows.first.categoryId, 'food');
  });

  test('exactly the limit is a warning, not an exceeded state', () {
    final rows = budgetProgress(
      limits: [BudgetLimit(categoryId: 'market', amount: 100)],
      transactions: [
        expense(amount: 100, categoryId: 'market', date: DateTime(2026, 11, 1)),
      ],
      categories: [market],
      month: month,
    );

    expect(rows.single.remaining, 0);
    expect(rows.single.isNearLimit, isTrue);
    expect(rows.single.isExceeded, isFalse);
  });

  test('just under 80 percent stays ok', () {
    final rows = budgetProgress(
      limits: [BudgetLimit(categoryId: 'market', amount: 100)],
      transactions: [
        expense(amount: 79, categoryId: 'market', date: DateTime(2026, 11, 1)),
      ],
      categories: [market],
      month: month,
    );

    expect(rows.single.level, BudgetLevel.ok);
    expect(budgetAlertMessage(rows.single), isNull);
  });

  test('non-positive limits and income transactions do not alert', () {
    expect(
      budgetProgress(
        limits: [BudgetLimit(categoryId: 'market', amount: 0)],
        transactions: [
          expense(
              amount: 40, categoryId: 'market', date: DateTime(2026, 11, 1)),
        ],
        categories: [market],
        month: month,
      ),
      isEmpty,
    );

    final income = expense(
      amount: 500,
      categoryId: 'market',
      date: DateTime(2026, 11, 1),
      isIncome: true,
    );
    expect(
      budgetAlertForTransaction(
        transaction: income,
        transactions: [income],
        limits: [BudgetLimit(categoryId: 'market', amount: 100)],
        categories: [market],
      ),
      isNull,
    );
  });

  test('alert uses the new transaction before the store publishes it', () {
    final added = expense(
      amount: 30,
      categoryId: 'market',
      date: DateTime(2026, 11, 8),
    );
    final message = budgetAlertForTransaction(
      transaction: added,
      transactions: [
        expense(amount: 80, categoryId: 'market', date: DateTime(2026, 11, 1)),
      ],
      limits: [BudgetLimit(categoryId: 'market', amount: 100)],
      categories: [market],
    );

    expect(message, contains('Limit aşıldı'));
    expect(message, contains('Market'));
  });

  test('unknown category still gets a progress row', () {
    final rows = budgetProgress(
      limits: [BudgetLimit(categoryId: 'missing', amount: 20)],
      transactions: [
        expense(amount: 5, categoryId: 'missing', date: DateTime(2026, 11, 1)),
      ],
      categories: const [],
      month: month,
    );

    expect(rows.single.name, 'Bilinmeyen kategori');
    expect(rows.single.icon, '📁');
    expect(rows.single.spent, 5);
  });

  test('a later limit for the same category replaces the earlier one', () {
    final rows = budgetProgress(
      limits: [
        BudgetLimit(categoryId: 'market', amount: 10),
        BudgetLimit(categoryId: 'market', amount: 200),
      ],
      transactions: [
        expense(amount: 50, categoryId: 'market', date: DateTime(2026, 11, 1)),
      ],
      categories: [market],
      month: month,
    );

    expect(rows, hasLength(1));
    expect(rows.single.limit, 200);
    expect(rows.single.level, BudgetLevel.ok);
  });
}
