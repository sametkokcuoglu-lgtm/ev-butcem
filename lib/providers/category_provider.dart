import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/category.dart';
import '../services/category_repository.dart';
import '../utils/text_utils.dart';
import 'transaction_provider.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(Hive.box<Category>(CategoryRepository.boxName)),
);

/// Kayıtlı kategoriler; ekleme, düzenleme ve silmede anında güncellenir.
/// Liste Türk alfabesine göre sıralıdır.
class CategoriesNotifier extends Notifier<List<Category>> {
  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  @override
  List<Category> build() => _sorted(ref.watch(categoryRepositoryProvider).getAll());

  String? validateName(String name, {required bool isIncome, String? excludeId}) =>
      _repo.validateName(name, isIncome: isIncome, excludeId: excludeId);

  /// Kategoriyi kullanan işlem sayısı.
  int usageCount(String categoryId) =>
      ref.read(transactionsProvider).where((t) => t.categoryId == categoryId).length;

  /// Silmeye engel bir durum varsa mesajı (örn. türün son kategorisi).
  String? deleteBlocker(String categoryId) => _repo.deleteBlocker(categoryId);

  /// Ekler veya günceller. Kural ihlalinde [CategoryException] fırlatır.
  Future<Category> save(Category category) async {
    final old = _repo.getById(category.id);
    if (old != null && old.isIncome != category.isIncome && usageCount(category.id) > 0) {
      throw const CategoryException(
          'Bu kategoride işlem olduğu için türü değiştirilemez');
    }
    final saved = await _repo.save(category);
    state = _sorted([...state.where((c) => c.id != saved.id), saved]);
    return saved;
  }

  /// Kategoriyi siler. Kategori işlemlerde kullanılıyorsa [moveToId] ile
  /// aynı türden başka bir kategori verilmelidir; işlemler oraya taşınır.
  /// Taşınan işlem sayısını döndürür.
  Future<int> delete(String categoryId, {String? moveToId}) async {
    final blocker = _repo.deleteBlocker(categoryId);
    if (blocker != null) throw CategoryException(blocker);
    final category = _repo.getById(categoryId)!;

    final used = usageCount(categoryId);
    var moved = 0;
    if (used > 0) {
      if (moveToId == null) {
        throw CategoryException(
            'Bu kategoride $used işlem var. Silmeden önce işlemleri başka bir kategoriye taşıyın.');
      }
      final target = _repo.getById(moveToId);
      if (target == null || target.id == categoryId || target.isIncome != category.isIncome) {
        throw const CategoryException(
            'İşlemler aynı türden başka bir kategoriye taşınmalı');
      }
      moved = await ref
          .read(transactionsProvider.notifier)
          .reassignCategory(categoryId, moveToId);
    }

    await _repo.delete(categoryId);
    state = state.where((c) => c.id != categoryId).toList();
    return moved;
  }

  static List<Category> _sorted(List<Category> list) =>
      list..sort((a, b) => TurkishText.compare(a.name, b.name));
}

final categoriesProvider = NotifierProvider<CategoriesNotifier, List<Category>>(
  CategoriesNotifier.new,
);

/// Kimliğe göre kategori sözlüğü (listelerde hızlı erişim için).
final categoryMapProvider = Provider<Map<String, Category>>(
  (ref) => {for (final c in ref.watch(categoriesProvider)) c.id: c},
);
