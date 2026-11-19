import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../providers/finance_providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/payment_schedule.dart';
import '../widgets/upcoming_payment_tile.dart';
import 'bill_form_screen.dart';
import 'finance_calendar_screen.dart';
import 'upcoming_payments_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final preview = previewUpcoming(ref.watch(upcomingSectionsProvider));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ev Bütçem'),
        actions: [
          IconButton(
            tooltip: 'Finans Takvimi',
            onPressed: () => _open(context, const FinanceCalendarScreen()),
            icon: const Icon(Iconsax.calendar_1),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatTrMonth(now),
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Gelir',
                    amount: '42.500 ₺',
                    color: AppTheme.incomeColor,
                    icon: Iconsax.arrow_down_1,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Gider',
                    amount: '28.750 ₺',
                    color: AppTheme.expenseColor,
                    icon: Iconsax.arrow_up_1,
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
                    colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bu Ay Kalan', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 4),
                  Text(
                    '13.750 ₺',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text('Yaklaşan Ödemeler',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () =>
                      _open(context, const UpcomingPaymentsScreen()),
                  child: const Text('Tümünü gör'),
                ),
              ],
            ),
            if (preview.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Yaklaşan ödeme yok. Kart borcu veya fatura eklediğinde burada görünür.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              for (final item in preview)
                UpcomingPaymentTile(
                  item: item,
                  now: now,
                  onTap: () => _open(context, const UpcomingPaymentsScreen()),
                ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                    child: _QuickButton(
                        label: 'Gelir Ekle', color: AppTheme.incomeColor)),
                SizedBox(width: 12),
                Expanded(
                    child: _QuickButton(
                        label: 'Gider Ekle', color: AppTheme.expenseColor)),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, const BillFormScreen()),
        icon: const Icon(Iconsax.add),
        label: const Text('Fatura Ekle'),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
