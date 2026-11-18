import 'package:flutter/material.dart';
import '../models/category.dart';

class DefaultData {
  static List<Category> get defaultCategories => [
        Category(
            name: 'Market',
            icon: '🛒',
            colorValue: Colors.green.toARGB32(),
            isIncome: false,
            isSystem: true),
        Category(
            name: 'Kira',
            icon: '🏠',
            colorValue: Colors.indigo.toARGB32(),
            isIncome: false,
            isSystem: true),
        Category(
            name: 'Faturalar',
            icon: '💡',
            colorValue: Colors.amber.toARGB32(),
            isIncome: false,
            isSystem: true),
        Category(
            name: 'Ulaşım',
            icon: '🚗',
            colorValue: Colors.blue.toARGB32(),
            isIncome: false,
            isSystem: true),
        Category(
            name: 'Yemek',
            icon: '🍽️',
            colorValue: Colors.orange.toARGB32(),
            isIncome: false,
            isSystem: true),
        Category(
            name: 'Sağlık',
            icon: '🏥',
            colorValue: Colors.red.toARGB32(),
            isIncome: false,
            isSystem: true),
        Category(
            name: 'Maaş',
            icon: '💰',
            colorValue: Colors.green.toARGB32(),
            isIncome: true,
            isSystem: true),
        Category(
            name: 'Ek Gelir',
            icon: '📈',
            colorValue: Colors.lightGreen.toARGB32(),
            isIncome: true,
            isSystem: true),
      ];
}
