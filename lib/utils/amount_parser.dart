/// Tutar girişlerini ayrıştırır.
///
/// Hem Türkçe biçimi (`1.250,50`) hem nokta ondalıklı biçimi (`1250.50`)
/// kabul eder. Geçersiz girişte `null` döner.
class AmountParser {
  AmountParser._();

  static final RegExp _allowed = RegExp(r'^\d[\d.,]*$');

  static double? parse(String? input) {
    if (input == null) return null;
    var text = input
        .replaceAll('₺', '')
        .replaceAll(RegExp(r'\bTL\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s'), '');
    if (text.isEmpty || !_allowed.hasMatch(text)) return null;
    if (text.endsWith('.') || text.endsWith(',')) return null;

    final lastDot = text.lastIndexOf('.');
    final lastComma = text.lastIndexOf(',');
    String intPart;
    String decPart = '';

    if (lastDot >= 0 && lastComma >= 0) {
      // İkisi de varsa en sağdaki ondalık ayırıcıdır.
      final decSep = lastComma > lastDot ? ',' : '.';
      final thousandSep = decSep == ',' ? '.' : ',';
      final idx = text.lastIndexOf(decSep);
      intPart = text.substring(0, idx);
      decPart = text.substring(idx + 1);
      if (intPart.contains(decSep)) return null;
      if (!_validGrouping(intPart, thousandSep)) return null;
      intPart = intPart.replaceAll(thousandSep, '');
    } else if (lastComma >= 0 || lastDot >= 0) {
      final sep = lastComma >= 0 ? ',' : '.';
      final parts = text.split(sep);
      if (parts.length > 2) {
        // 1.250.000 veya 1,250,000 → binlik ayırıcı
        if (!_validGrouping(text, sep)) return null;
        intPart = text.replaceAll(sep, '');
      } else if (sep == '.' &&
          parts[1].length == 3 &&
          parts[0] != '0' &&
          parts[0].length <= 3) {
        // Türkçe kullanımda "1.250" bin iki yüz elli demektir.
        intPart = parts[0] + parts[1];
      } else {
        intPart = parts[0];
        decPart = parts[1];
      }
    } else {
      intPart = text;
    }

    if (intPart.isEmpty || decPart.length > 2) return null;
    final value = double.tryParse(decPart.isEmpty ? intPart : '$intPart.$decPart');
    if (value == null || value.isNaN || value.isInfinite) return null;
    return value;
  }

  static bool _validGrouping(String text, String sep) {
    final groups = text.split(sep);
    if (groups.first.isEmpty || groups.first.length > 3) return false;
    return groups.skip(1).every((g) => g.length == 3);
  }

  /// Düzenleme formunda gösterilecek Türkçe metin (örn. `1250,5`).
  static String toInput(double amount) {
    final fixed = amount.toStringAsFixed(2);
    final trimmed = fixed.endsWith('.00')
        ? fixed.substring(0, fixed.length - 3)
        : fixed.endsWith('0')
            ? fixed.substring(0, fixed.length - 1)
            : fixed;
    return trimmed.replaceAll('.', ',');
  }
}
