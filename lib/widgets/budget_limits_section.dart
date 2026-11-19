import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../models/category.dart';
import '../providers/budget_providers.dart';
import '../theme/app_theme.dart';
import '../utils/budget_progress.dart';
import '../utils/format.dart';

class BudgetLimitsSection extends ConsumerWidget {
  const BudgetLimitsSection({super.key, required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final transactions = ref.watch(transactionsProvider);
    final limits = ref.watch(budgetLimitsProvider);
    final expenseCategories = [
      for (final category in categories)
        if (!category.isIncome) category,
    ];
    final progress = budgetProgress(
      limits: limits,
      transactions: transactions,
      categories: categories,
      month: month,
    );
    final progressById = {
      for (final row in progress) row.categoryId: row,
    };
    final knownIds = expenseCategories.map((category) => category.id).toSet();
    final orphanIds = [
      for (final row in progress)
        if (!knownIds.contains(row.categoryId)) row.categoryId,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bütçe limitleri',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(
          'Seçili aydaki harcama, aylık limite göre',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (expenseCategories.isEmpty && orphanIds.isEmpty)
          const _LimitSurface(
            child: Text('Gider kategorisi yok'),
          )
        else
          _LimitSurface(
            child: Column(
              children: [
                for (var index = 0;
                    index < expenseCategories.length;
                    index++) ...[
                  if (index > 0) const Divider(height: 20),
                  _LimitRow(
                    category: expenseCategories[index],
                    progress: progressById[expenseCategories[index].id],
                  ),
                ],
                for (final categoryId in orphanIds) ...[
                  const Divider(height: 20),
                  _LimitRow(
                    category: Category(
                      id: categoryId,
                      name: progressById[categoryId]!.name,
                      icon: progressById[categoryId]!.icon,
                      colorValue: progressById[categoryId]!.colorValue,
                      isIncome: false,
                    ),
                    progress: progressById[categoryId],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _LimitSurface extends StatelessWidget {
  const _LimitSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }
}

class _LimitRow extends ConsumerWidget {
  const _LimitRow({required this.category, required this.progress});

  final Category category;
  final CategoryBudgetProgress? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelColor = switch (progress?.level) {
      BudgetLevel.exceeded => AppTheme.expenseColor,
      BudgetLevel.near => AppTheme.warningColor,
      BudgetLevel.ok || null => AppTheme.incomeColor,
    };
    final ratio = progress == null
        ? 0.0
        : (progress!.ratio.isFinite ? progress!.ratio.clamp(0.0, 1.0) : 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (progress == null)
              TextButton(
                onPressed: () => _editLimit(context, ref),
                child: const Text('Belirle'),
              )
            else ...[
              IconButton(
                tooltip: 'Düzenle',
                onPressed: () => _editLimit(context, ref),
                icon: const Icon(Iconsax.edit_2, size: 18),
              ),
              IconButton(
                tooltip: 'Kaldır',
                onPressed: () => _removeLimit(context, ref),
                icon: const Icon(
                  Iconsax.trash,
                  size: 18,
                  color: AppTheme.expenseColor,
                ),
              ),
            ],
          ],
        ),
        if (progress == null)
          const Text(
            'Aylık limit yok',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          )
        else ...[
          Text(
            '${formatTry(progress!.spent)} / ${formatTry(progress!.limit)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                color: levelColor,
                backgroundColor: levelColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _statusLabel(progress!),
            style: TextStyle(
              color: progress!.isExceeded
                  ? AppTheme.expenseColor
                  : progress!.isNearLimit
                      ? AppTheme.warningColor
                      : Colors.grey.shade700,
              fontWeight:
                  progress!.isExceeded ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  String _statusLabel(CategoryBudgetProgress progress) {
    if (progress.isExceeded) return 'Limit aşıldı';
    if (progress.isNearLimit) {
      return 'Limite yaklaşıldı · Kalan ${formatTry(progress.remaining)}';
    }
    return 'Kalan ${formatTry(progress.remaining)}';
  }

  Future<void> _editLimit(BuildContext context, WidgetRef ref) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => _LimitDialog(
        categoryName: category.name,
        initialAmount: progress?.limit,
      ),
    );
    if (amount == null) return;
    await ref.read(budgetLimitsProvider.notifier).save(
          categoryId: category.id,
          amount: amount,
        );
  }

  Future<void> _removeLimit(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limiti kaldır'),
        content: Text(
          '${category.name} için aylık limiti kaldırmak istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(budgetLimitsProvider.notifier)
        .removeForCategory(category.id);
  }
}

class _LimitDialog extends StatefulWidget {
  const _LimitDialog({required this.categoryName, this.initialAmount});

  final String categoryName;
  final double? initialAmount;

  @override
  State<_LimitDialog> createState() => _LimitDialogState();
}

class _LimitDialogState extends State<_LimitDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController = TextEditingController(
    text: widget.initialAmount == null
        ? ''
        : formatTry(widget.initialAmount!).replaceFirst('₺', ''),
  );

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialAmount != null;
    return AlertDialog(
      title: Text(editing ? 'Limiti düzenle' : 'Limit belirle'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.categoryName),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Aylık limit',
                hintText: '1.000,00',
                prefixText: '₺ ',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (parseAmount(value ?? '') == null) {
                  return 'Geçerli bir tutar girin';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(parseAmount(_amountController.text));
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
