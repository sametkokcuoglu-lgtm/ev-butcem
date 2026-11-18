import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../models/planned_payment.dart';
import '../models/scheduled_item.dart';
import '../providers/finance_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/upcoming_payment_tile.dart';
import 'payment_form_screen.dart';

class UpcomingPaymentsScreen extends ConsumerWidget {
  const UpcomingPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(upcomingSectionsProvider);
    final now = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(title: const Text('Yaklaşan Ödemeler')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Iconsax.add),
        label: const Text('Ödeme Ekle'),
      ),
      body: sections.isEmpty
          ? const _EmptyPayments()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                for (final section in sections) ...[
                  _SectionHeader(group: section.group),
                  for (final item in section.items)
                    UpcomingPaymentTile(
                      item: item,
                      now: now,
                      onToggle: item.canTogglePaid
                          ? () => _toggle(context, ref, item)
                          : null,
                      onTap: item.kind == FinanceKind.planned
                          ? () => _editPlanned(context, ref, item)
                          : null,
                    ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }

  Future<void> _toggle(
      BuildContext context, WidgetRef ref, ScheduledItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    if (item.kind == FinanceKind.installment && item.installmentIndex != null) {
      final nextCount =
          item.isPaid ? item.installmentIndex! : item.installmentIndex! + 1;
      await ref
          .read(installmentsProvider.notifier)
          .setPaidCount(item.sourceId, nextCount);
      return;
    }
    if (item.kind != FinanceKind.planned) return;

    final turningOn = !item.isPaid;
    await ref.read(plannedPaymentsProvider.notifier).togglePaid(item.sourceId);
    if (!turningOn ||
        item.recurrence == null ||
        item.recurrence == PaymentRecurrence.none) {
      return;
    }
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Ödendi olarak işaretlendi'),
        action: SnackBarAction(
          label: 'Sonraki dönem',
          onPressed: () {
            ref
                .read(plannedPaymentsProvider.notifier)
                .advanceToNextPeriod(item.sourceId);
          },
        ),
      ),
    );
  }

  void _editPlanned(BuildContext context, WidgetRef ref, ScheduledItem item) {
    PlannedPayment? payment;
    for (final candidate in ref.read(plannedPaymentsProvider)) {
      if (candidate.id == item.sourceId) {
        payment = candidate;
        break;
      }
    }
    if (payment == null) return;
    _openForm(context, existing: payment);
  }

  void _openForm(BuildContext context, {PlannedPayment? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaymentFormScreen(existing: existing)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.group});

  final PaymentGroup group;

  @override
  Widget build(BuildContext context) {
    final color = switch (group) {
      PaymentGroup.overdue => AppTheme.expenseColor,
      PaymentGroup.today => AppTheme.warningColor,
      PaymentGroup.thisWeek => AppTheme.primaryColor,
      PaymentGroup.later => Colors.grey.shade700,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        group.title,
        style:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _EmptyPayments extends StatelessWidget {
  const _EmptyPayments();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.calendar_tick, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Yaklaşan ödeme yok',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Kira, fatura veya diğer planlı ödemeleri ekleyerek burada takip edebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
