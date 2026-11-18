import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../providers/transaction_provider.dart';
import '../services/category_repository.dart';
import '../theme/app_theme.dart';

/// Kategori ekleme / düzenleme formu.
///
/// Kaydedilen kategoriyi `Navigator.pop` ile döndürür.
class CategoryFormScreen extends ConsumerStatefulWidget {
  final Category? category;
  final bool initialIsIncome;

  const CategoryFormScreen({super.key, this.category, this.initialIsIncome = false});

  /// Formda sunulan simgeler.
  static const List<String> icons = [
    '🛒', '🏠', '🏢', '💡', '💧', '🔥', '🌐', '📱', '🚗', '⛽',
    '🚌', '🍽️', '☕', '🍔', '🏥', '💊', '🎓', '📚', '👕', '👶',
    '🐾', '🎁', '🎬', '🎮', '✈️', '🏖️', '💪', '💇', '🧹', '🔧',
    '🛋️', '📺', '🧾', '🛡️', '🏛️', '💳', '🏦', '📦', '❤️', '📌',
    '💰', '📈', '💼', '🪙', '💵', '🏷️', '🤝', '🎉',
  ];

  /// Formda sunulan renkler.
  static const List<int> colors = [
    0xFF16A34A, 0xFF22C55E, 0xFF0EA5E9, 0xFF2563EB, 0xFF4F46E5, 0xFF9333EA,
    0xFFDB2777, 0xFFDC2626, 0xFFEA580C, 0xFFF59E0B, 0xFF78716C, 0xFF0F766E,
  ];

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late bool _isIncome;
  late String _icon;
  late int _color;
  bool _saving = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameController = TextEditingController(text: c?.name ?? '');
    _isIncome = c?.isIncome ?? widget.initialIsIncome;
    _icon = c?.icon ?? (_isIncome ? '💰' : '📌');
    _color = c?.colorValue ?? CategoryFormScreen.colors[3];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final old = widget.category;
    final candidate = old != null
        ? old.copyWith(name: _nameController.text, icon: _icon, colorValue: _color, isIncome: _isIncome)
        : Category(name: _nameController.text, icon: _icon, colorValue: _color, isIncome: _isIncome);
    try {
      final saved = await ref.read(categoriesProvider.notifier).save(candidate);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Kategori güncellendi' : 'Kategori eklendi')),
      );
      Navigator.of(context).pop(saved);
    } on CategoryException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(categoriesProvider.notifier);
    // İşlemde kullanılan kategorinin türü değiştirilemez (toplamlar bozulmasın).
    final typeLocked = _isEditing && notifier.usageCount(widget.category!.id) > 0;
    final color = Color(_color);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Kategoriyi Düzenle' : 'Yeni Kategori')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(_icon, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Gider'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: true, label: Text('Gelir'), icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_isIncome},
              onSelectionChanged: typeLocked
                  ? null
                  : (s) => setState(() {
                        _isIncome = s.first;
                        _formKey.currentState?.validate();
                      }),
            ),
            if (typeLocked)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Bu kategoride işlem olduğu için türü değiştirilemez.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('categoryNameField'),
              controller: _nameController,
              maxLength: CategoryRepository.maxNameLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Kategori adı',
                hintText: 'Örn. Aidat',
                border: OutlineInputBorder(),
              ),
              validator: (v) => notifier.validateName(
                v ?? '',
                isIncome: _isIncome,
                excludeId: widget.category?.id,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Simge', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final icon in CategoryFormScreen.icons)
                  InkWell(
                    key: ValueKey('icon-$icon'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _icon = icon),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: icon == _icon ? color.withValues(alpha: 0.2) : null,
                        border: Border.all(
                          color: icon == _icon ? color : Colors.grey.withValues(alpha: 0.3),
                          width: icon == _icon ? 2 : 1,
                        ),
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Renk', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in CategoryFormScreen.colors)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _color = c),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(c),
                      child: c == _color ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      // Kaydet düğmesi her zaman görünür (simge listesi uzun olabilir).
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            key: const Key('saveCategoryButton'),
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.check),
            label: Text(_isEditing ? 'Güncelle' : 'Kaydet'),
          ),
        ),
      ),
    );
  }
}
