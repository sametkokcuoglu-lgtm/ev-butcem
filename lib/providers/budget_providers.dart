import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/budget_limit.dart';
import '../models/category.dart';
import '../models/transaction.dart';

final categoriesProvider = NotifierProvider<CategoriesNotifier, List<Category>>(
    CategoriesNotifier.new);

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<Transaction>>(
  TransactionsNotifier.new,
);

final budgetLimitsProvider =
    NotifierProvider<BudgetLimitsNotifier, List<BudgetLimit>>(
  BudgetLimitsNotifier.new,
);

class CategoriesNotifier extends Notifier<List<Category>> {
  @override
  List<Category> build() {
    final box = Hive.box<Category>('categories');
    final subscription = box.watch().listen((_) {
      state = _readCategories();
    });
    ref.onDispose(subscription.cancel);
    return _readCategories();
  }
}

class TransactionsNotifier extends Notifier<List<Transaction>> {
  @override
  List<Transaction> build() {
    final box = Hive.box<Transaction>('transactions');
    final subscription = box.watch().listen((_) {
      state = _readTransactions();
    });
    ref.onDispose(subscription.cancel);
    return _readTransactions();
  }

  Future<void> add(Transaction transaction) {
    return Hive.box<Transaction>('transactions')
        .put(transaction.id, transaction);
  }
}

class BudgetLimitsNotifier extends Notifier<List<BudgetLimit>> {
  @override
  List<BudgetLimit> build() {
    final box = Hive.box<BudgetLimit>('budget_limits');
    final subscription = box.watch().listen((_) {
      state = _readLimits();
    });
    ref.onDispose(subscription.cancel);
    return _readLimits();
  }

  Future<void> save({
    required String categoryId,
    required double amount,
  }) async {
    final box = Hive.box<BudgetLimit>('budget_limits');
    final existing = box.values
        .where((limit) => limit.categoryId == categoryId)
        .toList(growable: false);
    final limit = BudgetLimit(
      id: existing.isEmpty ? null : existing.first.id,
      categoryId: categoryId,
      amount: amount,
    );
    await box.put(limit.id, limit);
    if (existing.length > 1) {
      await box.deleteAll(existing.skip(1).map((item) => item.id));
    }
  }

  Future<void> removeForCategory(String categoryId) async {
    final box = Hive.box<BudgetLimit>('budget_limits');
    final ids = box.values
        .where((limit) => limit.categoryId == categoryId)
        .map((limit) => limit.id)
        .toList(growable: false);
    if (ids.isEmpty) return;
    await box.deleteAll(ids);
  }
}

List<Category> _readCategories() {
  final items = Hive.box<Category>('categories').values.toList();
  items.sort((a, b) => a.name.compareTo(b.name));
  return List.unmodifiable(items);
}

List<Transaction> _readTransactions() {
  final items = Hive.box<Transaction>('transactions').values.toList();
  items.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    return b.createdAt.compareTo(a.createdAt);
  });
  return List.unmodifiable(items);
}

List<BudgetLimit> _readLimits() {
  final items = Hive.box<BudgetLimit>('budget_limits').values.toList();
  items.sort((a, b) => a.categoryId.compareTo(b.categoryId));
  return List.unmodifiable(items);
}
