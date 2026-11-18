import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account.dart';
import '../providers/wallet_providers.dart';
import '../utils/account_style.dart';
import '../utils/form_validators.dart';
import '../utils/money.dart';
import '../widgets/amount_form_field.dart';
import '../widgets/style_pickers.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.account});

  final Account? account;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bank;
  late final TextEditingController _balance;
  late final TextEditingController _iban;
  late final TextEditingController _overdraft;
  late AccountType _type;
  late String _currency;
  late String _color;
  late String _icon;
  var _iconTouched = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.account;
    final iban = existing?.iban;
    final overdraft = existing?.overdraftLimit;
    _name = TextEditingController(text: existing?.name ?? '');
    _bank = TextEditingController(text: existing?.bankName ?? '');
    _balance = TextEditingController(
      text: existing == null ? '' : formatAmountInput(existing.balance),
    );
    _iban = TextEditingController(text: iban == null ? '' : formatIban(iban));
    _overdraft = TextEditingController(
      text: overdraft == null ? '' : formatAmountInput(overdraft),
    );
    _type = existing?.type ?? AccountType.vadesiz;
    _currency = (existing?.currency ?? 'TRY').toUpperCase();
    _color = existing?.color ?? defaultAccountColor;
    _icon = existing?.icon ?? defaultIconKeyFor(_type);
    _iconTouched = existing?.icon != null;
  }

  @override
  void dispose() {
    _name.dispose();
    _bank.dispose();
    _balance.dispose();
    _iban.dispose();
    _overdraft.dispose();
    super.dispose();
  }

  List<CurrencyOption> get _currencies {
    final known = currencyOptions.any((option) => option.code == _currency);
    if (known) return currencyOptions;
    return [...currencyOptions, CurrencyOption(_currency, _currency)];
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final balance = parseAmount(_balance.text);
    if (balance == null) return;
    final overdraftText = _overdraft.text.trim();
    final overdraft = overdraftText.isEmpty ? null : parseAmount(overdraftText);
    if (overdraftText.isNotEmpty && overdraft == null) return;

    _saving = true;
    final saved = Account(
      id: widget.account?.id,
      name: _name.text.trim(),
      bankName: _bank.text.trim(),
      balance: balance,
      currency: _currency,
      color: _color,
      isActive: widget.account?.isActive ?? true,
      createdAt: widget.account?.createdAt,
      accountType: _type.name,
      iban: normalizeIban(_iban.text),
      icon: _icon,
      overdraftLimit: overdraft,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    await ref.read(accountsProvider.notifier).save(saved);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.account != null;
    final accent = parseHexColor(_color);
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Hesabı Düzenle' : 'Yeni Hesap')),
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
                    key: const Key('account-name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Hesap adı'),
                    validator: (value) => validateRequiredText(
                      value,
                      emptyMessage: 'Hesap adı gerekli',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('account-bank'),
                    controller: _bank,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Banka adı'),
                    validator: (value) => validateRequiredText(
                      value,
                      emptyMessage: 'Banka adı gerekli',
                    ),
                  ),
                  const SizedBox(height: 18),
                  const FormSectionLabel('Hesap türü'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final type in AccountType.values)
                        ChoiceChip(
                          label: Text(type.label),
                          selected: _type == type,
                          onSelected: (_) {
                            setState(() {
                              _type = type;
                              if (!_iconTouched) {
                                _icon = defaultIconKeyFor(type);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AmountFormField(
                    key: const Key('account-balance'),
                    controller: _balance,
                    label: 'Bakiye',
                    allowNegative: true,
                    emptyMessage: 'Bakiye gerekli',
                    negativeMessage: 'Geçerli bir tutar girin',
                  ),
                  const SizedBox(height: 18),
                  const FormSectionLabel('Para birimi'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in _currencies)
                        ChoiceChip(
                          label: Text(option.label),
                          selected: _currency == option.code,
                          onSelected: (_) =>
                              setState(() => _currency = option.code),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('account-iban'),
                    controller: _iban,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9 ]'),
                      ),
                      LengthLimitingTextInputFormatter(42),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'IBAN (isteğe bağlı)',
                    ),
                    validator: validateIban,
                  ),
                  const SizedBox(height: 14),
                  AmountFormField(
                    key: const Key('account-overdraft'),
                    controller: _overdraft,
                    label: 'KMH limiti (isteğe bağlı)',
                    requiredField: false,
                    emptyMessage: '',
                    negativeMessage: 'KMH limiti negatif olamaz',
                  ),
                  const SizedBox(height: 18),
                  const FormSectionLabel('Renk'),
                  ColorPicker(
                    selected: _color,
                    onSelected: (hex) => setState(() => _color = hex),
                  ),
                  const SizedBox(height: 18),
                  const FormSectionLabel('İkon'),
                  IconPicker(
                    selectedKey: _icon,
                    color: accent,
                    onSelected: (key) => setState(() {
                      _iconTouched = true;
                      _icon = key;
                    }),
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
