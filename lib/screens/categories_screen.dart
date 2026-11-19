import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../providers/transaction_provider.dart';
import '../services/category_repository.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/category_avatar.dart';
import '../widgets/content_frame.dart';
import 'category_form_screen.dart';

enum _CategoryAction { edit, delete }

/// Kategori ekleme / düzenleme formunu açar; kaydedilen kategoriyi döndürür.
Future<Category?> openCategoryForm(
  BuildContext context, {
  Category? category,
  bool isIncome = false,
}) {
  return Navigator.of(context).push<Category>(
    MaterialPageRoute(
      builder: (_) => CategoryFormScreen(category: category, initialIsIncome: isIncome),
    ),
  );
}

/// Kategoriler: gider ve gelir kategorileri iki sekmede.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Kategoriler'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Gider'),
                Tab(text: 'Gelir'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _CategoryList(isIncome: false),
              _CategoryList(isIncome: true),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('addCategoryButton'),
            onPressed: () => openCategoryForm(
              context,
              isIncome: DefaultTabController.of(context).index == 1,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Yeni Kategori'),
          ),
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final bool isIncome;

  const _CategoryList({required this.isIncome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).where((c) => c.isIncome == isIncome).toList();
    final usage = <String, int>{};
    for (final t in ref.watch(transactionsProvider)) {
      usage[t.categoryId] = (usage[t.categoryId] ?? 0) + 1;
    }

    if (categories.isEmpty) {
      return Center(child: Text('Henüz ${isIncome ? 'gelir' : 'gider'} kategorisi yok'));
    }
    return ContentFrame(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, 96),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.item),
        itemBuilder: (context, i) => _CategoryTile(
          key: ValueKey(categories[i].id),
          category: categories[i],
          usageCount: usage[categories[i].id] ?? 0,
        ),
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final Category category;
  final int usageCount;

  const _CategoryTile({super.key, required this.category, required this.usageCount});

  Future<void> _handle(BuildContext context, WidgetRef ref, _CategoryAction? action) async {
    switch (action) {
      case _CategoryAction.edit:
        await openCategoryForm(context, category: category);
      case _CategoryAction.delete:
        await deleteCategoryFlow(context, ref, category);
      case null:
        break;
    }
  }

  Future<void> _showContextMenu(BuildContext context, WidgetRef ref, Offset position) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final action = await showMenu<_CategoryAction>(
      context: context,
      position: RelativeRect.fromRect(position & const Size(1, 1), Offset.zero & overlay.size),
      items: const [
        PopupMenuItem(value: _CategoryAction.edit, child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Düzenle'))),
        PopupMenuItem(value: _CategoryAction.delete, child: ListTile(leading: Icon(Icons.delete_outline_rounded), title: Text('Sil'))),
      ],
    );
    if (context.mounted) await _handle(context, ref, action);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = category;
    final subtitle = [
      usageCount == 0 ? 'İşlem yok' : '$usageCount işlem',
      if (c.isSystem) 'Varsayılan',
    ].join(' · ');

    return GestureDetector(
      onSecondaryTapDown: (d) => _showContextMenu(context, ref, d.globalPosition),
      child: AppCard(
        padding: EdgeInsets.zero,
        radius: AppSpacing.radiusMd,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          onTap: () => openCategoryForm(context, category: c),
          leading: CategoryAvatar(icon: c.icon, colorValue: c.colorValue, size: 42),
          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: PopupMenuButton<_CategoryAction>(
            key: ValueKey('categoryMenu-${c.id}'),
            tooltip: 'İşlemler',
            onSelected: (a) => _handle(context, ref, a),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _CategoryAction.edit, child: Text('Düzenle')),
              PopupMenuItem(value: _CategoryAction.delete, child: Text('Sil')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kategori silme akışı:
/// - Türün son kategorisiyse silme engellenir.
/// - Kategoride işlem yoksa basit onay istenir.
/// - İşlem varsa, işlemlerin taşınacağı aynı türden kategori seçtirilir.
Future<void> deleteCategoryFlow(BuildContext context, WidgetRef ref, Category category) async {
  final notifier = ref.read(categoriesProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);

  final blocker = notifier.deleteBlocker(category.id);
  if (blocker != null) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategori silinemez'),
        content: Text(blocker),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))],
      ),
    );
    return;
  }

  final used = notifier.usageCount(category.id);
  String? moveToId;
  if (used == 0) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategori silinsin mi?'),
        content: Text('"${category.name}" kategorisi silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            key: const Key('confirmCategoryDeleteButton'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.expenseColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
  } else {
    final targets = ref
        .read(categoriesProvider)
        .where((c) => c.isIncome == category.isIncome && c.id != category.id)
        .toList();
    moveToId = await showDialog<String>(
      context: context,
      builder: (ctx) => _MoveTransactionsDialog(category: category, used: used, targets: targets),
    );
    if (moveToId == null) return;
  }

  try {
    final moved = await notifier.delete(category.id, moveToId: moveToId);
    messenger.showSnackBar(SnackBar(
      content: Text(moved > 0
          ? 'Kategori silindi, $moved işlem taşındı'
          : 'Kategori silindi'),
    ));
  } on CategoryException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

class _MoveTransactionsDialog extends StatefulWidget {
  final Category category;
  final int used;
  final List<Category> targets;

  const _MoveTransactionsDialog({required this.category, required this.used, required this.targets});

  @override
  State<_MoveTransactionsDialog> createState() => _MoveTransactionsDialogState();
}

class _MoveTransactionsDialogState extends State<_MoveTransactionsDialog> {
  String? _targetId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('İşlemler taşınsın'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${widget.category.name}" kategorisinde ${widget.used} işlem var. '
            'Silmeden önce bu işlemlerin taşınacağı kategoriyi seçin.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: const Key('moveTargetDropdown'),
            initialValue: _targetId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Yeni kategori', border: OutlineInputBorder()),
            items: [
              for (final c in widget.targets)
                DropdownMenuItem(value: c.id, child: Text('${c.icon}  ${c.name}')),
            ],
            onChanged: (id) => setState(() => _targetId = id),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
        FilledButton(
          key: const Key('moveAndDeleteButton'),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.expenseColor),
          onPressed: _targetId == null ? null : () => Navigator.pop(context, _targetId),
          child: const Text('Taşı ve Sil'),
        ),
      ],
    );
  }
}
