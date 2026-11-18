import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/category.dart';
import '../models/transaction.dart';

final categoriesProvider = NotifierProvider<CategoriesNotifier, List<Category>>(
    CategoriesNotifier.new);

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<Transaction>>(
  TransactionsNotifier.new,
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
