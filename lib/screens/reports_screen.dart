import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../providers/budget_providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/report_aggregator.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _month = _currentMonth();
  bool _showIncome = false;

  static DateTime _currentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  bool get _canGoNext {
    final current = _currentMonth();
    return _month.isBefore(current);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoriesProvider);
    final totals = monthlyTotals(transactions, _month);
    final history = recentMonths(transactions, _month);
    final shares = categoryShares(
      transactions: transactions,
      categories: categories,
      month: _month,
      isIncome: _showIncome,
    );
    final historyMax = history.fold<double>(0, (max, month) {
      final candidate =
          month.income > month.expense ? month.income : month.expense;
      return candidate > max ? candidate : max;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Raporlar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _Surface(child: _monthSelector()),
          const SizedBox(height: 16),
          _NetCard(amount: totals.net),
          const SizedBox(height: 16),
          const _SectionTitle('Aylık gelir-gider özeti'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TotalCard(
                  title: 'Toplam gelir',
                  amount: totals.income,
                  color: AppTheme.incomeColor,
                  icon: Iconsax.arrow_down_1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TotalCard(
                  title: 'Toplam gider',
                  amount: totals.expense,
                  color: AppTheme.expenseColor,
                  icon: Iconsax.arrow_up_1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Kategori dağılımı'),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<bool>(value: false, label: Text('Giderler')),
              ButtonSegment<bool>(value: true, label: Text('Gelirler')),
            ],
            selected: {_showIncome},
            onSelectionChanged: (selection) {
              setState(() => _showIncome = selection.first);
            },
          ),
          const SizedBox(height: 12),
          _Surface(
            child: shares.isEmpty
                ? _EmptyDistribution(isIncome: _showIncome)
                : _DistributionChart(shares: shares, isIncome: _showIncome),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Son 6 ay'),
          const SizedBox(height: 8),
          _Surface(
            child: Column(
              children: [
                const _HistoryLegend(),
                const SizedBox(height: 8),
                for (final month in history) ...[
                  _HistoryRow(
                    snapshot: month,
                    maxAmount: historyMax,
                    selected: month.month.year == _month.year &&
                        month.month.month == _month.month,
                  ),
                  if (month != history.last) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthSelector() {
    return Row(
      children: [
        IconButton(
          key: const Key('previous-month'),
          tooltip: 'Önceki ay',
          onPressed: () => _shiftMonth(-1),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        Expanded(
          child: Text(
            formatMonthYear(_month),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          key: const Key('next-month'),
          tooltip: 'Sonraki ay',
          onPressed: _canGoNext ? () => _shiftMonth(1) : null,
          icon: const Icon(Iconsax.arrow_right_3),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatTry(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetCard extends StatelessWidget {
  const _NetCard({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    final positive = amount >= 0;
    final colors = positive
        ? const [Color(0xFF16A34A), Color(0xFF15803D)]
        : const [Color(0xFFDC2626), Color(0xFFB91C1C)];
    return Container(
      key: const Key('net-durum'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Iconsax.wallet_3, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Net durum',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatTry(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gelir − gider',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _HistoryLegend extends StatelessWidget {
  const _HistoryLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Spacer(),
        _DotLabel(color: AppTheme.incomeColor, label: 'Gelir'),
        SizedBox(width: 12),
        _DotLabel(color: AppTheme.expenseColor, label: 'Gider'),
      ],
    );
  }
}

class _DotLabel extends StatelessWidget {
  const _DotLabel({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.snapshot,
    required this.maxAmount,
    required this.selected,
  });

  final MonthSnapshot snapshot;
  final double maxAmount;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
        : Colors.transparent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatMonthShort(snapshot.month),
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                formatTry(snapshot.income),
                style: const TextStyle(
                  color: AppTheme.incomeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatTry(snapshot.expense),
                style: const TextStyle(
                  color: AppTheme.expenseColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Meter(
              value: snapshot.income,
              max: maxAmount,
              color: AppTheme.incomeColor),
          const SizedBox(height: 3),
          _Meter(
              value: snapshot.expense,
              max: maxAmount,
              color: AppTheme.expenseColor),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.value, required this.max, required this.color});

  final double value;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction =
        max <= 0 || value <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: color.withValues(alpha: 0.12)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDistribution extends StatelessWidget {
  const _EmptyDistribution({required this.isIncome});

  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Iconsax.chart_2, size: 42, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            isIncome
                ? 'Bu ay için gelir kaydı yok'
                : 'Bu ay için gider kaydı yok',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _DistributionChart extends StatelessWidget {
  const _DistributionChart({required this.shares, required this.isIncome});

  final List<CategoryShare> shares;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final total = shares.fold<double>(0, (sum, share) => sum + share.amount);
    final cardColor = Theme.of(context).cardColor;

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: shares.length <= 1 ? 0 : 2,
                  centerSpaceRadius: 62,
                  centerSpaceColor: cardColor,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(enabled: false),
                  sections: [
                    for (final share in shares)
                      PieChartSectionData(
                        value: share.amount,
                        color: Color(share.colorValue),
                        radius: 48,
                        showTitle: false,
                        title: '',
                      ),
                  ],
                ),
                swapAnimationDuration: const Duration(milliseconds: 250),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isIncome ? 'Gelir' : 'Gider',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 96,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatTry(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final share in shares) _LegendRow(share: share),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.share});

  final CategoryShare share;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Color(share.colorValue),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(share.icon),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              share.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatTry(share.amount),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                formatPercent(share.percentage),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
