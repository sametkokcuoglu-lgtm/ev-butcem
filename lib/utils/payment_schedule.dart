import '../models/account.dart';
import '../models/category.dart';
import '../models/credit_card.dart';
import '../models/installment.dart';
import '../models/planned_payment.dart';
import '../models/scheduled_item.dart';
import '../models/transaction.dart';
import 'dates.dart';

const int upcomingHorizonDays = 30;

int monthStepFor(PaymentRecurrence recurrence) => switch (recurrence) {
      PaymentRecurrence.none => 0,
      PaymentRecurrence.monthly => 1,
      PaymentRecurrence.yearly => 12,
    };

/// Dates of a series that start at [anchor] and fall inside [start, end].
List<DateTime> occurrenceDates({
  required DateTime anchor,
  required int monthStep,
  required DateTime start,
  required DateTime end,
}) {
  final from = dateOnly(start);
  final to = dateOnly(end);
  final origin = dateOnly(anchor);
  if (to.isBefore(from) || to.isBefore(origin)) return const [];

  if (monthStep <= 0) {
    if (!origin.isBefore(from) && !origin.isAfter(to)) return [origin];
    return const [];
  }

  var index = 0;
  if (origin.isBefore(from)) {
    final months = (from.year - origin.year) * 12 + (from.month - origin.month);
    index = months ~/ monthStep;
  }

  final dates = <DateTime>[];
  for (var guard = 0; guard < 480; guard++) {
    final date = addMonths(origin, index * monthStep);
    if (date.isAfter(to)) break;
    if (!date.isBefore(from)) dates.add(date);
    index++;
  }
  return dates;
}

/// The stored due date, plus later cycles that fall inside the horizon.
/// Missed months between an overdue due date and today are not duplicated;
/// the stored due date is the open obligation.
List<DateTime> upcomingPlannedDates(
  PlannedPayment payment,
  DateTime now, {
  int horizonDays = upcomingHorizonDays,
}) {
  final today = dateOnly(now);
  final horizon = today.add(Duration(days: horizonDays));
  final anchor = dateOnly(payment.dueDate);
  final dates = <DateTime>[];
  if (!anchor.isAfter(horizon)) dates.add(anchor);

  final step = monthStepFor(payment.recurrence);
  if (step == 0) return dates;

  var index = 1;
  while (index < 480) {
    final date = addMonths(anchor, index * step);
    if (date.isAfter(horizon)) break;
    if (!date.isBefore(today)) dates.add(date);
    index++;
  }
  return dates;
}

PaymentGroup? paymentGroupFor(
  DateTime date,
  DateTime now, {
  required bool isPaid,
  int horizonDays = upcomingHorizonDays,
}) {
  final day = dateOnly(date);
  final today = dateOnly(now);
  if (day.isBefore(today)) {
    return isPaid ? null : PaymentGroup.overdue;
  }
  final horizon = today.add(Duration(days: horizonDays));
  if (day.isAfter(horizon)) return null;
  if (isSameDay(day, today)) return PaymentGroup.today;
  if (!day.isAfter(endOfWeek(today))) return PaymentGroup.thisWeek;
  return PaymentGroup.later;
}

List<PaymentSection> groupScheduledItems(
  List<ScheduledItem> items,
  DateTime now, {
  int horizonDays = upcomingHorizonDays,
}) {
  final buckets = <PaymentGroup, List<ScheduledItem>>{};
  for (final item in items) {
    final group = paymentGroupFor(
      item.date,
      now,
      isPaid: item.isPaid,
      horizonDays: horizonDays,
    );
    if (group == null) continue;
    buckets.putIfAbsent(group, () => []).add(item);
  }

  for (final list in buckets.values) {
    list.sort(_byDateThenTitle);
  }

  return [
    for (final group in PaymentGroup.values)
      if (buckets[group]?.isNotEmpty ?? false)
        PaymentSection(group: group, items: buckets[group]!),
  ];
}

