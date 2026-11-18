import 'package:ev_butcem/utils/form_validators.dart';
import 'package:ev_butcem/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatMoney', () {
    test('formats Turkish lira with grouping and two decimals', () {
      expect(formatMoney(1234.56), '₺1.234,56');
      expect(formatMoney(0), '₺0,00');
      expect(formatMoney(1000000), '₺1.000.000,00');
      expect(formatMoney(10.5), '₺10,50');
      expect(formatMoney(-1250.5), '-₺1.250,50');
    });

    test('keeps Turkish separators for other currencies', () {
      expect(formatMoney(1234.56, currency: 'USD'), r'$1.234,56');
      expect(formatMoney(1234.56, currency: 'EUR'), '€1.234,56');
    });

    test('formats field input without a symbol', () {
      expect(formatAmountInput(1234.5), '1.234,50');
      expect(formatAmountInput(-10), '-10,00');
    });
  });

  group('parseAmount', () {
    test('accepts Turkish and plain decimal amounts', () {
      expect(parseAmount('1.234,56'), 1234.56);
      expect(parseAmount('1234,56'), 1234.56);
      expect(parseAmount('1234.56'), 1234.56);
      expect(parseAmount('1.234'), 1234);
      expect(parseAmount('12,50'), 12.5);
      expect(parseAmount('0,50'), 0.5);
      expect(parseAmount('0.50'), 0.5);
      expect(parseAmount('₺2.500,00'), 2500);
      expect(parseAmount('-1.250,50'), -1250.5);
      expect(parseAmount('  12,5 '), 12.5);
    });

    test('rejects empty and non-numeric text', () {
      expect(parseAmount(null), isNull);
      expect(parseAmount(''), isNull);
      expect(parseAmount('   '), isNull);
      expect(parseAmount('abc'), isNull);
    });
  });

  group('dates and iban', () {
    test('formats a Turkish short date', () {
      expect(formatTrDate(DateTime(2026, 11, 25)), '25 Kas 2026');
      expect(formatTrDate(DateTime(2026, 2, 28)), '28 Şub 2026');
    });

    test('normalizes and groups an IBAN', () {
      expect(normalizeIban(' tr33 0006 '), 'TR330006');
      expect(normalizeIban('   '), isNull);
      expect(
        formatIban('TR330006100519786457841326'),
        'TR33 0006 1005 1978 6457 8413 26',
      );
    });
  });

  group('validators', () {
    test('requires text and amounts', () {
      expect(
        validateRequiredText('  ', emptyMessage: 'Hesap adı gerekli'),
        'Hesap adı gerekli',
      );
      expect(
        validateRequiredText('Ziraat', emptyMessage: 'Hesap adı gerekli'),
        isNull,
      );
      expect(
        validateAmount(
          '',
          requiredField: true,
          emptyMessage: 'Bakiye gerekli',
          invalidMessage: 'Geçerli bir tutar girin',
          negativeMessage: 'Borç negatif olamaz',
        ),
        'Bakiye gerekli',
      );
      expect(
        validateAmount(
          'abc',
          requiredField: true,
          emptyMessage: 'Bakiye gerekli',
          invalidMessage: 'Geçerli bir tutar girin',
          negativeMessage: 'Borç negatif olamaz',
        ),
        'Geçerli bir tutar girin',
      );
      expect(
        validateAmount(
          '-5',
          requiredField: true,
          emptyMessage: 'Güncel borç gerekli',
          invalidMessage: 'Geçerli bir tutar girin',
          negativeMessage: 'Borç negatif olamaz',
        ),
        'Borç negatif olamaz',
      );
      expect(
        validateAmount(
          '1.234,56',
          requiredField: true,
          emptyMessage: 'Bakiye gerekli',
          invalidMessage: 'Geçerli bir tutar girin',
          negativeMessage: 'Borç negatif olamaz',
        ),
        isNull,
      );
      expect(
        validateAmount(
          '',
          requiredField: false,
          emptyMessage: 'Tutar gerekli',
          invalidMessage: 'Geçerli bir tutar girin',
          negativeMessage: 'Tutar negatif olamaz',
        ),
        isNull,
      );
    });

    test('accepts days from 1 to 31 only', () {
      expect(
        validateDay('', emptyMessage: 'Son ödeme günü gerekli'),
        'Son ödeme günü gerekli',
      );
      expect(
        validateDay('0', emptyMessage: 'Gün gerekli'),
        'Gün 1 ile 31 arasında olmalı',
      );
      expect(
        validateDay('32', emptyMessage: 'Gün gerekli'),
        'Gün 1 ile 31 arasında olmalı',
      );
      expect(validateDay('1', emptyMessage: 'Gün gerekli'), isNull);
      expect(validateDay('31', emptyMessage: 'Gün gerekli'), isNull);
    });

    test('checks the last four digits and TR IBAN length', () {
      expect(validateLastFour(''), isNull);
      expect(validateLastFour('4242'), isNull);
      expect(validateLastFour('42'), 'Son 4 hane 4 rakam olmalı');
      expect(validateIban(''), isNull);
      expect(validateIban('TR330006100519786457841326'), isNull);
      expect(
        validateIban('TR330006100519786457'),
        'TR IBAN 26 karakter olmalı',
      );
      expect(validateIban('DE89-'), 'IBAN yalnızca harf ve rakam içerebilir');
    });
  });
}
