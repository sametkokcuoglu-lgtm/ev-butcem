import 'package:flutter/material.dart';
import '../models/category.dart';

class DefaultData {
  static List<Category> get defaultCategories => [
        Category(
            name: 'Market',
            icon: '🛒',
            colorValue: Colors.green.value,
            isIncome: false,
            isSystem: true),
        Category(
            name: 'Kira',
            icon: '🏠',
            colorValue: Colors.indigo.value,
            isIncome: false,
            isSystem: true),
        Category(
            name: 'Faturalar',
            icon: '💡',
            colorValue: Colors.amber.value,
            isIncome: false,
            isSystem: true),
        Category(
            name: 'Ulaşım',
            icon: '🚗',
            colorValue: Colors.blue.value,
            isIncome: false,
            isSystem: true),
        Category(
            name: 'Yemek',
            icon: '🍽️',
            colorValue: Colors.orange.value,
            isIncome: false,
            isSystem: true),
        Category(
            name: 'Sağlık',
            icon: '🏥',
            colorValue: Colors.red.value,
            isIncome: false,
            isSystem: true),
        Category(
            name: 'Maaş',
            icon: '💰',
            colorValue: Colors.green.value,
            isIncome: true,
            isSystem: true),
        Category(
            name: 'Ek Gelir',
            icon: '📈',
            colorValue: Colors.lightGreen.value,
            isIncome: true,
            isSystem: true),
      ];
}