List<ScheduledItem> previewUpcoming(List<PaymentSection> sections,
    {int limit = 3}) {
  return sections.expand((section) => section.items).take(limit).toList();
}

List<PaymentSection> buildUpcomingSections({
  required DateTime now,
  required List<PlannedPayment> planned,
  required List<CreditCard> cards,
  required List<Installment> installments,
  List<Account> accounts = const [],
  List<Category> categories = const [],
  int horizonDays = upcomingHorizonDays,
}) {
  final names =
      _NameLookup(accounts: accounts, categories: categories, cards: cards);
  final items = <ScheduledItem>[
    for (final payment in planned)
      ..._plannedUpcoming(payment, now, names, horizonDays),
    for (final card in cards) ..._cardUpcoming(card, now),
    for (final installment in installments)
      ...installmentOccurrences(installment,
              cardName: names.card(installment.creditCardId))
          .where((item) =>
              paymentGroupFor(item.date, now,
                  isPaid: item.isPaid, horizonDays: horizonDays) !=
              null),
  ];
  return groupScheduledItems(items, now, horizonDays: horizonDays);
}

MonthFinance buildMonthFinance({
  required DateTime month,
  required DateTime today,
  required List<PlannedPayment> planned,
  required List<CreditCard> cards,
  required List<Installment> installments,
  List<Account> accounts = const [],
  List<Category> categories = const [],
  List<Transaction> transactions = const [],
}) {
  final names =
      _NameLookup(accounts: accounts, categories: categories, cards: cards);
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);
  final entries = <ScheduledItem>[
    for (final payment in planned)
      ..._plannedInRange(payment, start, end, names),
    for (final card in cards) ..._cardInMonth(card, month, today),
    for (final installment in installments)
      ...installmentOccurrences(installment,
              cardName: names.card(installment.creditCardId))
          .where(
        (item) => !item.date.isBefore(start) && !item.date.isAfter(end),
      ),
    ..._transactionsInRange(transactions, start, end, names),
  ]..sort(_byDateThenTitle);

  return MonthFinance(entries: entries, summary: summarizeObligations(entries));
}

MonthSummary summarizeObligations(List<ScheduledItem> entries) {
  var total = 0.0;
  var paid = 0.0;
  for (final entry in entries) {
    if (!entry.isObligation) continue;
    total += entry.amount;
    if (entry.isPaid) paid += entry.amount;
  }
  return MonthSummary(totalDue: total, paid: paid, remaining: total - paid);
}

List<ScheduledItem> installmentOccurrences(Installment installment,
    {String? cardName}) {
  if (installment.totalInstallments <= 0) return const [];
  final origin = dateOnly(installment.startDate);
  return [
    for (var index = 0; index < installment.totalInstallments; index++)
      ScheduledItem(
        id: 'installment:${installment.id}:$index',
        sourceId: installment.id,
        kind: FinanceKind.installment,
        title: installment.title,
        amount: installment.monthlyAmount,
        date: addMonths(origin, index),
        isPaid: index < installment.paidInstallments,
        canTogglePaid: index == installment.paidInstallments ||
            index == installment.paidInstallments - 1,
        installmentIndex: index,
        subtitle: _installmentSubtitle(
          index: index,
          total: installment.totalInstallments,
          cardName: cardName,
        ),
      ),
  ];
}

List<ScheduledItem> _plannedUpcoming(
  PlannedPayment payment,
  DateTime now,
  _NameLookup names,
  int horizonDays,
) {
  return [
    for (final date
        in upcomingPlannedDates(payment, now, horizonDays: horizonDays))
      _plannedItem(payment, date, names),
  ];
}

List<ScheduledItem> _plannedInRange(
  PlannedPayment payment,
  DateTime start,
  DateTime end,
  _NameLookup names,
) {
  return [
    for (final date in occurrenceDates(
      anchor: payment.dueDate,
      monthStep: monthStepFor(payment.recurrence),
      start: start,
      end: end,
    ))
      _plannedItem(payment, date, names),
  ];
}

