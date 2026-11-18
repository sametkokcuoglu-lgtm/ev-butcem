import 'package:hive/hive.dart';

import '../models/category.dart';
import '../utils/default_data.dart';
import '../utils/text_utils.dart';

/// Kategori kurallarından biri ihlal edildiğinde fırlatılır.
/// [message] kullanıcıya doğrudan gösterilebilecek Türkçe metindir.
class CategoryException implements Exception {
  final String message;
  const CategoryException(this.message);

  @override
  String toString() => message;
}

/// Kategorilerin Hive kutusuna yazılıp okunduğu katman ve iş kuralları.
class CategoryRepository {
  static const String boxName = 'categories';
  static const int maxNameLength = 30;

  final Box<Category> _box;

  CategoryRepository(this._box);

  /// Kayıtlı kategoriler, id'ye göre tekil.
  List<Category> getAll() {
    final byId = <String, Category>{};
    for (final c in _box.values) {
      byId[c.id] = c;
    }
    return byId.values.toList();
  }

  Category? getById(String id) => _box.get(id);

  /// Kutu boşsa varsayılan kategorileri (sabit id'lerle) ekler.
  Future<void> seedDefaultsIfEmpty() async {
    if (_box.isNotEmpty) return;
    await _box.putAll({for (final c in DefaultData.defaultCategories) c.id: c});
  }

  /// Ad için hata mesajı döndürür; geçerliyse `null`.
  ///
  /// Aynı türde (gelir/gider) aynı ad, büyük/küçük harf ve baştaki/sondaki
  /// boşluklar Türkçe kurallarıyla yok sayılarak karşılaştırılır.
  String? validateName(String name, {required bool isIncome, String? excludeId}) {
    final cleaned = TurkishText.clean(name);
    if (cleaned.isEmpty) return 'Kategori adı girin';
    if (cleaned.length > maxNameLength) {
      return 'Kategori adı en fazla $maxNameLength karakter olabilir';
    }
    final key = TurkishText.key(cleaned);
    final exists = getAll().any((c) =>
        c.id != excludeId && c.isIncome == isIncome && TurkishText.key(c.name) == key);
    if (exists) {
      return '"$cleaned" adında bir ${isIncome ? 'gelir' : 'gider'} kategorisi zaten var';
    }
    return null;
  }

  /// Yeni kategori ekler veya mevcut olanı günceller (anahtar: `id`).
  /// Ad temizlenerek kaydedilir.
  Future<Category> save(Category category) async {
    final error = validateName(category.name,
        isIncome: category.isIncome, excludeId: category.id);
    if (error != null) throw CategoryException(error);
    if (category.icon.trim().isEmpty) throw const CategoryException('Bir simge seçin');

    final old = _box.get(category.id);
    if (old != null && old.isIncome != category.isIncome && _countOfType(old.isIncome) <= 1) {
      throw CategoryException(
          'En az bir ${old.isIncome ? 'gelir' : 'gider'} kategorisi kalmalı');
    }

    final cleaned = Category(
      id: category.id,
      name: TurkishText.clean(category.name),
      icon: category.icon.trim(),
      colorValue: category.colorValue,
      isIncome: category.isIncome,
      isSystem: old?.isSystem ?? category.isSystem,
    );
    await _box.put(cleaned.id, cleaned);
    return cleaned;
  }

  /// Silmeye engel bir durum varsa mesajını döndürür; yoksa `null`.
  /// Her türden (gelir/gider) en az bir kategori kalmalıdır.
  String? deleteBlocker(String id) {
    final c = _box.get(id);
    if (c == null) return 'Kategori bulunamadı';
    if (_countOfType(c.isIncome) <= 1) {
      return 'En az bir ${c.isIncome ? 'gelir' : 'gider'} kategorisi kalmalı';
    }
    return null;
  }

  Future<void> delete(String id) async {
    final blocker = deleteBlocker(id);
    if (blocker != null) throw CategoryException(blocker);
    await _box.delete(id);
  }

  int _countOfType(bool isIncome) => getAll().where((c) => c.isIncome == isIncome).length;
}
