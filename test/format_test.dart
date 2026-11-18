import 'package:ev_butcem/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatTry uses Turkish Lira grouping', () {
    expect(formatTry(1234.56), '₺1.234,56');
    expect(formatTry(0), '₺0,00');
    expect(formatTry(250.5), '₺250,50');
    expect(formatTry(1000000.1), '₺1.000.000,10');
    expect(formatTry(-1234.56), '-₺1.234,56');
  });

  test('formatPercent uses a Turkish decimal comma', () {
    expect(formatPercent(33.333), '%33,3');
    expect(formatPercent(12.5), '%12,5');
    expect(formatPercent(50), '%50');
    expect(formatPercent(100), '%100');
    expect(formatPercent(0), '%0');
  });

  test('formatMonthYear uses Turkish month names', () {
    expect(formatMonthYear(DateTime(2026, 11)), 'Kasım 2026');
    expect(formatMonthShort(DateTime(2026, 1)), 'Oca 2026');
    expect(formatFullDate(DateTime(2026, 11, 18)), '18 Kasım 2026');
  });

  test('parseAmount accepts Turkish and plain decimals', () {
    expect(parseAmount('1.234,56'), 1234.56);
    expect(parseAmount('1234,56'), 1234.56);
    expect(parseAmount('1234.56'), 1234.56);
    expect(parseAmount('1.234'), 1234);
    expect(parseAmount('1.234.567'), 1234567);
    expect(parseAmount('12,50'), 12.5);
    expect(parseAmount('₺ 1.234,56'), 1234.56);
    expect(parseAmount('250'), 250);
    expect(parseAmount(''), isNull);
    expect(parseAmount('0'), isNull);
    expect(parseAmount('0,00'), isNull);
    expect(parseAmount('-5'), isNull);
    expect(parseAmount('abc'), isNull);
  });
}
