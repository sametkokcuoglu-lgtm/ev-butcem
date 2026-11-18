import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../models/card_statement.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';

/// Statement row styled like the dashboard upcoming-payment tiles.
class StatementTile extends StatelessWidget {
  const StatementTile({
    super.key,
    required this.statement,
    required this.onEdit,
    required this.onDelete,
    this.onMarkPaid,
    this.now,
  });

  final CardStatement statement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMarkPaid;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final today = now ?? DateTime.now();
    final status = statement.paymentStatus;
    final urgent = statement.isDueSoon(today) || statement.isOverdue(today);
    final statusColor = switch (status) {
      StatementStatus.paid => AppTheme.incomeColor,
      StatementStatus.partial => AppTheme.warningColor,
      StatementStatus.unpaid => urgent
          ? AppTheme.expenseColor
          : Theme.of(context).colorScheme.onSurfaceVariant,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: urgent
              ? AppTheme.expenseColor.withValues(alpha: 0.35)
              : Colors.grey.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('📄', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kesim ${formatTrDate(statement.periodDate)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Son ödeme: ${formatTrDate(statement.dueDate)} · ${statement.dueLabel(today)}',
                      style: TextStyle(fontSize: 12, color: statusColor),
                    ),
                  ],
                ),
              ),
              Text(
                formatMoney(statement.remainingAmount),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: statement.isSettled ? AppTheme.incomeColor : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatusChip(label: status.label, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ekstre ${formatMoney(statement.totalAmount)} · Ödenen ${formatMoney(statement.paidAmount)}',
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (statement.minimumPayment > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Asgari ${formatMoney(statement.minimumPayment)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onMarkPaid != null && !statement.isSettled)
                TextButton(
                  onPressed: onMarkPaid,
                  child: const Text('Ödendi olarak işaretle'),
                ),
              IconButton(
                tooltip: 'Düzenle',
                onPressed: onEdit,
                icon: const Icon(Iconsax.edit_2, size: 18),
              ),
              IconButton(
                tooltip: 'Sil',
                onPressed: onDelete,
                icon: const Icon(
                  Iconsax.trash,
                  size: 18,
                  color: AppTheme.expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
