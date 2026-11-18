import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../services/transaction_repository.dart';
import '../utils/transaction_summary.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(
    Hive.box<Transaction>(TransactionRepository.boxName),
  ),
);

/// Kayıtlı kategoriler (Hive `categories` kutusundan, id'ye göre tekil).
final categoriesProvider = Provider<List<Category>>((ref) {
  final byId = <String, Category>{};
  for (final c in Hive.box<Category>('categories').values) {
    byId[c.id] = c;
  }
  return byId.values.toList();
});

/// Tüm işlemler, en yeniden eskiye sıralı.
class TransactionsNotifier extends Notifier<List<Transaction>> {
  TransactionRepository get _repo => ref.read(transactionRepositoryProvider);

  @override
  List<Transaction> build() =>
      sortNewestFirst(ref.watch(transactionRepositoryProvider).getAll());

  Future<void> add(Transaction transaction) => _save(transaction);

  Future<void> edit(Transaction transaction) => _save(transaction);

  Future<void> remove(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _repo.delete(id);
  }

  Future<void> _save(Transaction transaction) async {
    state = sortNewestFirst([
      ...state.where((t) => t.id != transaction.id),
      transaction,
    ]);
    await _repo.save(transaction);
  }
}

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<Transaction>>(
  TransactionsNotifier.new,
);

/// Genel Bakış için içinde bulunulan ayın toplamları.
final currentMonthSummaryProvider = Provider<TransactionSummary>((ref) {
  return TransactionSummary.forMonth(
    ref.watch(transactionsProvider),
    DateTime.now(),
  );
});
