import 'package:intl/intl.dart';

final _tryFormat = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 2,
);

final _percentFormat = NumberFormat('#0.#', 'tr_TR');

const _months = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

const _monthsShort = [
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];

/// Formats [amount] as Turkish Lira, for example `₺1.234,56`.
String formatTry(num amount) => _tryFormat.format(amount);

/// Formats a 0–100 percentage with a leading percent sign, for example `%12,5`.
String formatPercent(num percent) => '%${_percentFormat.format(percent)}';

/// Parses a Turkish or plain decimal amount. Returns null when the text is
/// empty, not a number, or not greater than zero.
double? parseAmount(String raw) {
  var text = raw
      .trim()
      .replaceAll('₺', '')
      .replaceAll(' ', '')
      .replaceAll('\u00A0', '');
  if (text.isEmpty) return null;
  if (text.startsWith('+')) text = text.substring(1);

  if (text.contains(',')) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  } else if (text.contains('.')) {
    final parts = text.split('.');
    final looksLikeThousands = parts.length > 1 &&
        parts.first.isNotEmpty &&
        parts.skip(1).every((part) => part.length == 3);
    if (looksLikeThousands) {
      text = parts.join();
    }
  }

  final value = double.tryParse(text);
  if (value == null || value <= 0 || value.isNaN || value.isInfinite) {
    return null;
  }
  return value;
}

String formatMonthYear(DateTime date) =>
    '${_months[date.month - 1]} ${date.year}';

String formatMonthShort(DateTime date) =>
    '${_monthsShort[date.month - 1]} ${date.year}';

String formatFullDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';
