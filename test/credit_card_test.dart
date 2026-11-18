import 'package:ev_butcem/models/credit_card.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_bytes.dart';

void main() {
  CreditCard sample({
    int dueDay = 15,
    int statementDay = 1,
    double limit = 10000,
    double currentDebt = 2500,
  }) {
    return CreditCard(
      id: 'card-1',
      name: 'Bonus',
      bankName: 'Garanti',
      limit: limit,
      currentDebt: currentDebt,
      statementDay: statementDay,
      dueDay: dueDay,
      createdAt: DateTime(2024, 1, 1),
    );
  }

  group('available limit', () {
    test('is limit minus current debt', () {
      expect(sample(limit: 10000, currentDebt: 2500).availableLimit, 7500);
      expect(sample(limit: 10000, currentDebt: 0).availableLimit, 10000);
      expect(sample(limit: 1000, currentDebt: 1500).availableLimit, -500);
    });
  });

  group('usage percentage', () {
    test('is the share of the limit currently used', () {
      expect(sample(limit: 10000, currentDebt: 2500).usagePercentage, 25);
      expect(sample(limit: 10000, currentDebt: 0).usagePercentage, 0);
    });

    test('is 100 when the limit is zero but there is debt', () {
      expect(sample(limit: 0, currentDebt: 0).usagePercentage, 0);
      expect(sample(limit: 0, currentDebt: 100).usagePercentage, 100);
    });

    test('can exceed 100 when debt is above the limit', () {
      expect(sample(limit: 1000, currentDebt: 1500).usagePercentage, 150);
      expect(sample(limit: 1000, currentDebt: 1500).isOverLimit, isTrue);
      expect(sample(limit: 1000, currentDebt: 1000).isOverLimit, isFalse);
    });

    test('treats negative debt as no usage', () {
      expect(sample(limit: 1000, currentDebt: -10).usagePercentage, 0);
    });

    test('clamps the progress ratio between 0 and 1', () {
      expect(sample(limit: 1000, currentDebt: 250).usageRatio, 0.25);
      expect(sample(limit: 1000, currentDebt: 1500).usageRatio, 1);
      expect(sample(limit: 1000, currentDebt: -10).usageRatio, 0);
      expect(sample(limit: 0, currentDebt: 10).usageRatio, 1);
    });
  });

  group('next due date', () {
    test('stays in the current month when the due day has not passed', () {
      final card = sample(dueDay: 15);
      final from = DateTime(2026, 11, 10, 23, 59);
      expect(card.nextDueDate(from), DateTime(2026, 11, 15));
      expect(card.daysRemaining(from), 5);
      expect(card.isOverdue(from), isFalse);
    });

    test('ignores the time of day and is zero on the due date', () {
      final card = sample(dueDay: 15);
      final from = DateTime(2026, 11, 15, 23, 59);
      expect(card.nextDueDate(from), DateTime(2026, 11, 15));
      expect(card.daysRemaining(from), 0);
      expect(card.isOverdue(from), isFalse);
      expect(card.daysOverdue(from), 0);
      expect(card.dueStatusLabel(from), 'Bugün son gün');
      expect(card.dueUrgency(from), DueUrgency.soon);
      expect(card.shouldHighlightDue(from), isTrue);
    });

    test('labels the day before the due date as tomorrow', () {
      final card = sample(dueDay: 15);
      expect(card.dueStatusLabel(DateTime(2026, 11, 14)), 'Yarın');
      expect(card.daysRemaining(DateTime(2026, 11, 14)), 1);
    });

    test('highlights within 3 days and not on the 4th day', () {
      final card = sample(dueDay: 15);
      expect(card.daysRemaining(DateTime(2026, 11, 12)), 3);
      expect(card.shouldHighlightDue(DateTime(2026, 11, 12)), isTrue);
      expect(card.dueUrgency(DateTime(2026, 11, 12)), DueUrgency.soon);
      expect(card.dueStatusLabel(DateTime(2026, 11, 12)), '3 gün kaldı');

      expect(card.daysRemaining(DateTime(2026, 11, 11)), 4);
      expect(card.shouldHighlightDue(DateTime(2026, 11, 11)), isFalse);
      expect(card.dueUrgency(DateTime(2026, 11, 11)), DueUrgency.normal);
      expect(card.dueStatusLabel(DateTime(2026, 11, 11)), '4 gün kaldı');
    });

    test(
      'rolls to next month after the due day and marks the card overdue',
      () {
        final card = sample(dueDay: 10);
        final from = DateTime(2026, 11, 12, 8);
        expect(card.nextDueDate(from), DateTime(2026, 12, 10));
        expect(card.daysRemaining(from), 28);
        expect(card.isOverdue(from), isTrue);
        expect(card.daysOverdue(from), 2);
        expect(card.dueUrgency(from), DueUrgency.overdue);
        expect(card.dueStatusLabel(from), '2 gün gecikti');
        expect(card.shouldHighlightDue(from), isTrue);
      },
    );

    test('uses singular overdue wording for a single day', () {
      final card = sample(dueDay: 10);
      expect(card.dueStatusLabel(DateTime(2026, 11, 11)), '1 gün gecikti');
    });

    test('clamps due day 31 to 28 February in a non-leap year', () {
      final card = sample(dueDay: 31);
      final from = DateTime(2026, 2, 1, 22, 30);
      expect(card.nextDueDate(from), DateTime(2026, 2, 28));
      expect(card.daysRemaining(from), 27);
      expect(card.dueDateInMonth(2026, 2), DateTime(2026, 2, 28));
    });

    test('clamps due day 31 to 29 February in a leap year', () {
      final card = sample(dueDay: 31);
      expect(card.nextDueDate(DateTime(2024, 2, 28)), DateTime(2024, 2, 29));
      expect(card.daysRemaining(DateTime(2024, 2, 28)), 1);
      expect(card.dueDateInMonth(2024, 2), DateTime(2024, 2, 29));
    });

    test('clamps due day 31 to the 30th in a 30-day month', () {
      final card = sample(dueDay: 31);
      expect(card.nextDueDate(DateTime(2026, 4, 15)), DateTime(2026, 4, 30));
      expect(card.isOverdue(DateTime(2026, 4, 30)), isFalse);
      expect(card.daysRemaining(DateTime(2026, 4, 30)), 0);
    });

    test('rolls from December into January', () {
      final card = sample(dueDay: 5);
      final from = DateTime(2026, 12, 20);
      expect(card.nextDueDate(from), DateTime(2027, 1, 5));
      expect(card.isOverdue(from), isTrue);
      expect(card.daysOverdue(from), 15);
      expect(card.daysRemaining(from), 16);
    });

    test('starts a new cycle on the first day of the next month', () {
      final card = sample(dueDay: 25);
      final from = DateTime(2026, 12, 1);
      expect(card.isOverdue(from), isFalse);
      expect(card.nextDueDate(from), DateTime(2026, 12, 25));
      expect(card.daysOverdue(from), 0);
    });

    test('clamps an out-of-range stored due day before applying the month', () {
      final card = sample(dueDay: 40);
      expect(card.dueDateInMonth(2026, 1), DateTime(2026, 1, 31));
      final early = sample(dueDay: 0);
      expect(early.dueDateInMonth(2026, 1), DateTime(2026, 1, 1));
    });
  });

  group('hive compatibility', () {
    test('reads cards saved before last-four and minimum payment existed', () {
      final card = readHive(CreditCardAdapter(), (writer) {
        writer
          ..writeByte(10)
          ..writeByte(0)
          ..write('legacy-card')
          ..writeByte(1)
          ..write('Platinum')
          ..writeByte(2)
          ..write('Ziraat')
          ..writeByte(3)
          ..write(20000.0)
          ..writeByte(4)
          ..write(5000.0)
          ..writeByte(5)
          ..write(15)
          ..writeByte(6)
          ..write(25)
          ..writeByte(7)
          ..write('#2563EB')
          ..writeByte(8)
          ..write(true)
          ..writeByte(9)
          ..write(DateTime(2024, 5, 1));
      });

      expect(card.id, 'legacy-card');
      expect(card.name, 'Platinum');
      expect(card.limit, 20000);
      expect(card.currentDebt, 5000);
      expect(card.availableLimit, 15000);
      expect(card.usagePercentage, 25);
      expect(card.statementDay, 15);
      expect(card.dueDay, 25);
      expect(card.color, '#2563EB');
      expect(card.isActive, isTrue);
      expect(card.createdAt.year, 2024);
      expect(card.lastFourDigits, isNull);
      expect(card.minimumPayment, isNull);
    });

    test('round-trips the new optional fields', () {
      final original = CreditCard(
        id: 'new-card',
        name: 'Miles',
        bankName: 'Yapı Kredi',
        limit: 30000,
        currentDebt: 1200.5,
        statementDay: 3,
        dueDay: 13,
        color: '#DC2626',
        createdAt: DateTime(2025, 8, 9),
        lastFourDigits: '4242',
        minimumPayment: 350.75,
      );

      final loaded = readHive(CreditCardAdapter(), (writer) {
        CreditCardAdapter().write(writer, original);
      });

      expect(loaded.id, original.id);
      expect(loaded.lastFourDigits, '4242');
      expect(loaded.minimumPayment, 350.75);
      expect(loaded.availableLimit, original.availableLimit);
      expect(loaded.statementDay, 3);
      expect(loaded.dueDay, 13);
      expect(loaded.createdAt.year, 2025);
      expect(loaded.createdAt.month, 8);
      expect(loaded.createdAt.day, 9);
    });
  });
}
