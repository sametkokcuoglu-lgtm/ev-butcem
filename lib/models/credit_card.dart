import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'credit_card.g.dart';

enum DueUrgency { normal, soon, overdue }

@HiveType(typeId: 3)
class CreditCard extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String bankName;

  /// Total card limit.
  @HiveField(3)
  final double limit;

  @HiveField(4)
  final double currentDebt;

  /// Statement cut-off day (hesap kesim günü), 1-31.
  @HiveField(5)
  final int statementDay;

  /// Payment due day (son ödeme günü), 1-31.
  @HiveField(6)
  final int dueDay;

  @HiveField(7)
  final String? color;

  @HiveField(8)
  final bool isActive;

  @HiveField(9)
  final DateTime createdAt;

  /// Optional last 4 digits. Null on older saves.
  @HiveField(10)
  final String? lastFourDigits;

  /// Optional minimum payment. Null when the user did not enter one.
  @HiveField(11)
  final double? minimumPayment;

  CreditCard({
    String? id,
    required this.name,
    required this.bankName,
    required this.limit,
    this.currentDebt = 0.0,
    required this.statementDay,
    required this.dueDay,
    this.color,
    this.isActive = true,
    DateTime? createdAt,
    this.lastFourDigits,
    this.minimumPayment,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Limit minus current debt. Negative when the debt is above the limit.
  double get availableLimit => limit - currentDebt;

  /// Usage as a percentage (0-100+). Can exceed 100 when debt is over the limit.
  /// A zero or negative limit with debt counts as 100; negative debt counts as 0.
  double get usagePercentage {
    if (limit <= 0) return currentDebt > 0 ? 100 : 0;
    if (currentDebt <= 0) return 0;
    return (currentDebt / limit) * 100;
  }

  /// 0-1 value for progress indicators. Over-limit debt stays at 1.
  double get usageRatio {
    if (limit <= 0) return currentDebt > 0 ? 1 : 0;
    final ratio = currentDebt / limit;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  bool get isOverLimit => currentDebt > limit && currentDebt > 0;

  /// Next payment due date on or after [from] (time of day is ignored).
  ///
  /// When [dueDay] does not exist in the target month (for example 31 in
  /// February), the date is clamped to the last day of that month.
  /// If [from] is after this month's due date, the result is next month.
  DateTime nextDueDate([DateTime? from]) {
    final today = _dateOnly(from ?? DateTime.now());
    final thisMonthDue = dueDateInMonth(today.year, today.month);
    if (!today.isAfter(thisMonthDue)) return thisMonthDue;
    final nextMonth = DateTime(today.year, today.month + 1, 1);
    return dueDateInMonth(nextMonth.year, nextMonth.month);
  }

  /// This month's due date, clamped to the last valid day.
  DateTime dueDateInMonth(int year, int month) =>
      _clampedDate(year, month, _safeDueDay);

  /// Whole days from [from] until [nextDueDate]. Zero when due today.
  int daysRemaining([DateTime? from]) {
    final today = _dateOnly(from ?? DateTime.now());
    return _daysBetween(today, nextDueDate(today));
  }

  /// True after this month's due date until the month ends.
  ///
  /// Payment status is not tracked, so a new month starts a new cycle and
  /// is not treated as overdue. A due day that falls on the last day of the
  /// month therefore has no "overdue" day inside that month.
  bool isOverdue([DateTime? from]) {
    final today = _dateOnly(from ?? DateTime.now());
    return today.isAfter(dueDateInMonth(today.year, today.month));
  }

  /// Days past this month's due date, or 0 when the card is not overdue.
  int daysOverdue([DateTime? from]) {
    if (!isOverdue(from)) return 0;
    final today = _dateOnly(from ?? DateTime.now());
    return _daysBetween(dueDateInMonth(today.year, today.month), today);
  }

  DueUrgency dueUrgency([DateTime? from]) {
    if (isOverdue(from)) return DueUrgency.overdue;
    if (daysRemaining(from) <= 3) return DueUrgency.soon;
    return DueUrgency.normal;
  }

  bool shouldHighlightDue([DateTime? from]) =>
      dueUrgency(from) != DueUrgency.normal;

  String dueStatusLabel([DateTime? from]) {
    if (isOverdue(from)) return '${daysOverdue(from)} gün gecikti';
    final days = daysRemaining(from);
    if (days == 0) return 'Bugün son gün';
    if (days == 1) return 'Yarın';
    return '$days gün kaldı';
  }

  CreditCard copyWith({
    String? name,
    String? bankName,
    double? limit,
    double? currentDebt,
    int? statementDay,
    int? dueDay,
    String? color,
    bool? isActive,
    String? lastFourDigits,
    double? minimumPayment,
    bool clearLastFourDigits = false,
    bool clearMinimumPayment = false,
  }) {
    return CreditCard(
      id: id,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      limit: limit ?? this.limit,
      currentDebt: currentDebt ?? this.currentDebt,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastFourDigits:
          clearLastFourDigits ? null : (lastFourDigits ?? this.lastFourDigits),
      minimumPayment:
          clearMinimumPayment ? null : (minimumPayment ?? this.minimumPayment),
    );
  }

  int get _safeDueDay {
    if (dueDay < 1) return 1;
    if (dueDay > 31) return 31;
    return dueDay;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _clampedDate(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final safeDay = day < 1 ? 1 : (day > lastDay ? lastDay : day);
    return DateTime(year, month, safeDay);
  }

  static int _daysBetween(DateTime from, DateTime to) {
    final start = DateTime.utc(from.year, from.month, from.day);
    final end = DateTime.utc(to.year, to.month, to.day);
    return end.difference(start).inDays;
  }
}
