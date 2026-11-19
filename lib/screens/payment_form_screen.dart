import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../models/planned_payment.dart';
import '../providers/finance_providers.dart';
import '../utils/format.dart';

class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({super.key, this.existing});

  final PlannedPayment? existing;

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late DateTime _dueDate;
  late PaymentRecurrence _recurrence;
  late bool _isPaid;
  String? _accountId;
  String? _creditCardId;
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
    _dueDate = existing?.dueDate ?? DateTime.now();
    _recurrence = existing?.recurrence ?? PaymentRecurrence.none;
    _isPaid = existing?.isPaid ?? false;
    _accountId = existing?.accountId;
    _creditCardId = existing?.creditCardId;
    _categoryId = existing?.categoryId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref
        .watch(accountsProvider)
        .where((account) => account.isActive)
        .toList();
    final cards =
        ref.watch(creditCardsProvider).where((card) => card.isActive).toList();
    final categories = ref
        .watch(categoriesProvider)
        .where((category) => !category.isIncome)
        .toList();
    final editing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Ödemeyi Düzenle' : 'Ödeme Ekle')),
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
                hintText: 'Kira, elektrik, aidat...',
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
              title: const Text('Vade tarihi'),
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
            const SizedBox(height: 4),
            Text(
              'Aylık ve yıllık ödemeler vade tarihinden itibaren takvimde tekrarlanır.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            _LinkTile(
              icon: Iconsax.wallet_2,
              title: 'Hesap',
              value: _labelFor(
                  accounts
                      .map((account) => (id: account.id, label: account.name)),
                  _accountId),
              onTap: () => _pick(
                title: 'Hesap',
                options: [
                  for (final account in accounts)
                    (id: account.id, label: account.name),
                ],
                selectedId: _accountId,
                onSelected: (id) => setState(() => _accountId = id),
              ),
            ),
            _LinkTile(
              icon: Iconsax.card,
              title: 'Kredi kartı',
              value: _labelFor(
                  cards.map((card) => (id: card.id, label: card.name)),
                  _creditCardId),
              onTap: () => _pick(
                title: 'Kredi kartı',
                options: [
                  for (final card in cards) (id: card.id, label: card.name),
                ],
                selectedId: _creditCardId,
                onSelected: (id) => setState(() => _creditCardId = id),
              ),
            ),
            _LinkTile(
              icon: Iconsax.category,
              title: 'Kategori',
              value: _labelFor(
                categories.map((category) => (
                      id: category.id,
                      label: '${category.icon} ${category.name}'
                    )),
                _categoryId,
              ),
              onTap: () => _pick(
                title: 'Kategori',
                options: [
                  for (final category in categories)
                    (
                      id: category.id,
                      label: '${category.icon} ${category.name}'
                    ),
                ],
                selectedId: _categoryId,
                onSelected: (id) => setState(() => _categoryId = id),
              ),
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
                child: const Text('Ödemeyi sil'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _labelFor(Iterable<({String id, String label})> options, String? id) {
    for (final option in options) {
      if (option.id == id) return option.label;
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

  Future<void> _pick({
    required String title,
    required List<({String id, String label})> options,
    required String? selectedId,
    required ValueChanged<String?> onSelected,
  }) async {
    final result = await showModalBottomSheet<_PickResult>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text('Seçilmedi'),
                      trailing: selectedId == null
                          ? const Icon(Iconsax.tick_circle)
                          : null,
                      onTap: () =>
                          Navigator.pop(context, const _PickResult(null)),
                    ),
                    for (final option in options)
                      ListTile(
                        title: Text(option.label),
                        trailing: selectedId == option.id
                            ? const Icon(Iconsax.tick_circle)
                            : null,
                        onTap: () =>
                            Navigator.pop(context, _PickResult(option.id)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (result == null) return;
    onSelected(result.id);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final amount = parseTryInput(_amountController.text)!;
    final existing = widget.existing;
    final payment = PlannedPayment(
      id: existing?.id,
      title: _titleController.text.trim(),
      amount: amount,
      dueDate: _dueDate,
      recurrence: _recurrence,
      accountId: _accountId,
      creditCardId: _creditCardId,
      categoryId: _categoryId,
      isPaid: _isPaid,
      createdAt: existing?.createdAt,
    );
    await ref.read(plannedPaymentsProvider.notifier).upsert(payment);
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
          title: const Text('Ödemeyi sil'),
          content: const Text('Bu planlı ödeme silinsin mi?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sil')),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    await ref.read(plannedPaymentsProvider.notifier).delete(existing.id);
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

class _PickResult {
  const _PickResult(this.id);
  final String? id;
}
