import 'package:hive/hive.dart';

import '../models/transaction.dart';

/// İşlemlerin Hive kutusuna yazılıp okunduğu katman.
class TransactionRepository {
  static const String boxName = 'transactions';

  final Box<Transaction> _box;

  TransactionRepository(this._box);

  List<Transaction> getAll() => _box.values.toList();

  /// Ekleme ve güncelleme: anahtar her zaman işlemin `id` alanıdır.
  Future<void> save(Transaction transaction) =>
      _box.put(transaction.id, transaction);

  /// Birden fazla işlemi tek seferde yazar.
  Future<void> saveAll(Iterable<Transaction> transactions) =>
      _box.putAll({for (final t in transactions) t.id: t});

  Future<void> delete(String id) => _box.delete(id);
}
