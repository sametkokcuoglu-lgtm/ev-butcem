import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../utils/format.dart';

class DayMarks {
  const DayMarks({this.hasPayment = false, this.hasIncome = false});

  final bool hasPayment;
  final bool hasIncome;

  bool get isEmpty => !hasPayment && !hasIncome;
}

class FinanceMonthCalendar extends StatelessWidget {
  const FinanceMonthCalendar({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.today,
    required this.marks,
    required this.onSelect,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onJumpToToday,
  });

  final DateTime month;
  final DateTime selectedDay;
  final DateTime today;
  final Map<DateTime, DayMarks> marks;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback? onJumpToToday;

  static const _weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    final cells = monthCells(month);
    final showToday = month.year != today.year || month.month != today.month;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Önceki ay',
                onPressed: onPreviousMonth,
                icon: const Icon(Iconsax.arrow_left_2),
              ),
              Expanded(
                child: Text(
                  formatTrMonth(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Sonraki ay',
                onPressed: onNextMonth,
                icon: const Icon(Iconsax.arrow_right_3),
              ),
            ],
          ),
          if (showToday)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onJumpToToday,
                child: const Text('Bugün'),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final label in _weekdays)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var row = 0; row < cells.length; row += 7)
            Row(
              children: [
                for (final day in cells.sublist(row, row + 7))
                  Expanded(
                    child: _DayCell(
                      day: day,
                      selected: day != null && isSameDay(day, selectedDay),
                      isToday: day != null && isSameDay(day, today),
                      marks: day == null ? null : marks[dateOnly(day)],
                      onTap: day == null ? null : () => onSelect(day),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppTheme.expenseColor, label: 'Ödeme'),
              SizedBox(width: 16),
              _LegendDot(color: AppTheme.incomeColor, label: 'Gelir'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.marks,
    required this.onTap,
  });

  final DateTime? day;
  final bool selected;
  final bool isToday;
  final DayMarks? marks;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (day == null) return const SizedBox(height: 46);

    final textColor =
        selected ? Colors.white : (isToday ? AppTheme.primaryColor : null);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 46,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryColor : null,
                shape: BoxShape.circle,
                border: isToday && !selected
                    ? Border.all(color: AppTheme.primaryColor)
                    : null,
              ),
              child: Text(
                '${day!.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      selected || isToday ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            SizedBox(
              height: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (marks?.hasPayment ?? false)
                    const _Dot(color: AppTheme.expenseColor),
                  if ((marks?.hasPayment ?? false) &&
                      (marks?.hasIncome ?? false))
                    const SizedBox(width: 3),
                  if (marks?.hasIncome ?? false)
                    const _Dot(color: AppTheme.incomeColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}
