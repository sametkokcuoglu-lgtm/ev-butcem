import 'money.dart';

String? validateRequiredText(String? value, {required String emptyMessage}) {
  if (value == null || value.trim().isEmpty) return emptyMessage;
  return null;
}

String? validateAmount(
  String? value, {
  required bool requiredField,
  required String emptyMessage,
  required String invalidMessage,
  required String negativeMessage,
  bool allowNegative = false,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return requiredField ? emptyMessage : null;
  final amount = parseAmount(text);
  if (amount == null) return invalidMessage;
  if (!allowNegative && amount < 0) return negativeMessage;
  return null;
}

String? validateDay(String? value, {required String emptyMessage}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return emptyMessage;
  final day = int.tryParse(text);
  if (day == null || day < 1 || day > 31) {
    return 'Gün 1 ile 31 arasında olmalı';
  }
  return null;
}

String? validateLastFour(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  if (!RegExp(r'^\d{4}$').hasMatch(text)) {
    return 'Son 4 hane 4 rakam olmalı';
  }
  return null;
}

String? validateIban(String? value) {
  final compact = normalizeIban(value);
  if (compact == null) return null;
  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(compact)) {
    return 'IBAN yalnızca harf ve rakam içerebilir';
  }
  if (compact.length < 15 || compact.length > 34) {
    return 'IBAN uzunluğu geçersiz';
  }
  if (compact.startsWith('TR') && compact.length != 26) {
    return 'TR IBAN 26 karakter olmalı';
  }
  return null;
}
