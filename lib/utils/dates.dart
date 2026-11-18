DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Adds calendar months, clamping the day to the end of the target month.
/// 31 Ocak + 1 ay => 28/29 Şubat, + 2 ay => 31 Mart.
DateTime addMonths(DateTime date, int months) {
  final zeroBased = date.month - 1 + months;
  var year = date.year + zeroBased ~/ 12;
  var monthIndex = zeroBased % 12;
  if (monthIndex < 0) {
    monthIndex += 12;
    year -= 1;
  }
  final month = monthIndex + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = date.day > lastDay ? lastDay : date.day;
  return DateTime(year, month, day);
}

DateTime clampDay(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  final safeDay = day < 1 ? 1 : (day > lastDay ? lastDay : day);
  return DateTime(year, month, safeDay);
}

/// Week starts on Monday and ends on Sunday.
DateTime endOfWeek(DateTime day) {
  final date = dateOnly(day);
  return date.add(Duration(days: DateTime.daysPerWeek - date.weekday));
}

/// Monday-first month grid. Null cells are leading or trailing blanks.
List<DateTime?> monthCells(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final days = DateTime(month.year, month.month + 1, 0).day;
  final cells = <DateTime?>[
    for (var i = 0; i < first.weekday - 1; i++) null,
    for (var day = 1; day <= days; day++)
      DateTime(month.year, month.month, day),
  ];
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return cells;
}
