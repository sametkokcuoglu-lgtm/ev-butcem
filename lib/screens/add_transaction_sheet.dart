import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/budget_providers.dart';
import '../theme/app_theme.dart';
import '../utils/budget_progress.dart';
import '../utils/format.dart';

Future<void> showAddTransactionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: const AddTransactionSheet(),
      );
    },
  );
}

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isIncome = false;
  String? _categoryId;
  bool _saving = false;
  late DateTime _date = _today();

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<Category> _matching(List<Category> categories) {
    return [
      for (final category in categories)
        if (category.isIncome == _isIncome) category,
    ];
  }

  String? _selectedCategoryId(List<Category> matching) {
    if (matching.any((category) => category.id == _categoryId)) {
      return _categoryId;
    }
    if (matching.isEmpty) return null;
    return matching.first.id;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
    );
    if (picked == null) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _save(List<Category> matching) async {
    if (!_formKey.currentState!.validate()) return;
    final amount = parseAmount(_amountController.text);
    final categoryId = _selectedCategoryId(matching);
    if (amount == null || categoryId == null) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final note = _noteController.text.trim();
    final saved = Transaction(
      amount: amount,
      categoryId: categoryId,
      date: _date,
      note: note.isEmpty ? null : note,
      isIncome: _isIncome,
    );
    try {
      await ref.read(transactionsProvider.notifier).add(saved);
      if (!mounted) return;
      final alert = budgetAlertForTransaction(
        transaction: saved,
        transactions: ref.read(transactionsProvider),
        limits: ref.read(budgetLimitsProvider),
        categories: ref.read(categoriesProvider),
      );
      navigator.pop();
      if (alert == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('İşlem kaydedildi')),
        );
      } else {
        final exceeded = alert.startsWith('Limit aşıldı');
        messenger.showSnackBar(
          SnackBar(
            content: Text(alert),
            backgroundColor:
                exceeded ? AppTheme.expenseColor : AppTheme.warningColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matching = _matching(ref.watch(categoriesProvider));
    final selectedId = _selectedCategoryId(matching);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Yeni İşlem',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<bool>(value: false, label: Text('Gider')),
                  ButtonSegment<bool>(value: true, label: Text('Gelir')),
                ],
                selected: {_isIncome},
                onSelectionChanged: (selection) {
                  setState(() {
                    _isIncome = selection.first;
                    _categoryId = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('transaction-amount'),
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Tutar',
                  hintText: '1.234,56',
                  prefixText: '₺ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (parseAmount(value ?? '') == null) {
                    return 'Geçerli bir tutar girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (matching.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Kategori bulunamadı'),
                )
              else
                DropdownButtonFormField<String>(
                  key: ValueKey('category-$_isIncome'),
                  initialValue: selectedId,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final category in matching)
                      DropdownMenuItem<String>(
                        value: category.id,
                        child: Text('${category.icon}  ${category.name}'),
                      ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                  validator: (value) => value == null ? 'Kategori seçin' : null,
                ),
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Iconsax.calendar_1),
                title: const Text('Tarih'),
                subtitle: Text(formatFullDate(_date)),
                trailing: const Icon(Iconsax.arrow_right_3),
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Not',
                  hintText: 'İsteğe bağlı',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('transaction-save'),
                onPressed: _saving ? null : () => _save(matching),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
