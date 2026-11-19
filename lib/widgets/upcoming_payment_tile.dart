import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/date_groups.dart';
import '../utils/formatters.dart';
import 'app_card.dart';
import 'category_avatar.dart';

class UpcomingPaymentTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double amount;
  final DateTime date;
  final String icon;
  final VoidCallback? onTap;

  const UpcomingPaymentTile({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
    required this.icon,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final days = DateUtils.dateOnly(date).difference(today).inDays;
    final urgent = days <= 3;
    final accent = urgent ? finance.warning : theme.colorScheme.primary;

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.item),
      padding: const EdgeInsets.all(14),
      radius: AppSpacing.radiusMd,
      border: urgent ? Border.all(color: finance.warning.withValues(alpha: 0.45)) : null,
      child: Row(
        children: [
          CategoryAvatar(icon: icon, colorValue: accent.toARGB32(), size: 42),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle == null ? DateGroups.due(date) : '${DateGroups.due(date)} · $subtitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: urgent ? finance.warning : theme.colorScheme.onSurfaceVariant,
                    fontWeight: urgent ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 128),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                AppFormatters.money(amount),
                style: theme.textTheme.titleSmall?.copyWith(color: urgent ? finance.warning : null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
