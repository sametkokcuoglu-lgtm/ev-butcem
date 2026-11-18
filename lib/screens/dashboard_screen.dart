import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'transactions_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(currentMonthSummaryProvider);
    final difference = summary.difference;
    return Scaffold(
      appBar: AppBar(title: const Text('Ev Bütçem')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppFormatters.monthYear(DateTime.now()), style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _SummaryCard(title: 'Gelir', amount: AppFormatters.money(summary.income), color: AppTheme.incomeColor, icon: Iconsax.arrow_down_1)),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(title: 'Gider', amount: AppFormatters.money(summary.expense), color: AppTheme.expenseColor, icon: Iconsax.arrow_up_1)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: difference >= 0
                      ? const [Color(0xFF16A34A), Color(0xFF15803D)]
                      : const [Color(0xFFDC2626), Color(0xFFB91C1C)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bu Ay Kalan', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.money(difference),
                    key: const Key('differenceText'),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Yaklaşan Ödemeler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _PaymentTile(title: 'Elektrik Faturası', amount: '875 ₺', days: '3 gün sonra'),
            _PaymentTile(title: 'Kredi Kartı', amount: '4.250 ₺', days: '5 gün sonra'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _QuickButton(label: 'Gelir Ekle', color: AppTheme.incomeColor, onTap: () => openTransactionForm(context, isIncome: true))),
                const SizedBox(width: 12),
                Expanded(child: _QuickButton(label: 'Gider Ekle', color: AppTheme.expenseColor, onTap: () => openTransactionForm(context))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, amount;
  final Color color;
  final IconData icon;
  const _SummaryCard({required this.title, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 8), Text(title, style: const TextStyle(color: Colors.grey))]),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String title, amount, days;
  const _PaymentTile({required this.title, required this.amount, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), Text(days, style: const TextStyle(fontSize: 12, color: Colors.grey))])),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        ),
      ),
    );
  }
}