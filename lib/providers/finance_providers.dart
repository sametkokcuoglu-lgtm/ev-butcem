import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_database.dart';
import '../data/payment_stores.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/credit_card.dart';
import '../models/installment.dart';
import '../models/planned_payment.dart';
import '../models/scheduled_item.dart';
import '../models/transaction.dart';
import '../utils/dates.dart';
import '../utils/payment_schedule.dart';

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final plannedPaymentStoreProvider = Provider<PlannedPaymentStore>((ref) {
  return HivePlannedPaymentStore();
});

final installmentStoreProvider = Provider<InstallmentStore>((ref) {
  return HiveInstallmentStore();
});

final plannedPaymentsProvider =
    NotifierProvider<PlannedPaymentsNotifier, List<PlannedPayment>>(
        PlannedPaymentsNotifier.new);

class PlannedPaymentsNotifier extends Notifier<List<PlannedPayment>> {
  @override
  List<PlannedPayment> build() =>
      _sorted(ref.watch(plannedPaymentStoreProvider).load());

  Future<void> upsert(PlannedPayment payment) async {
    await ref.read(plannedPaymentStoreProvider).save(payment);
    state = _sorted(ref.read(plannedPaymentStoreProvider).load());
  }

  Future<void> delete(String id) async {
    await ref.read(plannedPaymentStoreProvider).delete(id);
    state = _sorted(ref.read(plannedPaymentStoreProvider).load());
  }

  Future<void> togglePaid(String id) async {
    final current = _find(id);
    if (current == null) return;
    await upsert(current.copyWith(isPaid: !current.isPaid));
  }

  Future<void> advanceToNextPeriod(String id) async {
    final current = _find(id);
    if (current == null || current.recurrence == PaymentRecurrence.none) return;
    final months = current.recurrence == PaymentRecurrence.monthly ? 1 : 12;
    await upsert(
      current.copyWith(
        dueDate: addMonths(dateOnly(current.dueDate), months),
        isPaid: false,
      ),
    );
  }

  PlannedPayment? _find(String id) {
    for (final payment in state) {
      if (payment.id == id) return payment;
    }
    return null;
  }

  List<PlannedPayment> _sorted(List<PlannedPayment> items) {
    final copy = List<PlannedPayment>.of(items);
    copy.sort((a, b) {
      final byDate = a.dueDate.compareTo(b.dueDate);
      if (byDate != 0) return byDate;
      return a.title.compareTo(b.title);
    });
    return copy;
  }
}

final installmentsProvider =
    NotifierProvider<InstallmentsNotifier, List<Installment>>(
        InstallmentsNotifier.new);

class InstallmentsNotifier extends Notifier<List<Installment>> {
  @override
  List<Installment> build() => ref.watch(installmentStoreProvider).load();

  Future<void> setPaidCount(String id, int count) async {
    Installment? current;
    for (final installment in state) {
      if (installment.id == id) {
        current = installment;
        break;
      }
    }
    if (current == null) return;
    final max = current.totalInstallments;
    final paid = count < 0 ? 0 : (count > max ? max : count);
    await ref
        .read(installmentStoreProvider)
        .save(current.copyWith(paidInstallments: paid));
    state = ref.read(installmentStoreProvider).load();
  }
}

final accountsProvider = Provider<List<Account>>((ref) {
  return readHiveList<Account>(accountBoxName);
});

final categoriesProvider = Provider<List<Category>>((ref) {
  return readHiveList<Category>(categoryBoxName);
});

final creditCardsProvider = Provider<List<CreditCard>>((ref) {
  return readHiveList<CreditCard>(creditCardBoxName);
});

final transactionsProvider = Provider<List<Transaction>>((ref) {
  return readHiveList<Transaction>(transactionBoxName);
});

final upcomingSectionsProvider = Provider<List<PaymentSection>>((ref) {
  return buildUpcomingSections(
    now: ref.watch(clockProvider)(),
    planned: ref.watch(plannedPaymentsProvider),
    cards: ref.watch(creditCardsProvider),
    installments: ref.watch(installmentsProvider),
    accounts: ref.watch(accountsProvider),
    categories: ref.watch(categoriesProvider),
  );
});

final visibleMonthProvider = StateProvider<DateTime>((ref) {
  final now = ref.watch(clockProvider)();
  return DateTime(now.year, now.month);
});

final selectedDayProvider = StateProvider<DateTime>((ref) {
  return dateOnly(ref.watch(clockProvider)());
});

final monthFinanceProvider = Provider<MonthFinance>((ref) {
  final month = ref.watch(visibleMonthProvider);
  return buildMonthFinance(
    month: month,
    today: ref.watch(clockProvider)(),
    planned: ref.watch(plannedPaymentsProvider),
    cards: ref.watch(creditCardsProvider),
    installments: ref.watch(installmentsProvider),
    accounts: ref.watch(accountsProvider),
    categories: ref.watch(categoriesProvider),
    transactions: ref.watch(transactionsProvider),
  );
});
