import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../models/credit_card.dart';
import '../theme/app_theme.dart';
import '../utils/account_style.dart';
import '../utils/money.dart';

class CreditCardListCard extends StatelessWidget {
  const CreditCardListCard({
    super.key,
    required this.card,
    required this.onEdit,
    required this.onDelete,
    this.onOpen,
    this.now,
  });

  final CreditCard card;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpen;

  /// When null, the due-date status is computed from [DateTime.now].
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final today = now ?? DateTime.now();
    final accent = parseHexColor(card.color);
    final scheme = Theme.of(context).colorScheme;
    final urgency = card.dueUrgency(today);
    final statusColor = switch (urgency) {
      DueUrgency.overdue => AppTheme.expenseColor,
      DueUrgency.soon => card.daysRemaining(today) == 0
          ? AppTheme.expenseColor
          : AppTheme.warningColor,
      DueUrgency.normal => scheme.onSurfaceVariant,
    };
    final borderColor = switch (urgency) {
      DueUrgency.overdue => AppTheme.expenseColor.withValues(alpha: 0.45),
      DueUrgency.soon => AppTheme.warningColor.withValues(alpha: 0.55),
      DueUrgency.normal => Colors.grey.withValues(alpha: 0.12),
    };
    final barColor = card.isOverLimit || card.usagePercentage >= 100
        ? AppTheme.expenseColor
        : card.usagePercentage >= 80
            ? AppTheme.warningColor
            : accent;
    final availableColor =
        card.availableLimit < 0 ? AppTheme.expenseColor : AppTheme.incomeColor;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.card, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card.bankName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (card.lastFourDigits != null &&
                    card.lastFourDigits!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '•••• ${card.lastFourDigits}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _AmountColumn(
                    label: 'Limit',
                    amount: formatMoney(card.limit),
                  ),
                ),
                Expanded(
                  child: _AmountColumn(
                    label: 'Borç',
                    amount: formatMoney(card.currentDebt),
                    color: card.currentDebt > 0 ? AppTheme.expenseColor : null,
                  ),
                ),
                Expanded(
                  child: _AmountColumn(
                    label: 'Kullanılabilir',
                    amount: formatMoney(card.availableLimit),
                    color: availableColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: card.usageRatio.clamp(0, 1).toDouble(),
                      minHeight: 8,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      color: barColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '%${card.usagePercentage.round()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: barColor,
                  ),
                ),
              ],
            ),
            if (card.isOverLimit) ...[
              const SizedBox(height: 6),
              const Text(
                'Limit aşıldı',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.expenseColor,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              urgency == DueUrgency.overdue
                  ? 'Sonraki son ödeme: ${formatTrDate(card.nextDueDate(today))}'
                  : 'Son ödeme: ${formatTrDate(card.nextDueDate(today))}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              card.dueStatusLabel(today),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _metaLine(card),
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onOpen != null)
                  TextButton(onPressed: onOpen, child: const Text('Ekstreler')),
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
      ),
    );
  }

  static String _metaLine(CreditCard card) {
    final parts = <String>['Kesim günü: ${card.statementDay}'];
    final minimum = card.minimumPayment;
    if (minimum != null && minimum > 0) {
      parts.add('Asgari: ${formatMoney(minimum)}');
    }
    return parts.join(' · ');
  }
}

class _AmountColumn extends StatelessWidget {
  const _AmountColumn({required this.label, required this.amount, this.color});

  final String label;
  final String amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color ?? scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
