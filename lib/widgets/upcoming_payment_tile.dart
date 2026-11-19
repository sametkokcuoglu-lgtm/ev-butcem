import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../models/scheduled_item.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class UpcomingPaymentTile extends StatelessWidget {
  const UpcomingPaymentTile({
    super.key,
    required this.item,
    required this.now,
    this.onToggle,
    this.onTap,
  });

  final ScheduledItem item;
  final DateTime now;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final overdue =
        item.date.isBefore(DateTime(now.year, now.month, now.day)) &&
            !item.isPaid;
    final urgent =
        !item.isPaid && !overdue && item.date.difference(now).inDays <= 3;
    final accent = overdue || urgent ? AppTheme.expenseColor : Colors.grey;
    final titleStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 15,
      decoration: item.isPaid ? TextDecoration.lineThrough : null,
      color: item.isPaid ? Colors.grey : null,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: overdue
              ? AppTheme.expenseColor.withValues(alpha: 0.35)
              : Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 14, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (onToggle != null)
                Checkbox(
                  key: ValueKey('toggle-${item.id}'),
                  value: item.isPaid,
                  onChanged: (_) => onToggle!(),
                  visualDensity: VisualDensity.compact,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(_iconFor(item.kind), size: 22, color: accent),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: titleStyle),
                    const SizedBox(height: 2),
                    Text(
                      _metaLine(),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatTrDate(item.date)} · ${relativeDayLabel(item.date, now)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: overdue || urgent
                            ? AppTheme.expenseColor
                            : Colors.grey.shade600,
                        fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatTry(item.amount),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  decoration: item.isPaid ? TextDecoration.lineThrough : null,
                  color: item.isPaid
                      ? Colors.grey
                      : (item.isIncome
                          ? AppTheme.incomeColor
                          : (overdue ? AppTheme.expenseColor : null)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _metaLine() {
    final subtitle = item.subtitle;
    if (subtitle == null || subtitle.isEmpty) return item.kindLabel;
    return '${item.kindLabel} · $subtitle';
  }

  IconData _iconFor(FinanceKind kind) => switch (kind) {
        FinanceKind.planned => Iconsax.receipt_item,
        FinanceKind.bill => Iconsax.bill,
        FinanceKind.creditCard => Iconsax.card,
        FinanceKind.installment => Iconsax.calendar_1,
        FinanceKind.income => Iconsax.arrow_down_1,
        FinanceKind.expense => Iconsax.arrow_up_1,
      };
}
