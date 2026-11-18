import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../models/scheduled_item.dart';
import '../providers/finance_providers.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../utils/format.dart';
import '../widgets/finance_month_calendar.dart';
import '../widgets/upcoming_payment_tile.dart';
import 'payment_form_screen.dart';

class FinanceCalendarScreen extends ConsumerWidget {
  const FinanceCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(visibleMonthProvider);
    final selected = ref.watch(selectedDayProvider);
    final today = dateOnly(ref.watch(clockProvider)());
    final finance = ref.watch(monthFinanceProvider);
    final dayItems =
        finance.byDay[dateOnly(selected)] ?? const <ScheduledItem>[];
    final marks = <DateTime, DayMarks>{};
    for (final entry in finance.byDay.entries) {
      marks[entry.key] = DayMarks(
        hasPayment: entry.value.any((item) => !item.isIncome),
        hasIncome: entry.value.any((item) => item.isIncome),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Finans Takvimi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaymentFormScreen()),
          );
        },
        icon: const Icon(Iconsax.add),
        label: const Text('Ödeme Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _MonthSummary(summary: finance.summary),
          const SizedBox(height: 12),
          FinanceMonthCalendar(
            month: month,
            selectedDay: selected,
            today: today,
            marks: marks,
            onSelect: (day) =>
                ref.read(selectedDayProvider.notifier).state = dateOnly(day),
            onPreviousMonth: () => _shiftMonth(ref, -1),
            onNextMonth: () => _shiftMonth(ref, 1),
            onJumpToToday: () {
              ref.read(visibleMonthProvider.notifier).state =
                  DateTime(today.year, today.month);
              ref.read(selectedDayProvider.notifier).state = today;
            },
          ),
          const SizedBox(height: 20),
          Text(
            formatTrDate(selected),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (dayItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
              ),
              child: Text(
                'Bu günde kayıt yok',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            for (final item in dayItems)
              UpcomingPaymentTile(
                item: item,
                now: today,
                onToggle: item.canTogglePaid ? () => _toggle(ref, item) : null,
              ),
        ],
      ),
    );
  }

  void _shiftMonth(WidgetRef ref, int delta) {
    final current = ref.read(visibleMonthProvider);
    final next = DateTime(current.year, current.month + delta, 1);
    ref.read(visibleMonthProvider.notifier).state = next;
    final selected = ref.read(selectedDayProvider);
    if (selected.year == next.year && selected.month == next.month) return;
    final today = dateOnly(ref.read(clockProvider)());
    if (today.year == next.year && today.month == next.month) {
      ref.read(selectedDayProvider.notifier).state = today;
    } else {
      ref.read(selectedDayProvider.notifier).state = next;
    }
  }

  Future<void> _toggle(WidgetRef ref, ScheduledItem item) async {
    if (item.kind == FinanceKind.installment && item.installmentIndex != null) {
      final nextCount =
          item.isPaid ? item.installmentIndex! : item.installmentIndex! + 1;
      await ref
          .read(installmentsProvider.notifier)
          .setPaidCount(item.sourceId, nextCount);
      return;
    }
    if (item.kind == FinanceKind.planned) {
      await ref
          .read(plannedPaymentsProvider.notifier)
          .togglePaid(item.sourceId);
    }
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                title: 'Toplam',
                amount: formatTry(summary.totalDue),
                color: AppTheme.primaryColor,
                icon: Iconsax.wallet_2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                title: 'Ödenen',
                amount: formatTry(summary.paid),
                color: AppTheme.incomeColor,
                icon: Iconsax.tick_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kalan', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(
                formatTry(summary.remaining),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
