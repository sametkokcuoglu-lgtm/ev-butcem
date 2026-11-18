import 'package:ev_butcem/models/category.dart';
import 'package:ev_butcem/models/transaction.dart';
import 'package:ev_butcem/utils/report_aggregator.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction tx({
  required double amount,
  required String categoryId,
  required DateTime date,
  required bool isIncome,
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
  final salary = category(id: 'salary', name: 'Maaş', isIncome: true);
  final categories = [market, rent, salary];

  final transactions = [
    tx(
        amount: 1000,
        categoryId: 'salary',
        date: DateTime(2026, 11, 1),
        isIncome: true),
    tx(
        amount: 250.5,
        categoryId: 'salary',
        date: DateTime(2026, 11, 30, 23, 59),
        isIncome: true),
    tx(
        amount: 400,
        categoryId: 'market',
        date: DateTime(2026, 11, 15),
        isIncome: false),
    tx(
        amount: 100,
        categoryId: 'market',
        date: DateTime(2026, 11, 2),
        isIncome: false),
    tx(
        amount: 300,
        categoryId: 'rent',
        date: DateTime(2026, 11, 3),
        isIncome: false),
    tx(
        amount: 999,
        categoryId: 'market',
        date: DateTime(2026, 10, 31),
        isIncome: false),
    tx(
        amount: 50,
        categoryId: 'salary',
        date: DateTime(2026, 12, 1),
        isIncome: true),
    tx(
        amount: 80,
        categoryId: 'missing',
        date: DateTime(2026, 11, 4),
        isIncome: false),
  ];

  test('monthly totals include only the selected month', () {
    final totals = monthlyTotals(transactions, DateTime(2026, 11, 18));

    expect(totals.income, closeTo(1250.5, 0.001));
    expect(totals.expense, closeTo(880, 0.001));
    expect(totals.net, closeTo(370.5, 0.001));
  });

  test('empty month totals are zero', () {
    final totals = monthlyTotals(transactions, DateTime(2025, 1));

    expect(totals.income, 0);
    expect(totals.expense, 0);
    expect(totals.net, 0);
  });

  test('negative net is income minus expense', () {
    final totals = monthlyTotals(
      [
        tx(
            amount: 100,
            categoryId: 'salary',
            date: DateTime(2026, 3, 1),
            isIncome: true),
        tx(
            amount: 250,
            categoryId: 'rent',
            date: DateTime(2026, 3, 2),
            isIncome: false),
      ],
      DateTime(2026, 3),
    );

    expect(totals.net, closeTo(-150, 0.001));
  });

  test('category shares sum expenses and ignore income', () {
    final shares = categoryShares(
      transactions: transactions,
      categories: categories,
      month: DateTime(2026, 11),
      isIncome: false,
    );

    expect(
        shares.map((share) => share.categoryId), ['market', 'rent', 'missing']);
    expect(shares[0].amount, closeTo(500, 0.001));
    expect(shares[0].name, 'Market');
    expect(shares[1].amount, closeTo(300, 0.001));
    expect(shares[2].name, 'Bilinmeyen kategori');
    expect(shares[2].icon, '📁');
    expect(
      shares.fold<double>(0, (sum, share) => sum + share.percentage),
      closeTo(100, 0.001),
    );
    expect(shares[0].percentage, closeTo(500 / 880 * 100, 0.001));
  });

  test('income shares stay separate from expenses', () {
    final shares = categoryShares(
      transactions: transactions,
      categories: categories,
      month: DateTime(2026, 11),
      isIncome: true,
    );

    expect(shares, hasLength(1));
    expect(shares.single.categoryId, 'salary');
    expect(shares.single.amount, closeTo(1250.5, 0.001));
    expect(shares.single.percentage, closeTo(100, 0.001));
  });

  test('equal amounts are ordered by category name', () {
    final shares = categoryShares(
      transactions: [
        tx(
            amount: 40,
            categoryId: 'b',
            date: DateTime(2026, 5, 1),
            isIncome: false),
        tx(
            amount: 40,
            categoryId: 'a',
            date: DateTime(2026, 5, 2),
            isIncome: false),
      ],
      categories: [
        category(id: 'b', name: 'Ulaşım'),
        category(id: 'a', name: 'Market'),
      ],
      month: DateTime(2026, 5),
      isIncome: false,
    );

    expect(shares.map((share) => share.name), ['Market', 'Ulaşım']);
  });

  test('non-positive category sums are omitted from the chart', () {
    final items = [
      tx(
          amount: 0,
          categoryId: 'market',
          date: DateTime(2026, 4, 1),
          isIncome: false),
      tx(
          amount: -10,
          categoryId: 'rent',
          date: DateTime(2026, 4, 2),
          isIncome: false),
    ];

    expect(
      categoryShares(
        transactions: items,
        categories: categories,
        month: DateTime(2026, 4),
        isIncome: false,
      ),
      isEmpty,
    );
    expect(
        monthlyTotals(items, DateTime(2026, 4)).expense, closeTo(-10, 0.001));
  });

  test('recent months span the year boundary and exclude outside months', () {
    final items = [
      tx(
          amount: 10,
          categoryId: 'salary',
          date: DateTime(2025, 8, 20),
          isIncome: true),
      tx(
          amount: 99,
          categoryId: 'salary',
          date: DateTime(2025, 7, 31),
          isIncome: true),
      tx(
          amount: 5,
          categoryId: 'rent',
          date: DateTime(2026, 1, 15),
          isIncome: false),
      tx(
          amount: 77,
          categoryId: 'rent',
          date: DateTime(2026, 2, 1),
          isIncome: false),
    ];

    final months = recentMonths(items, DateTime(2026, 1, 15));

    expect(months, hasLength(6));
    expect(months.first.month, DateTime(2025, 8));
    expect(months.last.month, DateTime(2026, 1));
    expect(months.first.income, 10);
    expect(months.first.expense, 0);
    expect(months.last.expense, 5);
    expect(months.last.income, 0);
    expect(
      months.fold<double>(0, (sum, month) => sum + month.income),
      10,
    );
    expect(
      months.fold<double>(0, (sum, month) => sum + month.expense),
      5,
    );
  });

  test('recent months can return a single month', () {
    final months = recentMonths(transactions, DateTime(2026, 11), count: 1);

    expect(months, hasLength(1));
    expect(months.single.month, DateTime(2026, 11));
    expect(months.single.income, closeTo(1250.5, 0.001));
  });
}
