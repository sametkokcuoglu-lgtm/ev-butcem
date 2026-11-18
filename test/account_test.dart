import 'package:ev_butcem/models/account.dart';
import 'package:ev_butcem/models/credit_card.dart';
import 'package:ev_butcem/utils/wallet_totals.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_bytes.dart';

void main() {
  group('defaults', () {
    test('uses TRY, vadesiz and a zero balance when omitted', () {
      final account = Account(name: 'Maaş', bankName: 'Ziraat');
      expect(account.currency, 'TRY');
      expect(account.accountType, 'vadesiz');
      expect(account.type, AccountType.vadesiz);
      expect(account.balance, 0);
      expect(account.iban, isNull);
      expect(account.overdraftLimit, isNull);
      expect(account.hasOverdraft, isFalse);
      expect(account.isActive, isTrue);
    });

    test('maps unknown type names back to vadesiz', () {
      expect(AccountType.fromName(null), AccountType.vadesiz);
      expect(AccountType.fromName(''), AccountType.vadesiz);
      expect(AccountType.fromName('maas'), AccountType.maas);
      expect(AccountType.fromName('maas').label, 'Maaş');
    });
  });

  group('totals', () {
    test('sums balances per currency and keeps TRY first', () {
      final accounts = [
        Account(name: 'Dolar', bankName: 'A', balance: 50, currency: 'USD'),
        Account(name: 'Birikim', bankName: 'A', balance: 1000, currency: 'try'),
        Account(
          name: 'Vadesiz',
          bankName: 'A',
          balance: 250.5,
          currency: 'TRY',
        ),
      ];
      final totals = WalletTotals.balancesByCurrency(accounts);
      expect(totals['TRY'], 1250.5);
      expect(totals['USD'], 50);
      final sorted = WalletTotals.sortedCurrencyTotals(totals);
      expect(sorted.map((entry) => entry.key).toList(), ['TRY', 'USD']);
    });

    test(
      'sums card debt and available limit, including a negative remainder',
      () {
        final cards = [
          CreditCard(
            name: 'A',
            bankName: 'B',
            limit: 10000,
            currentDebt: 4000,
            statementDay: 1,
            dueDay: 10,
          ),
          CreditCard(
            name: 'C',
            bankName: 'B',
            limit: 1000,
            currentDebt: 1500,
            statementDay: 1,
            dueDay: 10,
          ),
        ];
        expect(WalletTotals.totalDebt(cards), 5500);
        expect(WalletTotals.totalAvailableLimit(cards), 5500);
      },
    );
  });

  group('hive compatibility', () {
    test('reads accounts saved before type, IBAN, icon and KMH existed', () {
      final account = readHive(AccountAdapter(), (writer) {
        writer
          ..writeByte(8)
          ..writeByte(0)
          ..write('legacy-account')
          ..writeByte(1)
          ..write('Ziraat Vadesiz')
          ..writeByte(2)
          ..write('Ziraat Bankası')
          ..writeByte(3)
          ..write(1500.5)
          ..writeByte(4)
          ..write('TRY')
          ..writeByte(5)
          ..write('#2563EB')
          ..writeByte(6)
          ..write(true)
          ..writeByte(7)
          ..write(DateTime(2024, 5, 1));
      });

      expect(account.id, 'legacy-account');
      expect(account.name, 'Ziraat Vadesiz');
      expect(account.bankName, 'Ziraat Bankası');
      expect(account.balance, 1500.5);
      expect(account.currency, 'TRY');
      expect(account.color, '#2563EB');
      expect(account.isActive, isTrue);
      expect(account.createdAt.year, 2024);
      expect(account.accountType, 'vadesiz');
      expect(account.type, AccountType.vadesiz);
      expect(account.iban, isNull);
      expect(account.icon, isNull);
      expect(account.overdraftLimit, isNull);
    });

    test('round-trips the new account fields', () {
      final original = Account(
        id: 'new-account',
        name: 'Birikim',
        bankName: 'İş Bankası',
        balance: 8000,
        currency: 'EUR',
        color: '#16A34A',
        createdAt: DateTime(2025, 3, 4),
        accountType: AccountType.birikim.name,
        iban: 'TR330006100519786457841326',
        icon: 'safe',
        overdraftLimit: 2500,
      );

      final loaded = readHive(AccountAdapter(), (writer) {
        AccountAdapter().write(writer, original);
      });

      expect(loaded.accountType, 'birikim');
      expect(loaded.type, AccountType.birikim);
      expect(loaded.iban, original.iban);
      expect(loaded.icon, 'safe');
      expect(loaded.overdraftLimit, 2500);
      expect(loaded.hasOverdraft, isTrue);
      expect(loaded.availableWithOverdraft, 10500);
      expect(loaded.currency, 'EUR');
      expect(loaded.createdAt.day, 4);
    });
  });
}
