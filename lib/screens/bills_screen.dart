import 'package:flutter/material.dart';

import '../demo/demo_finance.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/date_groups.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/category_avatar.dart';
import '../widgets/content_frame.dart';
import '../widgets/info_banner.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

enum _BillFilter { upcoming, paid }

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  _BillFilter _filter = _BillFilter.upcoming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bills = DemoFinance.bills();
    final visible = bills.where((b) => _filter == _BillFilter.paid ? b.paid : !b.paid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final openAmount = bills.where((b) => !b.paid).fold(0.0, (sum, b) => sum + b.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Faturalar')),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xl),
          children: [
            _OpenTotal(amount: openAmount),
            const SizedBox(height: AppSpacing.md),
            const InfoBanner(text: 'Faturalar örnek listedir. Gerçek fatura kaydı bağlanınca bu liste değişir.'),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<_BillFilter>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _BillFilter.upcoming, label: Text('Yaklaşan'), icon: Icon(Icons.schedule_rounded, size: 16)),
                ButtonSegment(value: _BillFilter.paid, label: Text('Ödenen'), icon: Icon(Icons.check_circle_outline, size: 16)),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionHeader(
              title: _filter == _BillFilter.paid ? 'Ödenen faturalar' : 'Yaklaşan faturalar',
              onAction: null,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (visible.isEmpty)
              Text(
                'Bu grupta fatura yok',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else
              for (final bill in visible) ...[
                _BillCard(bill: bill),
                const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              ],
          ],
        ),
      ),
    );
  }
}

class _OpenTotal extends StatelessWidget {
  final double amount;

  const _OpenTotal({required this.amount});

  @override
  Widget build(BuildContext context) {
    final finance = FinanceColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [finance.heroStart, finance.heroMid]),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ödenmemiş toplam', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppFormatters.money(amount),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final DemoBill bill;

  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final status = _status(bill, finance);

    return AppCard(
      child: Row(
        children: [
          CategoryAvatar(icon: bill.icon, colorValue: status.color.toARGB32(), size: 46),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${bill.provider} · ${AppFormatters.dayMonth(bill.dueDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.sm),
                StatusChip(label: status.label, color: status.color),
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
                AppFormatters.money(bill.amount),
                style: theme.textTheme.titleSmall?.copyWith(color: status.color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _BillStatus _status(DemoBill bill, FinanceColors finance) {
    if (bill.paid) return _BillStatus('Ödendi', finance.income);
    if (bill.overdue) return _BillStatus('Gecikti', finance.expense);
    final due = DateGroups.due(bill.dueDate);
    if (due == 'Bugün' || due == 'Yarın') return _BillStatus(due, finance.warning);
    return _BillStatus(due, finance.warning);
  }
}

class _BillStatus {
  final String label;
  final Color color;
  const _BillStatus(this.label, this.color);
}
