import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'card_statement.g.dart';

enum StatementStatus {
  unpaid('unpaid', 'Ödenmedi'),
  partial('partial', 'Kısmi'),
  paid('paid', 'Ödendi');

  const StatementStatus(this.storageKey, this.label);

  final String storageKey;
  final String label;

  static StatementStatus fromStorage(String? value) {
    for (final status in StatementStatus.values) {
      if (status.storageKey == value || status.name == value) return status;
    }
    return StatementStatus.unpaid;
  }

  static StatementStatus fromAmounts(double total, double paid) {
    if (paid <= 0) return StatementStatus.unpaid;
    if (paid + 0.009 >= total) return StatementStatus.paid;
    return StatementStatus.partial;
  }
}

/// How a card balance changes when a statement's paid amount changes.
///
/// Debt moves by the difference in paid amount, so editing or deleting a
/// statement puts the card back where it was.
abstract final class StatementLedger {
  static double debtAfterPaidChange({
    required double debt,
    required double previousPaid,
    required double nextPaid,
  }) {
    return _roundMoney(debt - (nextPaid - previousPaid));
  }

  static double _roundMoney(double value) => (value * 100).round() / 100.0;
}

@HiveType(typeId: 5)
class CardStatement extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String creditCardId;

  /// Statement cut-off date (hesap kesim tarihi).
  @HiveField(2)
  final DateTime periodDate;

  /// Payment due date (son ödeme tarihi).
  @HiveField(3)
  final DateTime dueDate;

  /// Statement total (ekstre tutarı).
  @HiveField(4)
  final double totalAmount;

  @HiveField(5, defaultValue: 0)
  final double minimumPayment;

  @HiveField(6, defaultValue: 0)
  final double paidAmount;

  /// `unpaid`, `partial` or `paid`. Missing values are treated as unpaid.
  @HiveField(7, defaultValue: 'unpaid')
  final String status;

  @HiveField(8)
  final DateTime createdAt;

  CardStatement({
    String? id,
    required this.creditCardId,
    required this.periodDate,
    required this.dueDate,
    required this.totalAmount,
    this.minimumPayment = 0,
    this.paidAmount = 0,
    this.status = 'unpaid',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  StatementStatus get paymentStatus =>
      StatementStatus.fromAmounts(totalAmount, paidAmount);

  double get remainingAmount {
    final remaining = totalAmount - paidAmount;
    return remaining <= 0 ? 0 : remaining;
  }

  bool get isSettled => paymentStatus == StatementStatus.paid;

  int daysUntilDue([DateTime? from]) {
    final today = _dateOnly(from ?? DateTime.now());
    final due = _dateOnly(dueDate);
    final start = DateTime.utc(today.year, today.month, today.day);
    final end = DateTime.utc(due.year, due.month, due.day);
    return end.difference(start).inDays;
  }

  bool isOverdue([DateTime? from]) => !isSettled && daysUntilDue(from) < 0;

  bool isDueSoon([DateTime? from]) {
    if (isSettled) return false;
    return daysUntilDue(from) <= 3;
  }

  String dueLabel([DateTime? from]) {
    if (isSettled) return 'Ödendi';
    final days = daysUntilDue(from);
    if (days < 0) return '${-days} gün gecikti';
    if (days == 0) return 'Bugün son gün';
    if (days == 1) return 'Yarın';
    return '$days gün kaldı';
  }

  CardStatement normalized() {
    final derived = paymentStatus;
    return CardStatement(
      id: id,
      creditCardId: creditCardId,
      periodDate: _dateOnly(periodDate),
      dueDate: _dateOnly(dueDate),
      totalAmount: totalAmount,
      minimumPayment: minimumPayment < 0 ? 0 : minimumPayment,
      paidAmount: paidAmount < 0 ? 0 : paidAmount,
      status: derived.storageKey,
      createdAt: createdAt,
    );
  }

  CardStatement markPaid() {
    return CardStatement(
      id: id,
      creditCardId: creditCardId,
      periodDate: periodDate,
      dueDate: dueDate,
      totalAmount: totalAmount,
      minimumPayment: minimumPayment,
      paidAmount: totalAmount,
      status: StatementStatus.paid.storageKey,
      createdAt: createdAt,
    ).normalized();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
