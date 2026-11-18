class CurrencyOption {
  const CurrencyOption(this.code, this.label);

  final String code;
  final String label;
}

const currencyOptions = <CurrencyOption>[
  CurrencyOption('TRY', 'TRY (₺)'),
  CurrencyOption('USD', 'USD (\$)'),
  CurrencyOption('EUR', 'EUR (€)'),
  CurrencyOption('GBP', 'GBP (£)'),
];

const _monthNames = <String>[
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

String currencySymbol(String currency) {
  switch (currency.toUpperCase()) {
    case 'USD':
      return r'$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'TRY':
      return '₺';
    default:
      return currency.toUpperCase();
  }
}

/// Turkish grouping with a currency symbol, for example `₺1.234,56`.
String formatMoney(double amount, {String currency = 'TRY'}) {
  final negative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts[0];
  final decimals = parts[1];
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    groups.add(digits.substring(start, end));
  }
  final whole = groups.reversed.join('.');
  final symbol = currencySymbol(currency);
  final prefix = symbol.length > 1 ? '$symbol ' : symbol;
  final body = '$prefix$whole,$decimals';
  return negative ? '-$body' : body;
}

/// Amount text for form fields, without a currency symbol (`1.234,56`).
String formatAmountInput(double amount) {
  final formatted = formatMoney(amount);
  if (formatted.startsWith('-₺')) {
    return '-${formatted.substring(2)}';
  }
  if (formatted.startsWith('₺')) {
    return formatted.substring(1);
  }
  return formatted;
}

/// Parses Turkish (`1.234,56`) and plain (`1234.56`) amounts.
double? parseAmount(String? raw) {
  if (raw == null) return null;
  var text = raw.trim().replaceAll('\u00A0', '').replaceAll(' ', '');
  if (text.isEmpty) return null;
  for (final symbol in ['₺', '€', '£', r'$', '\$']) {
    text = text.replaceAll(symbol, '');
  }
  if (text.isEmpty) return null;

  final negative = text.startsWith('-');
  if (negative || text.startsWith('+')) {
    text = text.substring(1);
  }
  if (text.isEmpty) return null;

  final hasComma = text.contains(',');
  final hasDot = text.contains('.');
  if (hasComma && hasDot) {
    if (text.lastIndexOf(',') > text.lastIndexOf('.')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else {
      text = text.replaceAll(',', '');
    }
  } else if (hasComma) {
    text = text.replaceAll(',', '.');
  } else if (hasDot && RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(text)) {
    final whole = text.split('.').first;
    if (whole != '0') {
      text = text.replaceAll('.', '');
    }
  }

  final value = double.tryParse(text);
  if (value == null || value.isNaN || value.isInfinite) return null;
  return negative ? -value : value;
}

String formatTrDate(DateTime date) =>
    '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

String? normalizeIban(String? raw) {
  if (raw == null) return null;
  final compact = raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  if (compact.isEmpty) return null;
  return compact;
}

String formatIban(String iban) {
  final compact = iban.replaceAll(' ', '');
  final buffer = StringBuffer();
  for (var i = 0; i < compact.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(compact[i]);
  }
  return buffer.toString();
}
