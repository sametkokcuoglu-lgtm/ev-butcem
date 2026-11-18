import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_delete.dart';
import 'add_transaction_screen.dart';

enum _TransactionAction { edit, delete }

/// İşlemler listesindeki tür filtresi.
enum TransactionTypeFilter { all, income, expense }

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionTypeFilter _type = TransactionTypeFilter.all;

  /// Seçili ay (ayın 1'i); `null` ise tüm aylar.
  DateTime? _month;

  bool _matches(Transaction t) {
    switch (_type) {
      case TransactionTypeFilter.income:
        if (!t.isIncome) return false;
      case TransactionTypeFilter.expense:
        if (t.isIncome) return false;
      case TransactionTypeFilter.all:
        break;
    }
    final m = _month;
    return m == null || (t.date.year == m.year && t.date.month == m.month);
  }

  void _shiftMonth(int delta) {
    final now = DateTime.now();
    final base = _month ?? DateTime(now.year, now.month);
    setState(() => _month = DateTime(base.year, base.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(transactionsProvider);
    final categories = ref.watch(categoryMapProvider);
    final transactions = all.where(_matches).toList();

    var income = 0.0;
    var expense = 0.0;
    for (final t in transactions) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('İşlemler')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<TransactionTypeFilter>(
              key: const Key('typeFilter'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: TransactionTypeFilter.all, label: Text('Tümü')),
                ButtonSegment(value: TransactionTypeFilter.income, label: Text('Gelir')),
                ButtonSegment(value: TransactionTypeFilter.expense, label: Text('Gider')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('prevMonthButton'),
                tooltip: 'Önceki ay',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shiftMonth(-1),
              ),
              TextButton(
                key: const Key('monthFilterButton'),
                onPressed: () => setState(() {
                  final now = DateTime.now();
                  _month = _month == null ? DateTime(now.year, now.month) : null;
                }),
                child: Text(_month == null ? 'Tüm aylar' : AppFormatters.monthYear(_month!)),
              ),
              IconButton(
                key: const Key('nextMonthButton'),
                tooltip: 'Sonraki ay',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shiftMonth(1),
              ),
            ],
          ),
          if (transactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                '${transactions.length} işlem · Gelir ${AppFormatters.money(income)} · '
                'Gider ${AppFormatters.money(expense)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          Expanded(
            child: all.isEmpty
                ? const Center(child: Text('Henüz işlem yok'))
                : transactions.isEmpty
                    ? const Center(child: Text('Bu filtreye uygun işlem yok'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _TransactionTile(
                          key: ValueKey(transactions[i].id),
                          transaction: transactions[i],
                          category: categories[transactions[i].categoryId],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openTransactionForm(
          context,
          isIncome: _type == TransactionTypeFilter.income,
        ),
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

  const _TransactionTile({super.key, required this.transaction, required this.category});

  Future<void> _handle(BuildContext context, WidgetRef ref, _TransactionAction? action) async {
    switch (action) {
      case _TransactionAction.edit:
        await openTransactionForm(context, transaction: transaction);
      case _TransactionAction.delete:
        if (await confirmTransactionDelete(context, transaction, category) && context.mounted) {
          await deleteTransactionWithUndo(context, ref, transaction);
        }
      case null:
        break;
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

    return Dismissible(
      key: ValueKey('dismiss-${t.id}'),
      direction: DismissDirection.endToStart,
      // Kaydırınca önce onay istenir; Vazgeç'te satır yerine döner.
      confirmDismiss: (_) => confirmTransactionDelete(context, t, category),
      onDismissed: (_) => deleteTransactionWithUndo(context, ref, t),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.expenseColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            SizedBox(width: 8),
            Icon(Iconsax.trash, color: Colors.white),
          ],
        ),
      ),
      child: GestureDetector(
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
      ),
    );
  }
}
