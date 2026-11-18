import 'package:flutter/material.dart';
import '../models/category.dart';

class DefaultData {
  DefaultData._();

  /// Varsayılan kategoriler.
  ///
  /// Kimlikler sabittir (`default_...`); her çağrıda yeni rastgele id
  /// üretilmez. Böylece dropdown değerleri ve işlemlerin `categoryId`
  /// bağlantıları kararlı kalır. Daha önce rastgele id ile kaydedilmiş
  /// kategoriler olduğu gibi korunur; tohumlama yalnızca kutu boşsa yapılır.
  static List<Category> get defaultCategories => [
        Category(id: 'default_market', name: 'Market', icon: '🛒', colorValue: Colors.green.toARGB32(), isIncome: false, isSystem: true),
        Category(id: 'default_kira', name: 'Kira', icon: '🏠', colorValue: Colors.indigo.toARGB32(), isIncome: false, isSystem: true),
        Category(id: 'default_faturalar', name: 'Faturalar', icon: '💡', colorValue: Colors.amber.toARGB32(), isIncome: false, isSystem: true),
        Category(id: 'default_ulasim', name: 'Ulaşım', icon: '🚗', colorValue: Colors.blue.toARGB32(), isIncome: false, isSystem: true),
        Category(id: 'default_yemek', name: 'Yemek', icon: '🍽️', colorValue: Colors.orange.toARGB32(), isIncome: false, isSystem: true),
        Category(id: 'default_saglik', name: 'Sağlık', icon: '🏥', colorValue: Colors.red.toARGB32(), isIncome: false, isSystem: true),
        Category(id: 'default_egitim', name: 'Eğitim', icon: '🎓', colorValue: Colors.purple.toARGB32(), isIncome: false, isSystem: true),
        Category(id: 'default_maas', name: 'Maaş', icon: '💰', colorValue: Colors.green.toARGB32(), isIncome: true, isSystem: true),
        Category(id: 'default_ek_gelir', name: 'Ek Gelir', icon: '📈', colorValue: Colors.lightGreen.toARGB32(), isIncome: true, isSystem: true),
      ];
}
