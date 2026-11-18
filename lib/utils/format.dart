import 'package:intl/intl.dart';

import 'dates.dart';

final NumberFormat tryCurrencyFormat = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 0,
);

String formatTry(num amount) => tryCurrencyFormat.format(amount);

String formatTrDate(DateTime date) =>
    DateFormat('d MMMM y', 'tr_TR').format(date);

String formatTrMonth(DateTime date) => DateFormat.yMMMM('tr_TR').format(date);

String relativeDayLabel(DateTime date, DateTime now) {
  final days = dateOnly(date).difference(dateOnly(now)).inDays;
  if (days == 0) return 'Bugün';
  if (days == 1) return 'Yarın';
  if (days == -1) return 'Dün';
  if (days < 0) return '${-days} gün gecikti';
  return '$days gün sonra';
}

/// Accepts `1250`, `1250,50`, `1.250,50` and a trailing `₺`.
double? parseTryInput(String raw) {
  var value =
      raw.trim().replaceAll(' ', '').replaceAll('₺', '').replaceAll('TL', '');
  if (value.isEmpty) return null;

  final hasComma = value.contains(',');
  final hasDot = value.contains('.');
  if (hasComma && hasDot) {
    value = value.replaceAll('.', '').replaceAll(',', '.');
  } else if (hasComma) {
    value = value.replaceAll(',', '.');
  } else if (hasDot && RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(value)) {
    value = value.replaceAll('.', '');
  }
  return double.tryParse(value);
}

String amountToField(double amount) {
  if (amount == amount.roundToDouble()) return amount.toStringAsFixed(0);
  return amount.toStringAsFixed(2).replaceAll('.', ',');
}
