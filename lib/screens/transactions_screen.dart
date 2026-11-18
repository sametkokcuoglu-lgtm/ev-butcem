import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../providers/budget_providers.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'add_transaction_sheet.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final categories = {
      for (final category in ref.watch(categoriesProvider))
        category.id: category,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('İşlemler')),
      body: transactions.isEmpty
          ? const Center(child: Text('Henüz işlem yok'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final category = categories[transaction.categoryId];
                final color = transaction.isIncome
                    ? AppTheme.incomeColor
                    : AppTheme.expenseColor;
                final signed = transaction.isIncome
                    ? '+${formatTry(transaction.amount)}'
                    : '-${formatTry(transaction.amount)}';
                final note = transaction.note;
                final subtitle = note == null || note.isEmpty
                    ? formatFullDate(transaction.date)
                    : '${formatFullDate(transaction.date)} · $note';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        category?.icon ?? '📁',
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category?.name ?? 'Bilinmeyen kategori',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        signed,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: color),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddTransactionSheet(context),
        icon: const Icon(Iconsax.add),
        label: const Text('Yeni İşlem'),
      ),
    );
  }
}
