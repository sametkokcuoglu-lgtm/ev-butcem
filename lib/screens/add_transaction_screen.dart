import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/amount_parser.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/content_frame.dart';
import '../widgets/transaction_delete.dart';
import 'categories_screen.dart';

/// Gelir / Gider ekleme ve düzenleme formu.
///
/// [transaction] verilirse kayıt düzenlenir, verilmezse yeni kayıt eklenir.
class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final bool initialIsIncome;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.initialIsIncome = false,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late bool _isIncome;
  late DateTime _date;
  String? _categoryId;
  bool _saving = false;

  /// Formdan yeni kategori eklenince dropdown'ı yeni seçimle yeniden kurmak için.
  int _dropdownGeneration = 0;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _isIncome = t?.isIncome ?? widget.initialIsIncome;
    _date = t?.date ?? DateUtils.dateOnly(DateTime.now());
    _categoryId = t?.categoryId;
    _amountController = TextEditingController(
      text: t == null ? '' : AmountParser.toInput(t.amount),
    );
    _noteController = TextEditingController(text: t?.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Seçili türe (gelir/gider) ait kategoriler, id'ye göre tekil.
  List<Category> _categoriesFor(List<Category> all) {
    final seen = <String>{};
    return [
      for (final c in all)
        if (c.isIncome == _isIncome && seen.add(c.id)) c,
    ];
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'İşlem tarihi',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final amount = AmountParser.parse(_amountController.text)!;
    final note = _noteController.text.trim();
    final old = widget.transaction;
    final transaction = Transaction(
      id: old?.id,
      amount: amount,
      categoryId: _categoryId!,
      accountId: old?.accountId,
      creditCardId: old?.creditCardId,
      date: _date,
      note: note.isEmpty ? null : note,
      isIncome: _isIncome,
      // Düzenlemede id ve createdAt korunur, updatedAt şimdiye çekilir.
      createdAt: old?.createdAt,
      updatedAt: DateTime.now(),
    );

    final notifier = ref.read(transactionsProvider.notifier);
    try {
      if (_isEditing) {
        await notifier.edit(transaction);
      } else {
        await notifier.add(transaction);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'İşlem güncellendi' : 'İşlem kaydedildi')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydedilemedi: $e')),
      );
    }
  }

  Future<void> _addCategory() async {
    final created = await openCategoryForm(context, isIncome: _isIncome);
    if (created == null || !mounted) return;
    setState(() {
      _isIncome = created.isIncome;
      _categoryId = created.id;
      _dropdownGeneration++;
    });
  }

  Future<void> _delete() async {
    final t = widget.transaction;
    if (t == null || _saving) return;
    final category = ref.read(categoryMapProvider)[t.categoryId];
    if (!await confirmTransactionDelete(context, t, category)) return;
    if (!mounted) return;
    await deleteTransactionWithUndo(context, ref, t);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoriesFor(ref.watch(categoriesProvider));
    // Dropdown'a verilen değer mutlaka listedeki öğelerden biri olmalı;
    // değilse (tür değişti, kategori silindi vb.) seçim boşaltılır.
    final selectedId = categories.any((c) => c.id == _categoryId) ? _categoryId : null;
    final finance = FinanceColors.of(context);
    final color = _isIncome ? finance.income : finance.expense;
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'İşlemi Düzenle' : (_isIncome ? 'Gelir Ekle' : 'Gider Ekle')),
        actions: [
          if (_isEditing)
            IconButton(
              key: const Key('deleteTransactionButton'),
              tooltip: 'İşlemi sil',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: ContentFrame(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.lg),
                  children: [
                    SegmentedButton<bool>(
                      expandedInsets: EdgeInsets.zero,
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) return Colors.white;
                          return theme.colorScheme.onSurfaceVariant;
                        }),
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) return color;
                          return theme.cardColor;
                        }),
                      ),
                      segments: const [
                        ButtonSegment(value: false, label: Text('Gider'), icon: Icon(Icons.north_rounded, size: 18)),
                        ButtonSegment(value: true, label: Text('Gelir'), icon: Icon(Icons.south_rounded, size: 18)),
                      ],
                      selected: {_isIncome},
                      onSelectionChanged: (s) => setState(() {
                        if (_isIncome != s.first) {
                          _isIncome = s.first;
                          _categoryId = null; // Eski türün kategorisi yeni listede yok.
                        }
                      }),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                      child: Column(
                        children: [
                          Text('Tutar', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          TextFormField(
                            key: const Key('amountField'),
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.next,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: color,
                              height: 1.15,
                            ),
                            decoration: InputDecoration(
                              hintText: '0,00',
                              hintStyle: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                              ),
                              suffixText: '₺',
                              suffixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Tutar girin';
                              final amount = AmountParser.parse(v);
                              if (amount == null) return 'Geçerli bir tutar girin (örn. 1.250,50)';
                              if (amount <= 0) return 'Tutar sıfırdan büyük olmalı';
                              if (amount > 1000000000) return 'Tutar çok büyük';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      // Tür değişince alan yeniden kurulur; eski değer taşınmaz.
                      key: ValueKey('category-$_isIncome-$_dropdownGeneration'),
                      initialValue: selectedId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      hint: Text(categories.isEmpty ? 'Kategori bulunamadı' : 'Kategori seçin'),
                      items: [
                        for (final c in categories)
                          DropdownMenuItem<String>(
                            value: c.id,
                            child: Text('${c.icon}  ${c.name}', overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (id) => setState(() => _categoryId = id),
                      validator: (id) => id == null ? 'Kategori seçin' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: const Key('newCategoryButton'),
                        onPressed: _addCategory,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Yeni kategori'),
                      ),
                    ),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tarih',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                          suffixIcon: Icon(Icons.south_rounded, size: 18),
                        ),
                        child: Text(AppFormatters.date(_date)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      key: const Key('noteField'),
                      controller: _noteController,
                      maxLength: 200,
                      maxLines: 3,
                      minLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama (isteğe bağlı)',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 28),
                          child: Icon(Icons.sticky_note_2_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('saveButton'),
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_isEditing ? 'Güncelle' : 'Kaydet'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
