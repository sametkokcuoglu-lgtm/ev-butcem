import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../models/credit_card.dart';
import '../providers/wallet_providers.dart';
import '../theme/app_theme.dart';
import '../utils/account_style.dart';
import '../utils/form_validators.dart';
import '../utils/money.dart';
import '../widgets/amount_form_field.dart';
import '../widgets/style_pickers.dart';

class CreditCardFormScreen extends ConsumerStatefulWidget {
  const CreditCardFormScreen({super.key, this.card});

  final CreditCard? card;

  @override
  ConsumerState<CreditCardFormScreen> createState() =>
      _CreditCardFormScreenState();
}

class _CreditCardFormScreenState extends ConsumerState<CreditCardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bank;
  late final TextEditingController _lastFour;
  late final TextEditingController _limit;
  late final TextEditingController _debt;
  late final TextEditingController _statementDay;
  late final TextEditingController _dueDay;
  late final TextEditingController _minimum;
  late String _color;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.card;
    final minimum = existing?.minimumPayment;
    _name = TextEditingController(text: existing?.name ?? '');
    _bank = TextEditingController(text: existing?.bankName ?? '');
    _lastFour = TextEditingController(text: existing?.lastFourDigits ?? '');
    _limit = TextEditingController(
      text: existing == null ? '' : formatAmountInput(existing.limit),
    );
    _debt = TextEditingController(
      text: existing == null ? '' : formatAmountInput(existing.currentDebt),
    );
    _statementDay = TextEditingController(
      text: existing == null ? '' : '${existing.statementDay}',
    );
    _dueDay = TextEditingController(
      text: existing == null ? '' : '${existing.dueDay}',
    );
    _minimum = TextEditingController(
      text: minimum == null ? '' : formatAmountInput(minimum),
    );
    _color = existing?.color ?? defaultAccountColor;
    _limit.addListener(_refreshWarning);
    _debt.addListener(_refreshWarning);
  }

  @override
  void dispose() {
    _limit.removeListener(_refreshWarning);
    _debt.removeListener(_refreshWarning);
    _name.dispose();
    _bank.dispose();
    _lastFour.dispose();
    _limit.dispose();
    _debt.dispose();
    _statementDay.dispose();
    _dueDay.dispose();
    _minimum.dispose();
    super.dispose();
  }

  void _refreshWarning() {
    if (mounted) setState(() {});
  }

  bool get _debtExceedsLimit {
    final limit = parseAmount(_limit.text);
    final debt = parseAmount(_debt.text);
    if (limit == null || debt == null) return false;
    return debt > limit;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final limit = parseAmount(_limit.text);
    final debt = parseAmount(_debt.text);
    final statementDay = int.tryParse(_statementDay.text.trim());
    final dueDay = int.tryParse(_dueDay.text.trim());
    if (limit == null ||
        debt == null ||
        statementDay == null ||
        dueDay == null) {
      return;
    }
    final minimumText = _minimum.text.trim();
    final minimum = minimumText.isEmpty ? null : parseAmount(minimumText);
    if (minimumText.isNotEmpty && minimum == null) return;

    _saving = true;
    final saved = CreditCard(
      id: widget.card?.id,
      name: _name.text.trim(),
      bankName: _bank.text.trim(),
      limit: limit,
      currentDebt: debt,
      statementDay: statementDay,
      dueDay: dueDay,
      color: _color,
      isActive: widget.card?.isActive ?? true,
      createdAt: widget.card?.createdAt,
      lastFourDigits:
          _lastFour.text.trim().isEmpty ? null : _lastFour.text.trim(),
      minimumPayment: minimum,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    await ref.read(creditCardsProvider.notifier).save(saved);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.card != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Kartı Düzenle' : 'Yeni Kart')),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    key: const Key('card-name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Kart adı'),
                    validator: (value) => validateRequiredText(
                      value,
                      emptyMessage: 'Kart adı gerekli',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('card-bank'),
                    controller: _bank,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Banka adı'),
                    validator: (value) => validateRequiredText(
                      value,
                      emptyMessage: 'Banka adı gerekli',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('card-last-four'),
                    controller: _lastFour,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Son 4 hane (isteğe bağlı)',
                    ),
                    validator: validateLastFour,
                  ),
                  const SizedBox(height: 14),
                  AmountFormField(
                    key: const Key('card-limit'),
                    controller: _limit,
                    label: 'Toplam limit',
                    emptyMessage: 'Toplam limit gerekli',
                    negativeMessage: 'Limit negatif olamaz',
                  ),
                  const SizedBox(height: 14),
                  AmountFormField(
                    key: const Key('card-debt'),
                    controller: _debt,
                    label: 'Güncel borç',
                    emptyMessage: 'Güncel borç gerekli',
                    negativeMessage: 'Borç negatif olamaz',
                  ),
                  if (_debtExceedsLimit) ...[
                    const SizedBox(height: 10),
                    const _DebtWarning(),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DayFormField(
                          key: const Key('card-statement-day'),
                          controller: _statementDay,
                          label: 'Hesap kesim günü',
                          emptyMessage: 'Hesap kesim günü gerekli',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DayFormField(
                          key: const Key('card-due-day'),
                          controller: _dueDay,
                          label: 'Son ödeme günü',
                          emptyMessage: 'Son ödeme günü gerekli',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AmountFormField(
                    key: const Key('card-minimum'),
                    controller: _minimum,
                    label: 'Asgari ödeme (isteğe bağlı)',
                    requiredField: false,
                    emptyMessage: '',
                    negativeMessage: 'Asgari ödeme negatif olamaz',
                  ),
                  const SizedBox(height: 18),
                  const FormSectionLabel('Renk'),
                  ColorPicker(
                    selected: _color,
                    onSelected: (hex) => setState(() => _color = hex),
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
                  child: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtWarning extends StatelessWidget {
  const _DebtWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.warning_2, color: AppTheme.warningColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Borç, kart limitini aşıyor. Yine de kaydedebilirsiniz.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
