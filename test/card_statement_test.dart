import 'package:ev_butcem/models/card_statement.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hive_bytes.dart';

void main() {
  CardStatement sample({
    double total = 1000,
    double paid = 0,
    double minimum = 100,
    DateTime? due,
  }) {
    return CardStatement(
      id: 'st-1',
      creditCardId: 'card-1',
      periodDate: DateTime(2026, 11, 15),
      dueDate: due ?? DateTime(2026, 11, 25),
      totalAmount: total,
      minimumPayment: minimum,
      paidAmount: paid,
      createdAt: DateTime(2026, 11, 15),
    );
  }

  group('payment status', () {
    test('is unpaid, partial or paid from the amounts', () {
      expect(sample().paymentStatus, StatementStatus.unpaid);
      expect(sample(paid: 400).paymentStatus, StatementStatus.partial);
      expect(sample(paid: 1000).paymentStatus, StatementStatus.paid);
      expect(sample(total: 1000, paid: 1000.004).isSettled, isTrue);
    });

    test('remaining amount is never negative', () {
      expect(sample(total: 1000, paid: 250).remainingAmount, 750);
      expect(sample(total: 1000, paid: 1000).remainingAmount, 0);
      expect(sample(total: 1000, paid: 1200).remainingAmount, 0);
    });
  });

  group('due date', () {
    test('counts days and highlights overdue or soon statements', () {
      final statement = sample(due: DateTime(2026, 11, 25, 22));
      expect(statement.daysUntilDue(DateTime(2026, 11, 22, 23)), 3);
      expect(statement.isDueSoon(DateTime(2026, 11, 22)), isTrue);
      expect(statement.isDueSoon(DateTime(2026, 11, 21)), isFalse);
      expect(statement.dueLabel(DateTime(2026, 11, 24)), 'Yarın');
      expect(statement.dueLabel(DateTime(2026, 11, 25)), 'Bugün son gün');
      expect(statement.isOverdue(DateTime(2026, 11, 26)), isTrue);
      expect(statement.dueLabel(DateTime(2026, 11, 27)), '2 gün gecikti');
    });

    test('a settled statement is not overdue', () {
      final statement = sample(paid: 1000, due: DateTime(2026, 11, 1));
      expect(statement.isOverdue(DateTime(2026, 11, 20)), isFalse);
      expect(statement.dueLabel(DateTime(2026, 11, 20)), 'Ödendi');
    });
  });

  group('debt stays consistent with payments', () {
    test('reduces debt by a new payment and restores it when unpaid', () {
      const debt = 5000.0;
      final afterPartial = StatementLedger.debtAfterPaidChange(
        debt: debt,
        previousPaid: 0,
        nextPaid: 400,
      );
      expect(afterPartial, 4600);

      final afterPaid = StatementLedger.debtAfterPaidChange(
        debt: afterPartial,
        previousPaid: 400,
        nextPaid: 1000,
      );
      expect(afterPaid, 4000);

      final afterDelete = StatementLedger.debtAfterPaidChange(
        debt: afterPaid,
        previousPaid: 1000,
        nextPaid: 0,
      );
      expect(afterDelete, debt);
    });

    test('marking paid pays the remaining statement balance', () {
      final statement = sample(total: 2500, paid: 500);
      final paid = statement.markPaid();
      expect(paid.paidAmount, 2500);
      expect(paid.paymentStatus, StatementStatus.paid);
      expect(
        StatementLedger.debtAfterPaidChange(
          debt: 8000,
          previousPaid: statement.paidAmount,
          nextPaid: paid.paidAmount,
        ),
        6000,
      );
    });
  });

  group('hive compatibility', () {
    test('reads a statement saved before paid amount and status existed', () {
      final statement = readHive(CardStatementAdapter(), (writer) {
        writer
          ..writeByte(5)
          ..writeByte(0)
          ..write('legacy')
          ..writeByte(1)
          ..write('card-1')
          ..writeByte(2)
          ..write(DateTime(2026, 10, 15))
          ..writeByte(3)
          ..write(DateTime(2026, 10, 25))
          ..writeByte(4)
          ..write(1800.0);
      });

      expect(statement.id, 'legacy');
      expect(statement.totalAmount, 1800);
      expect(statement.minimumPayment, 0);
      expect(statement.paidAmount, 0);
      expect(statement.paymentStatus, StatementStatus.unpaid);
      expect(statement.remainingAmount, 1800);
      expect(statement.createdAt, DateTime(2026, 10, 15));
    });

    test('round-trips payment fields', () {
      final original = sample(total: 3200, paid: 800, minimum: 320);
      final loaded = readHive(CardStatementAdapter(), (writer) {
        CardStatementAdapter().write(writer, original);
      });
      expect(loaded.paidAmount, 800);
      expect(loaded.minimumPayment, 320);
      expect(loaded.paymentStatus, StatementStatus.partial);
      expect(loaded.dueDate, DateTime(2026, 11, 25));
    });
  });
}
