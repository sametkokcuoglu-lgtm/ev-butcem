import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_statement.dart';
import '../models/credit_card.dart';
import '../providers/statement_actions.dart';
import '../utils/form_validators.dart';
import '../utils/money.dart';
import '../widgets/amount_form_field.dart';

class StatementFormScreen extends ConsumerStatefulWidget {
  const StatementFormScreen({
    super.key,
    required this.card,
    this.statement,
  });

  final CreditCard card;
  final CardStatement? statement;

  @override
  ConsumerState<StatementFormScreen> createState() =>
      _StatementFormScreenState();
}

class _StatementFormScreenState extends ConsumerState<StatementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _total;
  late final TextEditingController _minimum;
  late final TextEditingController _paid;
  late DateTime _periodDate;
  late DateTime _dueDate;
  String? _paidError;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.statement;
    final today = DateTime.now();
    _periodDate =
        existing?.periodDate ?? DateTime(today.year, today.month, today.day);
    _dueDate = existing?.dueDate ?? _periodDate.add(const Duration(days: 10));
    _total = TextEditingController(
      text: existing == null ? '' : formatAmountInput(existing.totalAmount),
    );
    _minimum = TextEditingController(
      text: formatAmountInput(existing?.minimumPayment ?? 0),
    );
    _paid = TextEditingController(
      text: formatAmountInput(existing?.paidAmount ?? 0),
    );
    _total.addListener(_refresh);
    _paid.addListener(_refresh);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _paidError = null);
  }

  @override
  void dispose() {
    _total.removeListener(_refresh);
    _paid.removeListener(_refresh);
    _total.dispose();
    _minimum.dispose();
    _paid.dispose();
    super.dispose();
  }

  StatementStatus get _status {
    final total = parseAmount(_total.text) ?? 0;
    final paid = parseAmount(_paid.text) ?? 0;
    return StatementStatus.fromAmounts(total, paid);
  }

  Future<void> _pickDate({required bool period}) async {
    final initial = period ? _periodDate : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      final date = DateTime(picked.year, picked.month, picked.day);
      if (period) {
        _periodDate = date;
      } else {
        _dueDate = date;
      }
    });
  }

  void _applyStatus(StatementStatus status) {
    final total = parseAmount(_total.text);
    if (status == StatementStatus.paid && total != null) {
      _paid.text = formatAmountInput(total);
    } else if (status == StatementStatus.unpaid) {
      _paid.text = formatAmountInput(0);
    } else {
      setState(() {});
    }
  }

  String? _validatePaid(String? value) {
    final amountError = validateAmount(
      value,
      requiredField: true,
      emptyMessage: 'Ödenen tutar gerekli',
      invalidMessage: 'Geçerli bir tutar girin',
      negativeMessage: 'Ödenen tutar negatif olamaz',
    );
    if (amountError != null) return amountError;
    final total = parseAmount(_total.text);
    final paid = parseAmount(value);
    if (total != null && paid != null && paid > total + 0.001) {
      return 'Ödenen tutar ekstre tutarını aşamaz';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final total = parseAmount(_total.text);
    final minimum = parseAmount(_minimum.text);
    final paid = parseAmount(_paid.text);
    if (total == null || minimum == null || paid == null) return;
    final paidError = _validatePaid(_paid.text);
    if (paidError != null) {
      setState(() => _paidError = paidError);
      return;
    }

    _saving = true;
    final statement = CardStatement(
      id: widget.statement?.id,
      creditCardId: widget.card.id,
      periodDate: _periodDate,
      dueDate: _dueDate,
      totalAmount: total,
      minimumPayment: minimum,
      paidAmount: paid,
      createdAt: widget.statement?.createdAt,
    );
    if (!mounted) return;
    final actions = StatementActions(ref);
    Navigator.of(context).pop();
    await actions.save(statement, previous: widget.statement);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.statement != null;
    final dueBeforePeriod = _dueDate.isBefore(_periodDate);
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Ekstreyi Düzenle' : 'Yeni Ekstre')),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.card.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hesap kesim tarihi'),
                    subtitle: Text(formatTrDate(_periodDate)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () => _pickDate(period: true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Son ödeme tarihi'),
                    subtitle: Text(formatTrDate(_dueDate)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () => _pickDate(period: false),
                  ),
                  if (dueBeforePeriod)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Son ödeme tarihi, hesap kesiminden önce.',
                        style:
                            TextStyle(color: Color(0xFFB45309), fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 8),
                  AmountFormField(
                    key: const Key('statement-total'),
                    controller: _total,
                    label: 'Ekstre tutarı',
                    emptyMessage: 'Ekstre tutarı gerekli',
                    negativeMessage: 'Ekstre tutarı negatif olamaz',
                  ),
                  const SizedBox(height: 14),
                  AmountFormField(
                    key: const Key('statement-minimum'),
                    controller: _minimum,
                    label: 'Asgari ödeme',
                    emptyMessage: 'Asgari ödeme gerekli',
                    negativeMessage: 'Asgari ödeme negatif olamaz',
                  ),
                  const SizedBox(height: 14),
                  AmountFormField(
                    key: const Key('statement-paid'),
                    controller: _paid,
                    label: 'Ödenen tutar',
                    emptyMessage: 'Ödenen tutar gerekli',
                    negativeMessage: 'Ödenen tutar negatif olamaz',
                  ),
                  if (_paidError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _paidError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Durum',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final status in StatementStatus.values)
                        ChoiceChip(
                          label: Text(status.label),
                          selected: _status == status,
                          onSelected: (_) => _applyStatus(status),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ödenen tutar kart borcundan düşülür.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Kaydet'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
