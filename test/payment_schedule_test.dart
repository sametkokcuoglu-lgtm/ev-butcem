import 'dart:io';

import 'package:ev_butcem/data/payment_stores.dart';
import 'package:ev_butcem/models/account.dart';
import 'package:ev_butcem/models/category.dart';
import 'package:ev_butcem/models/credit_card.dart';
import 'package:ev_butcem/models/installment.dart';
import 'package:ev_butcem/models/planned_payment.dart';
import 'package:ev_butcem/models/scheduled_item.dart';
import 'package:ev_butcem/models/transaction.dart';
import 'package:ev_butcem/providers/finance_providers.dart';
import 'package:ev_butcem/utils/dates.dart';
import 'package:ev_butcem/utils/format.dart';
import 'package:ev_butcem/utils/payment_schedule.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  final now = DateTime(2026, 11, 18);

  group('tarih yardımcıları', () {
    test('ay eklerken ay sonuna sabitlenir', () {
      expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
      expect(addMonths(DateTime(2026, 1, 31), 2), DateTime(2026, 3, 31));
      expect(addMonths(DateTime(2026, 11, 18), 12), DateTime(2027, 11, 18));
    });

    test('hafta pazartesi başlar ve pazar biter', () {
      expect(endOfWeek(DateTime(2026, 11, 18)), DateTime(2026, 11, 22));
      expect(endOfWeek(DateTime(2026, 11, 22)), DateTime(2026, 11, 22));
    });

    test('kasım 2026 ızgarası pazartesiden başlar', () {
      final cells = monthCells(DateTime(2026, 11));
      expect(cells.length % 7, 0);
      expect(cells.length, 42);
      expect(cells[5], isNull);
      expect(cells[6], DateTime(2026, 11, 1));
      expect(cells[35], DateTime(2026, 11, 30));
    });
  });

  group('tutar biçimi', () {
    test('Türkçe tutar metnini okur', () {
      expect(parseTryInput('1250'), 1250);
      expect(parseTryInput('1.250,50'), 1250.50);
      expect(parseTryInput('1250,5'), 1250.5);
      expect(parseTryInput('₺ 875'), 875);
      expect(parseTryInput('1.250'), 1250);
      expect(parseTryInput('1250.50'), 1250.50);
      expect(parseTryInput(''), isNull);
      expect(parseTryInput('abc'), isNull);
    });

    test('göreli gün etiketleri', () {
      expect(relativeDayLabel(DateTime(2026, 11, 18), now), 'Bugün');
      expect(relativeDayLabel(DateTime(2026, 11, 19), now), 'Yarın');
      expect(relativeDayLabel(DateTime(2026, 11, 17), now), 'Dün');
      expect(relativeDayLabel(DateTime(2026, 11, 10), now), '8 gün gecikti');
      expect(relativeDayLabel(DateTime(2026, 11, 21), now), '3 gün sonra');
    });
  });

  group('gruplama', () {
    PaymentGroup? group(DateTime date, {bool isPaid = false, DateTime? clock}) {
      return paymentGroupFor(date, clock ?? now, isPaid: isPaid);
    }

    test('gecikmiş, bugün, bu hafta ve daha sonra', () {
      expect(group(DateTime(2026, 11, 10)), PaymentGroup.overdue);
      expect(group(DateTime(2026, 11, 18)), PaymentGroup.today);
      expect(group(DateTime(2026, 11, 20)), PaymentGroup.thisWeek);
      expect(group(DateTime(2026, 11, 22)), PaymentGroup.thisWeek);
      expect(group(DateTime(2026, 11, 23)), PaymentGroup.later);
    });

    test('ödenmiş gecikmiş kayıt gizlenir, bugün ödenen kalır', () {
      expect(group(DateTime(2026, 11, 10), isPaid: true), isNull);
      expect(group(DateTime(2026, 11, 18), isPaid: true), PaymentGroup.today);
    });

    test('30 gün ufku dahil, 31. gün hariç', () {
      expect(group(DateTime(2026, 12, 18)), PaymentGroup.later);
      expect(group(DateTime(2026, 12, 19)), isNull);
    });

    test('pazar günü yarın bu hafta sayılmaz', () {
      final sunday = DateTime(2026, 11, 22);
      expect(group(DateTime(2026, 11, 23), clock: sunday), PaymentGroup.later);
      expect(group(DateTime(2026, 11, 22), clock: sunday), PaymentGroup.today);
    });

    test('bölümler tarihe göre sıralanır', () {
      final sections = groupScheduledItems(
        [
          _item('Sonra', DateTime(2026, 12, 1)),
          _item('Gecikmiş', DateTime(2026, 11, 2)),
          _item('Hafta 2', DateTime(2026, 11, 21)),
          _item('Hafta 1', DateTime(2026, 11, 19)),
          _item('Bugün', DateTime(2026, 11, 18)),
          _item('Eski ödenen', DateTime(2026, 11, 1), isPaid: true),
        ],
        now,
      );

      expect(sections.map((section) => section.group), [
        PaymentGroup.overdue,
        PaymentGroup.today,
        PaymentGroup.thisWeek,
        PaymentGroup.later,
      ]);
      expect(
          sections[2].items.map((item) => item.title), ['Hafta 1', 'Hafta 2']);
      expect(
          sections.expand((section) => section.items).map((item) => item.title),
          isNot(contains('Eski ödenen')));
    });
  });

  group('tekrar ve kaynaklar', () {
    test('aylık seri ara ayları yaklaşan listede çoğaltmaz', () {
      final rent = PlannedPayment(
        id: 'rent',
        title: 'Kira',
        amount: 1000,
        dueDate: DateTime(2026, 1, 1),
        recurrence: PaymentRecurrence.monthly,
      );

      expect(
        upcomingPlannedDates(rent, DateTime(2026, 6, 15)),
        [DateTime(2026, 1, 1), DateTime(2026, 7, 1)],
      );
    });

    test('ayın 31’i şubat ve martta doğru güne denk gelir', () {
      expect(
        occurrenceDates(
          anchor: DateTime(2026, 1, 31),
          monthStep: 1,
          start: DateTime(2026, 2, 1),
          end: DateTime(2026, 2, 28),
        ),
        [DateTime(2026, 2, 28)],
      );
      expect(
        occurrenceDates(
          anchor: DateTime(2026, 1, 31),
          monthStep: 1,
          start: DateTime(2026, 3, 1),
          end: DateTime(2026, 3, 31),
        ),
        [DateTime(2026, 3, 31)],
      );
    });

    test('yıllık ödeme kendi ayında görünür', () {
      expect(
        occurrenceDates(
          anchor: DateTime(2024, 11, 18),
          monthStep: 12,
          start: DateTime(2026, 11, 1),
          end: DateTime(2026, 11, 30),
        ),
        [DateTime(2026, 11, 18)],
      );
    });

    test('planlı ödemede kategori ve hesap adı birleşir', () {
      final sections = buildUpcomingSections(
        now: now,
        planned: [
          PlannedPayment(
            id: 'bill',
            title: 'Elektrik',
            amount: 875,
            dueDate: DateTime(2026, 11, 20),
            categoryId: 'cat',
            accountId: 'acc',
          ),
        ],
        cards: const [],
        installments: const [],
        accounts: [
          Account(id: 'acc', name: 'Ziraat Vadesiz', bankName: 'Ziraat'),
        ],
        categories: [
          Category(
              id: 'cat',
              name: 'Faturalar',
              icon: '💡',
              colorValue: 1,
              isIncome: false),
        ],
      );

      final item = sections.single.items.single;
      expect(sections.single.group, PaymentGroup.thisWeek);
      expect(item.subtitle, 'Faturalar · Ziraat Vadesiz');
      expect(item.canTogglePaid, isTrue);
    });

    test('kart borcu bu ayın son ödeme gününde, geçmiş ayda değil', () {
      final card = CreditCard(
        id: 'card',
        name: 'Platinum',
        bankName: 'Ziraat',
        limit: 20000,
        currentDebt: 4250,
        statementDay: 1,
        dueDay: 5,
      );

      final upcoming = buildUpcomingSections(
        now: DateTime(2026, 11, 28),
        planned: const [],
        cards: [card],
        installments: const [],
      );
      expect(upcoming.single.items.single.date, DateTime(2026, 11, 5));
      expect(upcoming.single.group, PaymentGroup.overdue);
      expect(upcoming.single.items.single.canTogglePaid, isFalse);

      final february = buildMonthFinance(
        month: DateTime(2026, 2),
        today: DateTime(2026, 2, 1),
        planned: const [],
        cards: [card.copyWith(dueDay: 31)],
        installments: const [],
      );
      expect(february.entries.single.date, DateTime(2026, 2, 28));

      final cleared = buildUpcomingSections(
        now: now,
        planned: const [],
        cards: [card.copyWith(currentDebt: 0)],
        installments: const [],
      );
      expect(cleared, isEmpty);

      final pastMonth = buildMonthFinance(
        month: DateTime(2026, 1),
        today: DateTime(2026, 2, 1),
        planned: const [],
        cards: [card],
        installments: const [],
      );
      expect(pastMonth.entries, isEmpty);
    });

    test('taksitler ödenen ve sıradaki taksidi ayırır', () {
      final installment = Installment(
        id: 'phone',
        title: 'Telefon',
        totalAmount: 4000,
        totalInstallments: 4,
        paidInstallments: 1,
        startDate: DateTime(2026, 1, 15),
      );

      final onFebruaryFirst = buildUpcomingSections(
        now: DateTime(2026, 2, 1),
        planned: const [],
        cards: const [],
        installments: [installment],
      );
      expect(onFebruaryFirst.single.items.map((item) => item.date),
          [DateTime(2026, 2, 15)]);
      expect(onFebruaryFirst.single.items.single.canTogglePaid, isTrue);
      expect(onFebruaryFirst.single.items.single.amount, 1000);
      expect(onFebruaryFirst.single.items.single.subtitle, '2/4 taksit');

      final onMarchTwentieth = buildUpcomingSections(
        now: DateTime(2026, 3, 20),
        planned: const [],
        cards: const [],
        installments: [installment],
      );
      final titles =
          onMarchTwentieth.expand((section) => section.items).toList();
      expect(titles.map((item) => item.date), [
        DateTime(2026, 2, 15),
        DateTime(2026, 3, 15),
        DateTime(2026, 4, 15),
      ]);
      expect(titles.map((item) => item.canTogglePaid), [true, false, false]);
    });

    test('ay özeti yalnızca yükümlülükleri sayar', () {
      final summary = buildMonthFinance(
        month: DateTime(2026, 3),
        today: DateTime(2026, 3, 1),
        planned: [
          PlannedPayment(
              id: 'rent',
              title: 'Kira',
              amount: 1000,
              dueDate: DateTime(2026, 3, 5)),
          PlannedPayment(
            id: 'aidat',
            title: 'Aidat',
            amount: 500,
            dueDate: DateTime(2026, 3, 10),
            isPaid: true,
          ),
        ],
        cards: [
          CreditCard(
            id: 'card',
            name: 'Kart',
            bankName: 'Banka',
            limit: 10000,
            currentDebt: 2000,
            statementDay: 1,
            dueDay: 20,
          ),
        ],
        installments: [
          Installment(
            id: 'loan',
            title: 'Kredi',
            totalAmount: 1000,
            totalInstallments: 4,
            paidInstallments: 0,
            startDate: DateTime(2026, 3, 15),
          ),
        ],
        transactions: [
          Transaction(
            id: 'salary',
            amount: 7000,
            categoryId: 'maas',
            date: DateTime(2026, 3, 3),
            isIncome: true,
            note: 'Maaş',
          ),
          Transaction(
            id: 'market',
            amount: 50,
            categoryId: 'market',
            date: DateTime(2026, 3, 4),
            isIncome: false,
          ),
        ],
      );

      expect(summary.summary.totalDue, 3750);
      expect(summary.summary.paid, 500);
      expect(summary.summary.remaining, 3250);
      expect(
          summary.entries.where((item) => item.isIncome).single.title, 'Maaş');
    });

    test('ödenen aylık kaydın sonraki ayı ödenmemiş kalır', () {
      final payment = PlannedPayment(
        id: 'net',
        title: 'İnternet',
        amount: 400,
        dueDate: DateTime(2026, 11, 5),
        recurrence: PaymentRecurrence.monthly,
        isPaid: true,
      );

      final november = buildMonthFinance(
        month: DateTime(2026, 11),
        today: now,
        planned: [payment],
        cards: const [],
        installments: const [],
      );
      expect(november.entries.single.isPaid, isTrue);
      expect(november.summary.paid, 400);

      final december = buildMonthFinance(
        month: DateTime(2026, 12),
        today: now,
        planned: [payment],
        cards: const [],
        installments: const [],
      );
      expect(december.entries.single.date, DateTime(2026, 12, 5));
      expect(december.entries.single.isPaid, isFalse);
      expect(december.entries.single.canTogglePaid, isFalse);
    });
  });

  group('kayıt', () {
    test('ödeme işaretlenince sonraki döneme alınabilir', () async {
      final store = MemoryPlannedPaymentStore([
        PlannedPayment(
          id: 'rent',
          title: 'Kira',
          amount: 15000,
          dueDate: DateTime(2026, 11, 18),
          recurrence: PaymentRecurrence.monthly,
        ),
      ]);
      final container = ProviderContainer(
        overrides: [
          plannedPaymentStoreProvider.overrideWith((ref) => store),
        ],
      );
      addTearDown(container.dispose);

      await container.read(plannedPaymentsProvider.notifier).togglePaid('rent');
      expect(container.read(plannedPaymentsProvider).single.isPaid, isTrue);

      await container
          .read(plannedPaymentsProvider.notifier)
          .advanceToNextPeriod('rent');
      final updated = container.read(plannedPaymentsProvider).single;
      expect(updated.dueDate, DateTime(2026, 12, 18));
      expect(updated.isPaid, isFalse);
    });

    test('taksit ödeme sayısı sınırın dışına çıkmaz', () async {
      final store = MemoryInstallmentStore([
        Installment(
          id: 'phone',
          title: 'Telefon',
          totalAmount: 4000,
          totalInstallments: 4,
          paidInstallments: 1,
          startDate: DateTime(2026, 1, 15),
        ),
      ]);
      final container = ProviderContainer(
        overrides: [
          installmentStoreProvider.overrideWith((ref) => store),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(installmentsProvider.notifier)
          .setPaidCount('phone', 2);
      expect(container.read(installmentsProvider).single.paidInstallments, 2);
      await container
          .read(installmentsProvider.notifier)
          .setPaidCount('phone', 99);
      expect(container.read(installmentsProvider).single.paidInstallments, 4);
    });

    test('planlı ödeme Hive kutusuna gidip gelir', () async {
      final directory = await Directory.systemTemp.createTemp('ev_butcem_hive');
      Hive.init(directory.path);
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(PlannedPaymentAdapter());
      }
      final box = await Hive.openBox<PlannedPayment>('planned_payments_test');
      final payment = PlannedPayment(
        id: 'p1',
        title: 'Kira',
        amount: 12500,
        dueDate: DateTime(2026, 11, 5, 15, 30),
        recurrence: PaymentRecurrence.yearly,
        accountId: 'acc',
        categoryId: 'cat',
        isPaid: true,
        createdAt: DateTime(2026, 1, 1),
      );

      await box.put(payment.id, payment);
      final loaded = box.get('p1')!;

      expect(loaded.title, 'Kira');
      expect(loaded.amount, 12500);
      expect(loaded.dueDate, DateTime(2026, 11, 5));
      expect(loaded.recurrence, PaymentRecurrence.yearly);
      expect(loaded.accountId, 'acc');
      expect(loaded.categoryId, 'cat');
      expect(loaded.creditCardId, isNull);
      expect(loaded.isPaid, isTrue);
      expect(loaded.createdAt, DateTime(2026, 1, 1));

      await box.close();
      await directory.delete(recursive: true);
    });
  });
}

ScheduledItem _item(String title, DateTime date, {bool isPaid = false}) {
  return ScheduledItem(
    id: title,
    sourceId: title,
    kind: FinanceKind.planned,
    title: title,
    amount: 10,
    date: date,
    isPaid: isPaid,
    canTogglePaid: true,
  );
}
