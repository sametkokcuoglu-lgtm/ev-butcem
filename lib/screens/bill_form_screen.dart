import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../models/bill.dart';
import '../models/category.dart';
import '../models/planned_payment.dart';
import '../providers/finance_providers.dart';
import '../utils/format.dart';

class BillFormScreen extends ConsumerStatefulWidget {
  const BillFormScreen({super.key, this.existing});

  final Bill? existing;

  @override
  ConsumerState<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends ConsumerState<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _dueDate;
  late PaymentRecurrence _recurrence;
  late bool _isPaid;
  String? _categoryId;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _amountController = TextEditingController(
      text: existing == null ? '' : amountToField(existing.amount),
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _dueDate = existing?.dueDate ?? DateTime.now();
    _recurrence = existing?.recurrence ?? PaymentRecurrence.monthly;
    _isPaid = existing?.isPaid ?? false;
    _categoryId = existing?.categoryId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref
        .watch(categoriesProvider)
        .where((category) => !category.isIncome)
        .toList();
    final editing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Faturayı Düzenle' : 'Fatura Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                hintText: 'Elektrik, su, internet, aidat...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Başlık gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Tutar',
                suffixText: '₺',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = parseTryInput(value ?? '');
                if (amount == null || amount <= 0) {
                  return 'Geçerli bir tutar girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Iconsax.calendar_1),
              title: const Text('Son ödeme tarihi'),
              subtitle: Text(formatTrDate(_dueDate)),
              trailing: const Icon(Iconsax.arrow_right_3),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            const Text('Tekrar', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final option in PaymentRecurrence.values)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: _recurrence == option,
                    onSelected: (_) => setState(() => _recurrence = option),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Not',
                hintText: 'İsteğe bağlı',
                border: OutlineInputBorder(),
              ),
            ),
            _LinkTile(
              icon: Iconsax.category,
              title: 'Kategori',
              value: _categoryLabel(categories),
              onTap: () => _pickCategory(categories),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ödendi'),
              value: _isPaid,
              onChanged: (value) => setState(() => _isPaid = value),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
            ),
            if (editing) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _saving ? null : _confirmDelete,
                child: const Text('Faturayı sil'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _categoryLabel(List<Category> categories) {
    for (final category in categories) {
      if (category.id == _categoryId) {
        return '${category.icon} ${category.name}';
      }
    }
    return 'Seçilmedi';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _dueDate = picked);
  }

  Future<void> _pickCategory(List<Category> categories) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Kategori')),
              ListTile(
                title: const Text('Seçilmedi'),
                onTap: () => Navigator.pop(context, ''),
              ),
              for (final category in categories)
                ListTile(
                  title: Text('${category.icon} ${category.name}'),
                  onTap: () => Navigator.pop(context, category.id),
                ),
            ],
          ),
        );
      },
    );
    if (result == null) return;
    setState(() => _categoryId = result.isEmpty ? null : result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final existing = widget.existing;
    final note = _noteController.text.trim();
    final bill = Bill(
      id: existing?.id,
      title: _titleController.text.trim(),
      amount: parseTryInput(_amountController.text)!,
      dueDate: _dueDate,
      recurrence: _recurrence,
      isPaid: _isPaid,
      categoryId: _categoryId,
      note: note.isEmpty ? null : note,
      createdAt: existing?.createdAt,
    );
    await ref.read(billsProvider.notifier).upsert(bill);
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Faturayı sil'),
          content: const Text('Bu fatura silinsin mi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    await ref.read(billsProvider.notifier).delete(existing.id);
    if (!mounted) return;
    Navigator.pop(context);
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Iconsax.arrow_right_3),
      onTap: onTap,
    );
  }
}
