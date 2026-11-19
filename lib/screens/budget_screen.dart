import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/transaction_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/budget_view.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/category_avatar.dart';
import '../widgets/content_frame.dart';
import '../widgets/empty_state.dart';
import '../widgets/info_banner.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final lines = BudgetView.lines(ref.watch(categoriesProvider), ref.watch(transactionsProvider), now);
    final theme = Theme.of(context);
    final limit = BudgetView.totalLimit(lines);
    final spent = BudgetView.totalSpent(lines);
    final remaining = limit - spent;
    final ratio = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    final over = limit > 0 && spent > limit;

    return Scaffold(
      appBar: AppBar(title: const Text('Bütçe')),
      body: ContentFrame(
        child: lines.isEmpty
            ? const EmptyState(
                icon: Icons.savings_rounded,
                title: 'Gider kategorisi yok',
                message: 'Bütçe kartları gider kategorilerinden oluşur.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xl),
                children: [
                  Text(
                    AppFormatters.monthYear(now),
                    style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                  _TotalCard(
                    limit: limit,
                    spent: spent,
                    remaining: remaining,
                    ratio: ratio,
                    over: over,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const InfoBanner(
                    text: 'Kategori limitleri örnek veridir. Harcamalar bu aya ait kayıtlı işlemlerden hesaplanır.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final line in lines) ...[
                    _BudgetCard(line: line),
                    const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                  ],
                ],
              ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double limit;
  final double spent;
  final double remaining;
  final double ratio;
  final bool over;

  const _TotalCard({
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.ratio,
    required this.over,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [finance.heroStart, finance.heroMid],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aylık limit', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppFormatters.money(limit),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: over ? const Color(0xFFFDA4AF) : const Color(0xFF6EE7B7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          Row(
            children: [
              Expanded(child: _WhiteStat(label: 'Harcanan', value: AppFormatters.money(spent))),
              Expanded(
                child: _WhiteStat(
                  label: over ? 'Aşan' : 'Kalan',
                  value: AppFormatters.money(remaining.abs()),
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            over ? 'Toplam limit aşıldı' : 'Limit içinde',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _WhiteStat extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _WhiteStat({required this.label, required this.value, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 12)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetLine line;

  const _BudgetCard({required this.line});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final category = line.category;
    final color = !line.hasLimit
        ? theme.colorScheme.onSurfaceVariant
        : line.over
            ? finance.expense
            : line.ratio >= 0.85
                ? finance.warning
                : finance.income;
    final progress = line.ratio.clamp(0.0, 1.0);
    final status = !line.hasLimit
        ? 'Örnek limit yok'
        : line.over
            ? '${AppFormatters.money(line.remaining.abs())} aşıldı'
            : '${AppFormatters.money(line.remaining)} kaldı';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryAvatar(icon: category.icon, colorValue: category.colorValue, size: 42),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      line.hasLimit
                          ? '${AppFormatters.money(line.spent)} / ${AppFormatters.money(line.limit!)}'
                          : AppFormatters.money(line.spent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  status,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(color: color, fontSize: 13),
                ),
              ),
            ],
          ),
          if (line.hasLimit) ...[
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.12),
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