ScheduledItem _plannedItem(
    PlannedPayment payment, DateTime date, _NameLookup names) {
  final anchor = dateOnly(payment.dueDate);
  final day = dateOnly(date);
  return ScheduledItem(
    id: 'planned:${payment.id}:${_dateKey(day)}',
    sourceId: payment.id,
    kind: FinanceKind.planned,
    title: payment.title,
    amount: payment.amount,
    date: day,
    isPaid: payment.isPaid && isSameDay(day, anchor),
    canTogglePaid: isSameDay(day, anchor),
    recurrence: payment.recurrence,
    subtitle: _joinParts([
      if (payment.recurrence != PaymentRecurrence.none)
        payment.recurrence.label,
      names.category(payment.categoryId),
      names.card(payment.creditCardId),
      names.account(payment.accountId),
    ]),
  );
}

List<ScheduledItem> _cardUpcoming(CreditCard card, DateTime now) {
  if (!card.isActive || card.currentDebt <= 0) return const [];
  final today = dateOnly(now);
  return _cardInMonth(card, today, today);
}

List<ScheduledItem> _cardInMonth(
    CreditCard card, DateTime month, DateTime today) {
  if (!card.isActive || card.currentDebt <= 0) return const [];
  final monthStart = DateTime(month.year, month.month);
  final currentMonth = DateTime(today.year, today.month);
  if (monthStart.isBefore(currentMonth)) return const [];

  final date = clampDay(month.year, month.month, card.dueDay);
  return [
    ScheduledItem(
      id: 'card:${card.id}:${date.year}-${date.month}',
      sourceId: card.id,
      kind: FinanceKind.creditCard,
      title: card.name,
      amount: card.currentDebt,
      date: date,
      subtitle: _joinParts([card.bankName, 'Son ödeme günü']),
    ),
  ];
}

List<ScheduledItem> _transactionsInRange(
  List<Transaction> transactions,
  DateTime start,
  DateTime end,
  _NameLookup names,
) {
  final items = <ScheduledItem>[];
  for (final transaction in transactions) {
    final date = dateOnly(transaction.date);
    if (date.isBefore(start) || date.isAfter(end)) continue;
    final category = names.category(transaction.categoryId);
    final note = transaction.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    items.add(
      ScheduledItem(
        id: 'tx:${transaction.id}',
        sourceId: transaction.id,
        kind: transaction.isIncome ? FinanceKind.income : FinanceKind.expense,
        title: hasNote
            ? note
            : (category ?? (transaction.isIncome ? 'Gelir' : 'Gider')),
        amount: transaction.amount,
        date: date,
        isPaid: true,
        subtitle: hasNote ? category : null,
      ),
    );
  }
  return items;
}

String _installmentSubtitle({
  required int index,
  required int total,
  String? cardName,
}) {
  return _joinParts([cardName, '${index + 1}/$total taksit'])!;
}

String? _joinParts(List<String?> parts) {
  final values = <String>[
    for (final part in parts)
      if (part != null && part.trim().isNotEmpty) part.trim(),
  ];
  if (values.isEmpty) return null;
  return values.join(' · ');
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

int _byDateThenTitle(ScheduledItem a, ScheduledItem b) {
  final byDate = a.date.compareTo(b.date);
  if (byDate != 0) return byDate;
  final byKind = a.kind.index.compareTo(b.kind.index);
  if (byKind != 0) return byKind;
  return a.title.compareTo(b.title);
}

class _NameLookup {
  _NameLookup({
    required List<Account> accounts,
    required List<Category> categories,
    required List<CreditCard> cards,
  })  : _accounts = {for (final account in accounts) account.id: account.name},
        _categories = {
          for (final category in categories) category.id: category.name
        },
        _cards = {for (final card in cards) card.id: card.name};

  final Map<String, String> _accounts;
  final Map<String, String> _categories;
  final Map<String, String> _cards;

  String? account(String? id) => id == null ? null : _accounts[id];
  String? category(String? id) => id == null ? null : _categories[id];
  String? card(String? id) => id == null ? null : _cards[id];
}
