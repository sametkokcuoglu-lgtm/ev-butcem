import 'package:flutter/material.dart';

import '../demo/demo_finance.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/date_groups.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/content_frame.dart';
import '../widgets/info_banner.dart';
import '../widgets/status_chip.dart';

class StatementsScreen extends StatelessWidget {
  const StatementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final statements = DemoFinance.statements();
    final debt = statements.fold(0.0, (sum, s) => sum + s.periodDebt);

    return Scaffold(
      appBar: AppBar(title: const Text('Ekstreler')),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xl),
          children: [
            _DebtHero(amount: debt, count: statements.length),
            const SizedBox(height: AppSpacing.md),
            const InfoBanner(
              text: 'Ekstreler örnek kartlardır. Kredi kartı kayıtları bağlanınca dönem borcu buradan gelecek.',
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 640;
                if (!wide) {
                  return Column(
                    children: [
                      for (final statement in statements) ...[
                        _StatementCard(statement: statement),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  );
                }
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final statement in statements)
                      SizedBox(
                        width: (constraints.maxWidth - AppSpacing.md) / 2,
                        child: _StatementCard(statement: statement),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtHero extends StatelessWidget {
  final double amount;
  final int count;

  const _DebtHero({required this.amount, required this.count});

  @override
  Widget build(BuildContext context) {
    final finance = FinanceColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [finance.heroStart, finance.heroMid, finance.heroEnd],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card_rounded, color: Colors.white.withValues(alpha: 0.85), size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '$count kart · dönem borcu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppFormatters.money(amount),
              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  final DemoStatement statement;

  const _StatementCard({required this.statement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final due = DateGroups.due(statement.dueDate);
    final clear = statement.periodDebt <= 0;
    final soon = !clear && (due == 'Bugün' || due == 'Yarın' || due.endsWith('gün sonra') && _days(due) <= 5);
    final statusLabel = clear ? 'Borç yok' : (statement.dueDate.isBefore(DateUtils.dateOnly(DateTime.now())) ? 'Gecikti' : (soon ? 'Yaklaşıyor' : 'Ödeme bekliyor'));
    final statusColor = clear ? finance.income : (statusLabel == 'Gecikti' ? finance.expense : finance.warning);
    final colors = statement.gradient.map(Color.new).toList();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        statement.bankName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.credit_card_rounded, color: Colors.white, size: 22),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  statement.cardName,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '•••• ${statement.last4}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 1.2, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _Fact(label: 'Dönem borcu', value: AppFormatters.money(statement.periodDebt), emphasize: true),
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                _Fact(label: 'Asgari ödeme', value: AppFormatters.money(statement.minimumPayment)),
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                _Fact(
                  label: 'Son ödeme',
                  value: '${AppFormatters.dayMonth(statement.dueDate)} · $due',
                ),
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Limit kullanımı',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    StatusChip(label: statusLabel, color: statusColor),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: statement.usage,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                    color: statement.usage > 0.8 ? finance.expense : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${AppFormatters.money(statement.periodDebt)} / ${AppFormatters.money(statement.limit)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _days(String due) {
    final match = RegExp(r'(\d+)').firstMatch(due);
    return int.tryParse(match?.group(1) ?? '') ?? 99;
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _Fact({required this.label, required this.value, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: emphasize ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
