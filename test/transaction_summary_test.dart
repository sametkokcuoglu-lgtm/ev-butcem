import 'package:ev_butcem/models/transaction.dart';
import 'package:ev_butcem/utils/transaction_summary.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _t(double amount, DateTime date, {bool income = false, DateTime? createdAt}) =>
    Transaction(amount: amount, categoryId: 'c', date: date, isIncome: income, createdAt: createdAt);

void main() {
  final month = DateTime(2026, 11, 19);

  test('Yalnızca seçili ayın gelir ve giderleri toplanır', () {
    final list = [
      _t(42500, DateTime(2026, 11, 1), income: true),
      _t(1500.25, DateTime(2026, 11, 2), income: true),
      _t(850, DateTime(2026, 11, 3)),
      _t(0.1, DateTime(2026, 11, 30)),
      _t(0.2, DateTime(2026, 11, 30)),
      _t(9999, DateTime(2026, 10, 31)), // geçen ay
      _t(9999, DateTime(2025, 11, 5), income: true), // geçen yıl aynı ay
    ];
    final s = TransactionSummary.forMonth(list, month);
    expect(s.income, 44000.25);
    expect(s.expense, 850.3);
    expect(s.difference, closeTo(43149.95, 0.001));
  });

  test('Boş listede toplamlar sıfırdır, gider fazlası negatif farktır', () {
    expect(TransactionSummary.forMonth([], month).difference, 0);
    final s = TransactionSummary.forMonth([_t(100, month, income: true), _t(250, month)], month);
    expect(s.difference, -150);
  });

  test('sortNewestFirst: önce işlem tarihi, eşitse kayıt anı', () {
    final a = _t(1, DateTime(2026, 11, 1), createdAt: DateTime(2026, 11, 1, 9));
    final b = _t(2, DateTime(2026, 11, 5), createdAt: DateTime(2026, 11, 5, 9));
    final c = _t(3, DateTime(2026, 11, 1), createdAt: DateTime(2026, 11, 18, 9)); // geçmişe sonradan girilmiş
    expect(sortNewestFirst([a, b, c]).map((t) => t.amount), [2, 3, 1]);
  });
}
