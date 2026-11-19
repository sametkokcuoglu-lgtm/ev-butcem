import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  static String money(double amount) => currency.format(amount);

  /// Hareket satırı. Giderlerde tipografik eksi (U+2212) kullanılır.
  static String activityAmount(double amount, {required bool income}) {
    final text = currency.format(amount.abs());
    return income ? '+$text' : '\u2212$text';
  }

  static String date(DateTime date) => DateFormat('d MMMM y', 'tr_TR').format(date);

  static String dayMonth(DateTime date) => DateFormat('d MMMM', 'tr_TR').format(date);

  static String monthYear(DateTime date) => DateFormat('MMMM y', 'tr_TR').format(date);

  static String shortMonth(DateTime date) =>
      DateFormat('MMM', 'tr_TR').format(date).replaceAll('.', '');

  /// Grafik ekseni için kısa tutar (ör. 12,5 B).
  static String compact(double amount) {
    final abs = amount.abs();
    if (abs >= 1000000) {
      final value = abs / 1000000;
      return '${_trim(value)} Mn';
    }
    if (abs >= 1000) {
      final value = abs / 1000;
      return '${_trim(value)} B';
    }
    return abs.toStringAsFixed(0);
  }

  static String _trim(double value) {
    final text = value >= 10 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return text.endsWith(',0') || text.endsWith('.0') ? text.substring(0, text.length - 2) : text.replaceAll('.', ',');
  }
}
