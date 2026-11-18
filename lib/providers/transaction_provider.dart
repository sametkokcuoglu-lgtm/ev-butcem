import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/transaction.dart';
import '../services/transaction_repository.dart';
import '../utils/transaction_summary.dart';

// Kategori sağlayıcıları eskiden bu dosyadaydı; mevcut importlar bozulmasın.
export 'category_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(
    Hive.box<Transaction>(TransactionRepository.boxName),
  ),
);

/// Tüm işlemler, en yeniden eskiye sıralı.
class TransactionsNotifier extends Notifier<List<Transaction>> {
  TransactionRepository get _repo => ref.read(transactionRepositoryProvider);

  @override
  List<Transaction> build() =>
      sortNewestFirst(ref.watch(transactionRepositoryProvider).getAll());

  Future<void> add(Transaction transaction) => _save(transaction);

  /// Güncelleme: `id` ve `createdAt` korunmalı, `updatedAt` yenilenir.
  Future<void> edit(Transaction transaction) => _save(transaction);

  /// İşlemi siler ve silinen kaydı döndürür (geri almak için).
  Future<Transaction?> remove(String id) async {
    Transaction? removed;
    for (final t in state) {
      if (t.id == id) removed = t;
    }
    state = state.where((t) => t.id != id).toList();
    await _repo.delete(id);
    return removed;
  }

  /// Silinen bir işlemi aynı id, tarih ve oluşturulma zamanıyla geri yükler.
  Future<void> restore(Transaction transaction) => _save(transaction.clone());

  /// [fromCategoryId] kategorisindeki tüm işlemleri [toCategoryId]'ye taşır.
  /// Taşınan işlem sayısını döndürür.
  Future<int> reassignCategory(String fromCategoryId, String toCategoryId) async {
    final moved = [
      for (final t in state)
        if (t.categoryId == fromCategoryId) t.copyWith(categoryId: toCategoryId),
    ];
    if (moved.isEmpty) return 0;
    final ids = {for (final t in moved) t.id};
    state = sortNewestFirst([
      ...state.where((t) => !ids.contains(t.id)),
      ...moved,
    ]);
    await _repo.saveAll(moved);
    return moved.length;
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
