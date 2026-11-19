import 'package:hive_flutter/hive_flutter.dart';

import '../models/account.dart';
import '../models/bill.dart';
import '../models/category.dart';
import '../models/credit_card.dart';
import '../models/installment.dart';
import '../models/planned_payment.dart';
import '../models/transaction.dart';
import '../utils/default_data.dart';

const String categoryBoxName = 'categories';
const String transactionBoxName = 'transactions';
const String accountBoxName = 'accounts';
const String creditCardBoxName = 'credit_cards';
const String installmentBoxName = 'installments';
const String plannedPaymentBoxName = 'planned_payments';
const String billBoxName = 'bills';

Future<void> initLocalDatabase() async {
  await Hive.initFlutter();
  _registerAdapters();

  await Hive.openBox<Category>(categoryBoxName);
  await Hive.openBox<Transaction>(transactionBoxName);
  await Hive.openBox<Account>(accountBoxName);
  await Hive.openBox<CreditCard>(creditCardBoxName);
  await Hive.openBox<Installment>(installmentBoxName);
  await Hive.openBox<PlannedPayment>(plannedPaymentBoxName);
  await Hive.openBox<Bill>(billBoxName);

  final categories = Hive.box<Category>(categoryBoxName);
  if (categories.isEmpty) {
    for (final category in DefaultData.defaultCategories) {
      await categories.put(category.id, category);
    }
  }
}

void _registerAdapters() {
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TransactionAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AccountAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(CreditCardAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(InstallmentAdapter());
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(PlannedPaymentAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(BillAdapter());
}
