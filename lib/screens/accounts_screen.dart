import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../providers/finance_providers.dart';
import '../utils/format.dart';
import 'card_form_screen.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(creditCardsProvider);
    final accounts =
        ref.watch(accountsProvider).where((account) => account.isActive);

    return Scaffold(
      appBar: AppBar(title: const Text('Hesaplar & Kartlar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CardFormScreen()),
          );
        },
        icon: const Icon(Iconsax.add),
        label: const Text('Kart Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const Text('Kredi Kartları',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (cards.isEmpty)
            const _EmptyLine(
              message:
                  'Henüz kart eklenmedi. Borcu olan kartların son ödeme günü yaklaşan ödemelerde görünür.',
            )
          else
            for (final card in cards)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Iconsax.card),
                title: Text(card.name),
                subtitle: Text(
                  '${card.bankName} · Son ödeme: her ayın ${card.dueDay}. günü',
                ),
                trailing: Text(
                  formatTry(card.currentDebt),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CardFormScreen(existing: card),
                    ),
                  );
                },
              ),
          const SizedBox(height: 24),
          const Text('Hesaplar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (accounts.isEmpty)
            const _EmptyLine(message: 'Henüz hesap eklenmedi')
          else
            for (final account in accounts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Iconsax.wallet_2),
                title: Text(account.name),
                subtitle: Text(account.bankName),
                trailing: Text(formatTry(account.balance)),
              ),
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
    );
  }
}
