import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// İşlem listelerinde Bugün / Dün / tarih başlıkları.
class DateGroups {
  DateGroups._();

  static String label(DateTime date, [DateTime? now]) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final day = DateUtils.dateOnly(date);
    if (day == today) return 'Bugün';
    if (day == today.subtract(const Duration(days: 1))) return 'Dün';
    final pattern = day.year == today.year ? 'd MMMM' : 'd MMMM y';
    return DateFormat(pattern, 'tr_TR').format(day);
  }

  /// Son ödeme / vade metni.
  static String due(DateTime date, [DateTime? now]) {
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final day = DateUtils.dateOnly(date);
    final days = day.difference(today).inDays;
    if (days == 0) return 'Bugün';
    if (days == 1) return 'Yarın';
    if (days == -1) return 'Dün';
    if (days > 1) return '$days gün sonra';
    return '${-days} gün gecikti';
  }
}
