import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/credit_card.dart';
import '../providers/finance_providers.dart';
import '../utils/format.dart';

class CardFormScreen extends ConsumerStatefulWidget {
  const CardFormScreen({super.key, this.existing});

  final CreditCard? existing;

  @override
  ConsumerState<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends ConsumerState<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bankController;
  late final TextEditingController _limitController;
  late final TextEditingController _debtController;
  late final TextEditingController _statementDayController;
  late final TextEditingController _dueDayController;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _bankController = TextEditingController(text: existing?.bankName ?? '');
    _limitController = TextEditingController(
      text: existing == null ? '' : amountToField(existing.limit),
    );
    _debtController = TextEditingController(
      text: existing == null ? '' : amountToField(existing.currentDebt),
    );
    _statementDayController = TextEditingController(
      text: existing == null ? '' : '${existing.statementDay}',
    );
    _dueDayController = TextEditingController(
      text: existing == null ? '' : '${existing.dueDay}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankController.dispose();
    _limitController.dispose();
    _debtController.dispose();
    _statementDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Kartı Düzenle' : 'Kart Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Kart adı',
                hintText: 'Ziraat Bankası Platinum',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kart adı gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bankController,
              decoration: const InputDecoration(
                labelText: 'Banka',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Banka gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _limitController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Limit',
                suffixText: '₺',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _positive(value, 'Geçerli bir limit girin'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _debtController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Ekstre / borç tutarı',
                suffixText: '₺',
                helperText: 'Borç 0 ise son ödeme günü listelenmez.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = parseTryInput(value ?? '');
                if (amount == null || amount < 0) {
                  return 'Geçerli bir tutar girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _statementDayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ekstre kesim günü',
                helperText: '1-31',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _day(value, 'Ekstre günü 1-31 olmalı'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dueDayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Son ödeme günü',
                helperText: '1-31',
                border: OutlineInputBorder(),
              ),
              validator: (value) => _day(value, 'Son ödeme günü 1-31 olmalı'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
            ),
            if (editing) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _saving ? null : _confirmDelete,
                child: const Text('Kartı sil'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _positive(String? value, String message) {
    final amount = parseTryInput(value ?? '');
    if (amount == null || amount <= 0) return message;
    return null;
  }

  String? _day(String? value, String message) {
    final day = int.tryParse((value ?? '').trim());
    if (day == null || day < 1 || day > 31) return message;
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final existing = widget.existing;
    final card = CreditCard(
      id: existing?.id,
      name: _nameController.text.trim(),
      bankName: _bankController.text.trim(),
      limit: parseTryInput(_limitController.text)!,
      currentDebt: parseTryInput(_debtController.text) ?? 0,
      statementDay: int.parse(_statementDayController.text.trim()),
      dueDay: int.parse(_dueDayController.text.trim()),
      color: existing?.color,
      isActive: existing?.isActive ?? true,
      createdAt: existing?.createdAt,
    );
    await ref.read(creditCardsProvider.notifier).upsert(card);
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
          title: const Text('Kartı sil'),
          content: const Text('Bu kredi kartı silinsin mi?'),
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
    await ref.read(creditCardsProvider.notifier).delete(existing.id);
    if (!mounted) return;
    Navigator.pop(context);
  }
}
