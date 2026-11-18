import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat currency =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  static String money(double amount) => currency.format(amount);

  static String date(DateTime date) => DateFormat('d MMMM y', 'tr_TR').format(date);

  static String monthYear(DateTime date) => DateFormat('MMMM y', 'tr_TR').format(date);
}
