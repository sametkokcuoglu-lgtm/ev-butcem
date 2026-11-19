import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/date_groups.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/category_avatar.dart';
import '../widgets/content_frame.dart';
import '../widgets/empty_state.dart';
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
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);

    var income = 0.0;
    var expense = 0.0;
    for (final t in transactions) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    final rows = <Object>[];
    String? lastLabel;
    for (final t in transactions) {
      final label = DateGroups.label(t.date);
      if (label != lastLabel) {
        rows.add(label);
        lastLabel = label;
      }
      rows.add(t);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('İşlemler')),
      body: ContentFrame(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, 0),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, 0),
              child: AppCard(
                radius: AppSpacing.radiusMd,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('prevMonthButton'),
                      tooltip: 'Önceki ay',
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => _shiftMonth(-1),
                    ),
                    Expanded(
                      child: TextButton(
                        key: const Key('monthFilterButton'),
                        onPressed: () => setState(() {
                          final now = DateTime.now();
                          _month = _month == null ? DateTime(now.year, now.month) : null;
                        }),
                        child: Text(
                          _month == null ? 'Tüm aylar' : AppFormatters.monthYear(_month!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('nextMonthButton'),
                      tooltip: 'Sonraki ay',
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () => _shiftMonth(1),
                    ),
                  ],
                ),
              ),
            ),
            if (transactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xs),
                child: Text(
                  '${transactions.length} işlem · Gelir ${AppFormatters.money(income)} · '
                  'Gider ${AppFormatters.money(expense)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            Expanded(
              child: all.isEmpty
                  ? const Center(
                      child: EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'Henüz işlem yok',
                        message: 'İlk gelir veya giderini eklediğinde liste burada oluşacak.',
                      ),
                    )
                  : transactions.isEmpty
                      ? const Center(
                          child: EmptyState(
                            icon: Icons.filter_alt_outlined,
                            title: 'Bu filtreye uygun işlem yok',
                            message: 'Tür veya ay filtresini değiştirip yeniden bakabilirsin.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, 96),
                          itemCount: rows.length,
                          itemBuilder: (context, i) {
                            final row = rows[i];
                            if (row is String) {
                              return Padding(
                                padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.sm, bottom: AppSpacing.sm),
                                child: Text(
                                  row,
                                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              );
                            }
                            final transaction = row as Transaction;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.item),
                              child: _TransactionTile(
                                key: ValueKey(transaction.id),
                                transaction: transaction,
                                category: categories[transaction.categoryId],
                                finance: finance,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openTransactionForm(
          context,
          isIncome: _type == TransactionTypeFilter.income,
        ),
        icon: const Icon(Icons.add_rounded),
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
  final FinanceColors finance;

  const _TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.finance,
  });

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
        PopupMenuItem(value: _TransactionAction.edit, child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Düzenle'))),
        PopupMenuItem(value: _TransactionAction.delete, child: ListTile(leading: Icon(Icons.delete_outline_rounded), title: Text('Sil'))),
      ],
    );
    if (context.mounted) await _handle(context, ref, action);
  }

  Future<void> _showBottomSheet(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<_TransactionAction>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Düzenle'),
              onTap: () => Navigator.pop(ctx, _TransactionAction.edit),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: finance.expense),
              title: Text('Sil', style: TextStyle(color: finance.expense)),
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
    final theme = Theme.of(context);
    final color = t.isIncome ? finance.income : finance.expense;
    final amount = '${t.isIncome ? '+' : '-'}${AppFormatters.money(t.amount)}';
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
          color: finance.expense,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white),
          ],
        ),
      ),
      child: GestureDetector(
        // Masaüstü / web: sağ tıkla Düzenle / Sil
        onSecondaryTapDown: (d) => _showContextMenu(context, ref, d.globalPosition),
        child: AppCard(
          radius: AppSpacing.radiusMd,
          padding: EdgeInsets.zero,
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            onTap: () => openTransactionForm(context, transaction: t),
            onLongPress: () => _showBottomSheet(context, ref),
            leading: CategoryAvatar(icon: category?.icon ?? '❔', colorValue: category?.colorValue, size: 42),
            title: Text(
              category?.name ?? 'Kategorisiz',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(amount, style: theme.textTheme.titleSmall?.copyWith(color: color)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
