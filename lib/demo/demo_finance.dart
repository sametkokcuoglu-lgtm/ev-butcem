import 'package:flutter/material.dart';

import '../models/category.dart';
import '../utils/text_utils.dart';

/// Henüz Hive modeli olmayan fatura, ekstre ve bütçe limitleri.
///
/// Gerçek kayıtlar bağlanınca bu dosyadaki listeler ilgili repository
/// ile değiştirilmeli. İşlem ve kategori verisi burada üretilmez.
class DemoBill {
  final String id;
  final String title;
  final String provider;
  final double amount;
  final DateTime dueDate;
  final bool paid;
  final String icon;

  const DemoBill({
    required this.id,
    required this.title,
    required this.provider,
    required this.amount,
    required this.dueDate,
    required this.paid,
    required this.icon,
  });

  bool get overdue {
    if (paid) return false;
    final today = DateUtils.dateOnly(DateTime.now());
    return DateUtils.dateOnly(dueDate).isBefore(today);
  }
}

class DemoStatement {
  final String id;
  final String bankName;
  final String cardName;
  final String last4;
  final double periodDebt;
  final double minimumPayment;
  final double limit;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime dueDate;
  final List<int> gradient;

  const DemoStatement({
    required this.id,
    required this.bankName,
    required this.cardName,
    required this.last4,
    required this.periodDebt,
    required this.minimumPayment,
    required this.limit,
    required this.periodStart,
    required this.periodEnd,
    required this.dueDate,
    required this.gradient,
  });

  double get usage => limit <= 0 ? 0 : (periodDebt / limit).clamp(0, 1);
}

class DemoFinance {
  DemoFinance._();

  /// Örnek aylık kategori limitleri. Anahtar, kategori adının Türkçe
  /// karşılaştırma biçimidir (`TurkishText.key`).
  static const Map<String, double> budgetLimitsByName = {
    'market': 6500,
    'kira': 18000,
    'faturalar': 2800,
    'ulaşım': 2200,
    'yemek': 3500,
    'sağlık': 1500,
    'eğitim': 2000,
  };

  static double? budgetLimitFor(Category category) =>
      budgetLimitsByName[TurkishText.key(category.name)];

  static List<DemoBill> bills([DateTime? now]) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    return [
      DemoBill(
        id: 'demo_internet',
        title: 'İnternet',
        provider: 'Türk Telekom',
        amount: 449.90,
        dueDate: today.add(const Duration(days: 1)),
        paid: false,
        icon: '🌐',
      ),
      DemoBill(
        id: 'demo_elektrik',
        title: 'Elektrik',
        provider: 'BEDAŞ',
        amount: 875.40,
        dueDate: today.add(const Duration(days: 3)),
        paid: false,
        icon: '💡',
      ),
      DemoBill(
        id: 'demo_dogalgaz',
        title: 'Doğalgaz',
        provider: 'İGDAŞ',
        amount: 640,
        dueDate: today.add(const Duration(days: 6)),
        paid: false,
        icon: '🔥',
      ),
      DemoBill(
        id: 'demo_su',
        title: 'Su',
        provider: 'İSKİ',
        amount: 210.75,
        dueDate: today.subtract(const Duration(days: 2)),
        paid: false,
        icon: '💧',
      ),
      DemoBill(
        id: 'demo_kira',
        title: 'Kira',
        provider: 'Ev sahibi',
        amount: 18000,
        dueDate: today.add(const Duration(days: 12)),
        paid: false,
        icon: '🏠',
      ),
      DemoBill(
        id: 'demo_telefon',
        title: 'Telefon',
        provider: 'Turkcell',
        amount: 329,
        dueDate: today.subtract(const Duration(days: 8)),
        paid: true,
        icon: '📱',
      ),
      DemoBill(
        id: 'demo_aidat',
        title: 'Site aidatı',
        provider: 'Yönetim',
        amount: 750,
        dueDate: today.subtract(const Duration(days: 4)),
        paid: true,
        icon: '🏢',
      ),
    ];
  }

  static List<DemoStatement> statements([DateTime? now]) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final start = DateTime(today.year, today.month - 1, 1);
    final end = DateTime(today.year, today.month, 0);
    return [
      DemoStatement(
        id: 'demo_card_bonus',
        bankName: 'Garanti BBVA',
        cardName: 'Bonus',
        last4: '9088',
        periodDebt: 6230.50,
        minimumPayment: 935,
        limit: 25000,
        periodStart: start,
        periodEnd: end,
        dueDate: today.add(const Duration(days: 3)),
        gradient: const [0xFF14532D, 0xFF16A34A],
      ),
      DemoStatement(
        id: 'demo_card_world',
        bankName: 'Yapı Kredi',
        cardName: 'World',
        last4: '4412',
        periodDebt: 12450,
        minimumPayment: 1867.50,
        limit: 40000,
        periodStart: start,
        periodEnd: end,
        dueDate: today.add(const Duration(days: 8)),
        gradient: const [0xFF1E1B4B, 0xFF4F46E5],
      ),
      DemoStatement(
        id: 'demo_card_maximum',
        bankName: 'İş Bankası',
        cardName: 'Maximum',
        last4: '3321',
        periodDebt: 0,
        minimumPayment: 0,
        limit: 15000,
        periodStart: start,
        periodEnd: end,
        dueDate: today.add(const Duration(days: 15)),
        gradient: const [0xFF0F172A, 0xFF334155],
      ),
    ];
  }
}
