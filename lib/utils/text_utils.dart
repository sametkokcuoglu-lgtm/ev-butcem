/// Türkçe'ye duyarlı metin yardımcıları.
class TurkishText {
  TurkishText._();

  /// Baştaki/sondaki boşlukları atar, aradaki çoklu boşlukları teke indirir.
  static String clean(String input) =>
      input.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Türkçe kurallarıyla küçük harfe çevirir (I → ı, İ → i).
  static String toLower(String input) =>
      input.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

  /// Karşılaştırma anahtarı: temizlenmiş ve Türkçe küçük harfli metin.
  /// "  MARKET " ile "market", "IŞIK" ile "ışık" aynı anahtarı verir.
  static String key(String input) => toLower(clean(input));

  static const String _alphabet = 'abcçdefgğhıijklmnoöprsştuüvyz';

  /// Türk alfabesi sırasına göre karşılaştırma (ç, ğ, ı, ö, ş, ü doğru yerde).
  static int compare(String a, String b) {
    final x = key(a);
    final y = key(b);
    final n = x.length < y.length ? x.length : y.length;
    for (var i = 0; i < n; i++) {
      final cx = x[i];
      final cy = y[i];
      if (cx == cy) continue;
      final ix = _alphabet.indexOf(cx);
      final iy = _alphabet.indexOf(cy);
      if (ix >= 0 && iy >= 0) return ix.compareTo(iy);
      if (ix >= 0) return 1; // Harf olmayanlar (rakam vb.) önce gelir.
      if (iy >= 0) return -1;
      return cx.compareTo(cy);
    }
    return x.length.compareTo(y.length);
  }
}
