import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/transaction_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/spending_report.dart';
import '../widgets/app_card.dart';
import '../widgets/category_avatar.dart';
import '../widgets/content_frame.dart';
import '../widgets/empty_state.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shift(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoryMapProvider);
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final slices = SpendingReport.expensesByCategory(transactions, categories, _month);
    final series = SpendingReport.months(transactions, DateTime.now());
    final income = SpendingReport.months(transactions, _month, count: 1).single.income;
    final expense = slices.fold(0.0, (s, slice) => s + slice.amount);
    final totalExpense = expense;

    return Scaffold(
      appBar: AppBar(title: const Text('Raporlar')),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xl),
          children: [
            AppCard(
              radius: AppSpacing.radiusMd,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Önceki ay',
                    onPressed: () => _shift(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      AppFormatters.monthYear(_month),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sonraki ay',
                    onPressed: () => _shift(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _MiniStat(label: 'Gelir', value: income, color: finance.income)),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(child: _MiniStat(label: 'Gider', value: expense, color: finance.expense)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Kategori dağılımı', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: slices.isEmpty
                  ? const EmptyState(
                      icon: Icons.pie_chart_outline_rounded,
                      title: 'Bu ay gider yok',
                      message: 'Gider eklediğinde kategori dağılımı burada görünecek.',
                    )
                  : _DonutBlock(slices: slices, total: totalExpense),
            ),
            const SizedBox(height: AppSpacing.section),
            Text('Son 6 ay', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            AppCard(child: _MonthlyBars(series: series)),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      radius: AppSpacing.radiusMd,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(AppFormatters.money(value), style: theme.textTheme.titleMedium?.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

class _DonutBlock extends StatelessWidget {
  final List<CategorySpend> slices;
  final double total;

  const _DonutBlock({required this.slices, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chart = SizedBox(
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 62,
              startDegreeOffset: -90,
              sections: [
                for (final slice in slices)
                  PieChartSectionData(
                    value: slice.amount,
                    color: Color(slice.colorValue),
                    radius: 22,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 108,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Gider', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(AppFormatters.money(total), style: theme.textTheme.titleMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final legend = Column(
      children: [
        for (final slice in slices) ...[
          Row(
            children: [
              CategoryAvatar(icon: slice.icon, colorValue: slice.colorValue, size: 36),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slice.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                    Text(
                      '%${total <= 0 ? 0 : (slice.amount / total * 100).round()}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    AppFormatters.money(slice.amount),
                    style: theme.textTheme.titleSmall?.copyWith(color: Color(slice.colorValue)),
                  ),
                ),
              ),
            ],
          ),
          if (slice != slices.last) const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 520) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: chart),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: legend),
            ],
          );
        }
        return Column(
          children: [
            chart,
            const SizedBox(height: AppSpacing.md),
            legend,
          ],
        );
      },
    );
  }
}

class _MonthlyBars extends StatelessWidget {
  final List<MonthPoint> series;

  const _MonthlyBars({required this.series});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final peak = series.fold<double>(0, (max, m) => [max, m.income, m.expense].reduce((a, b) => a > b ? a : b));
    final maxY = peak <= 0 ? 100.0 : peak * 1.2;
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Dot(color: finance.income, label: 'Gelir'),
            const SizedBox(width: AppSpacing.md),
            _Dot(color: finance.expense, label: 'Gider'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final point = series[group.x.toInt()];
                    final value = rodIndex == 0 ? point.income : point.expense;
                    final name = rodIndex == 0 ? 'Gelir' : 'Gider';
                    return BarTooltipItem(
                      '$name\n${AppFormatters.money(value)}',
                      TextStyle(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.w700, fontSize: 12),
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(color: finance.line, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        AppFormatters.compact(value),
                        style: theme.textTheme.labelSmall?.copyWith(color: muted),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= series.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          AppFormatters.shortMonth(series[index].month),
                          style: theme.textTheme.labelSmall?.copyWith(color: muted),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < series.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: series[i].income,
                        color: finance.income,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                      BarChartRodData(
                        toY: series[i].expense,
                        color: finance.expense,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;

  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
