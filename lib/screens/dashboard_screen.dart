import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../models/credit_card.dart';
import '../providers/wallet_providers.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(creditCardsProvider);
    final openStatements = ref
        .watch(statementsProvider)
        .where((statement) => !statement.isSettled)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return Scaffold(
      appBar: AppBar(title: const Text('Ev Bütçem')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kasım 2026',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                    child: _SummaryCard(
                        title: 'Gelir',
                        amount: '42.500 ₺',
                        color: AppTheme.incomeColor,
                        icon: Iconsax.arrow_down_1)),
                SizedBox(width: 12),
                Expanded(
                    child: _SummaryCard(
                        title: 'Gider',
                        amount: '28.750 ₺',
                        color: AppTheme.expenseColor,
                        icon: Iconsax.arrow_up_1)),
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
                  Text('13.750 ₺',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Yaklaşan Ödemeler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const _PaymentTile(
                title: 'Elektrik Faturası',
                amount: '875 ₺',
                days: '3 gün sonra'),
            const _PaymentTile(
                title: 'Kredi Kartı', amount: '4.250 ₺', days: '5 gün sonra'),
            for (final statement in openStatements.take(5))
              _PaymentTile(
                title: '${_cardName(cards, statement.creditCardId)} ekstresi',
                amount: formatMoney(statement.remainingAmount),
                days: statement.dueLabel(),
              ),
            const SizedBox(height: 24),
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
    );
  }
}

String _cardName(List<CreditCard> cards, String id) {
  for (final card in cards) {
    if (card.id == id) return card.name;
  }
  return 'Kart';
}

class _SummaryCard extends StatelessWidget {
  final String title, amount;
  final Color color;
  final IconData icon;
  const _SummaryCard(
      {required this.title,
      required this.amount,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.grey))
          ]),
          const SizedBox(height: 8),
          Text(amount,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String title, amount, days;
  const _PaymentTile(
      {required this.title, required this.amount, required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(days,
                    style: const TextStyle(fontSize: 12, color: Colors.grey))
              ])),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final Color color;
  const _QuickButton({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14)),
      child: Center(
          child: Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600))),
    );
  }
}
