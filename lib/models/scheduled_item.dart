import 'planned_payment.dart';

enum FinanceKind { planned, bill, creditCard, installment, income, expense }

enum PaymentGroup { overdue, today, thisWeek, later }

extension PaymentGroupLabel on PaymentGroup {
  String get title => switch (this) {
        PaymentGroup.overdue => 'Gecikmiş',
        PaymentGroup.today => 'Bugün',
        PaymentGroup.thisWeek => 'Bu hafta',
        PaymentGroup.later => 'Daha sonra',
      };
}

class ScheduledItem {
  const ScheduledItem({
    required this.id,
    required this.sourceId,
    required this.kind,
    required this.title,
    required this.amount,
    required this.date,
    this.isPaid = false,
    this.canTogglePaid = false,
    this.subtitle,
    this.recurrence,
    this.installmentIndex,
  });

  final String id;
  final String sourceId;
  final FinanceKind kind;
  final String title;
  final double amount;
  final DateTime date;
  final bool isPaid;
  final bool canTogglePaid;
  final String? subtitle;
  final PaymentRecurrence? recurrence;
  final int? installmentIndex;

  bool get isIncome => kind == FinanceKind.income;

  bool get isObligation =>
      kind == FinanceKind.planned ||
      kind == FinanceKind.bill ||
      kind == FinanceKind.creditCard ||
      kind == FinanceKind.installment;

  String get kindLabel => switch (kind) {
        FinanceKind.planned => 'Planlı ödeme',
        FinanceKind.bill => 'Fatura',
        FinanceKind.creditCard => 'Kart son ödeme',
        FinanceKind.installment => 'Taksit',
        FinanceKind.income => 'Gelir',
        FinanceKind.expense => 'Gider',
      };
}

class PaymentSection {
  const PaymentSection({required this.group, required this.items});

  final PaymentGroup group;
  final List<ScheduledItem> items;

  String get title => group.title;
}

class MonthSummary {
  const MonthSummary({
    required this.totalDue,
    required this.paid,
    required this.remaining,
  });

  static const empty = MonthSummary(totalDue: 0, paid: 0, remaining: 0);

  final double totalDue;
  final double paid;
  final double remaining;
}

class MonthFinance {
  const MonthFinance({required this.entries, required this.summary});

  static const empty = MonthFinance(entries: [], summary: MonthSummary.empty);

  final List<ScheduledItem> entries;
  final MonthSummary summary;

  Map<DateTime, List<ScheduledItem>> get byDay {
    final map = <DateTime, List<ScheduledItem>>{};
    for (final entry in entries) {
      final key = DateTime(entry.date.year, entry.date.month, entry.date.day);
      map.putIfAbsent(key, () => []).add(entry);
    }
    return map;
  }
}
