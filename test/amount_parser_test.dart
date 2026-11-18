import 'package:ev_butcem/utils/amount_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AmountParser.parse', () {
    test('Türkçe biçim', () {
      expect(AmountParser.parse('1.250,50'), 1250.50);
      expect(AmountParser.parse('1250,50'), 1250.50);
      expect(AmountParser.parse('12.345.678,9'), 12345678.9);
      expect(AmountParser.parse('0,75'), 0.75);
      expect(AmountParser.parse('1.250'), 1250);
      expect(AmountParser.parse('1.250.000'), 1250000);
    });

    test('Nokta ondalıklı biçim', () {
      expect(AmountParser.parse('1250.50'), 1250.50);
      expect(AmountParser.parse('1,250.50'), 1250.50);
      expect(AmountParser.parse('0.25'), 0.25);
      expect(AmountParser.parse('0.250'), isNull); // en fazla 2 ondalık
      expect(AmountParser.parse('99.9'), 99.9);
    });

    test('Para birimi ve boşluklar temizlenir', () {
      expect(AmountParser.parse(' 850 ₺ '), 850);
      expect(AmountParser.parse('1 250,50 TL'), 1250.50);
      expect(AmountParser.parse('850'), 850);
    });

    test('Geçersiz girişler null döner', () {
      for (final input in [null, '', 'abc', '-5', '1,2,3,4', '12.34.5', '1.250,50,1', '1,', '12,345', '1.25,5', '10,999']) {
        expect(AmountParser.parse(input), isNull, reason: '$input');
      }
    });
  });

  test('toInput Türkçe metin üretir ve geri ayrıştırılabilir', () {
    expect(AmountParser.toInput(1250.5), '1250,5');
    expect(AmountParser.toInput(850), '850');
    expect(AmountParser.toInput(0.75), '0,75');
    for (final v in [1250.5, 850.0, 0.75, 1234567.89]) {
      expect(AmountParser.parse(AmountParser.toInput(v)), v);
    }
  });
}
