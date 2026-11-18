import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'add_transaction_screen.dart';

enum _TransactionAction { edit, delete }

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final categories = {for (final c in ref.watch(categoriesProvider)) c.id: c};

    return Scaffold(
      appBar: AppBar(title: const Text('İşlemler')),
      body: transactions.isEmpty
          ? const Center(child: Text('Henüz işlem yok'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _TransactionTile(
                transaction: transactions[i],
                category: categories[transactions[i].categoryId],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openTransactionForm(context),
        icon: const Icon(Iconsax.add),
        label: const Text('Yeni İşlem'),
      ),
    );
  }
}

/// Ekleme / düzenleme formunu açar.
Future<void> openTransactionForm(
  BuildContext context, {
  Transaction? transaction,
  bool isIncome = false,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AddTransactionScreen(
        transaction: transaction,
        initialIsIncome: isIncome,
      ),
    ),
  );
}

class _TransactionTile extends ConsumerWidget {
  final Transaction transaction;
  final Category? category;

  const _TransactionTile({required this.transaction, required this.category});

  Future<void> _handle(BuildContext context, WidgetRef ref, _TransactionAction? action) async {
    switch (action) {
      case _TransactionAction.edit:
        await openTransactionForm(context, transaction: transaction);
      case _TransactionAction.delete:
        await _confirmDelete(context, ref);
      case null:
        break;
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İşlem silinsin mi?'),
        content: Text(
          '${category?.name ?? 'Kategorisiz'} · ${AppFormatters.money(transaction.amount)} '
          'tutarındaki işlem kalıcı olarak silinecek.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.expenseColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(transactionsProvider.notifier).remove(transaction.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem silindi')));
    }
  }

  Future<void> _showContextMenu(BuildContext context, WidgetRef ref, Offset position) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final action = await showMenu<_TransactionAction>(
      context: context,
      position: RelativeRect.fromRect(position & const Size(1, 1), Offset.zero & overlay.size),
      items: const [
        PopupMenuItem(value: _TransactionAction.edit, child: ListTile(leading: Icon(Iconsax.edit), title: Text('Düzenle'))),
        PopupMenuItem(value: _TransactionAction.delete, child: ListTile(leading: Icon(Iconsax.trash), title: Text('Sil'))),
      ],
    );
    if (context.mounted) await _handle(context, ref, action);
  }

  Future<void> _showBottomSheet(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<_TransactionAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.edit),
              title: const Text('Düzenle'),
              onTap: () => Navigator.pop(ctx, _TransactionAction.edit),
            ),
            ListTile(
              leading: const Icon(Iconsax.trash, color: AppTheme.expenseColor),
              title: const Text('Sil', style: TextStyle(color: AppTheme.expenseColor)),
              onTap: () => Navigator.pop(ctx, _TransactionAction.delete),
            ),
          ],
        ),
      ),
    );
    if (context.mounted) await _handle(context, ref, action);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = transaction;
    final color = t.isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
    final subtitle = [
      AppFormatters.date(t.date),
      if (t.note != null && t.note!.isNotEmpty) t.note!,
    ].join(' · ');

    return GestureDetector(
      // Masaüstü / web: sağ tıkla Düzenle / Sil
      onSecondaryTapDown: (d) => _showContextMenu(context, ref, d.globalPosition),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: () => openTransactionForm(context, transaction: t),
          onLongPress: () => _showBottomSheet(context, ref),
          leading: CircleAvatar(
            backgroundColor: Color(category?.colorValue ?? Colors.grey.toARGB32()).withValues(alpha: 0.15),
            child: Text(category?.icon ?? '❔', style: const TextStyle(fontSize: 20)),
          ),
          title: Text(category?.name ?? 'Kategorisiz', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(
            '${t.isIncome ? '+' : '-'}${AppFormatters.money(t.amount)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
