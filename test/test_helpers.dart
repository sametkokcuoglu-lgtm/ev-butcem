import 'dart:typed_data';

import 'package:ev_butcem/models/category.dart';
import 'package:ev_butcem/models/transaction.dart';
import 'package:ev_butcem/providers/transaction_provider.dart';
import 'package:ev_butcem/services/category_repository.dart';
import 'package:ev_butcem/services/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Testlerde kullanılan sabit kategoriler.
List<Category> testCategories() => [
      Category(id: 'market', name: 'Market', icon: '🛒', colorValue: 0xFF4CAF50, isIncome: false, isSystem: true),
      Category(id: 'kira', name: 'Kira', icon: '🏠', colorValue: 0xFF3F51B5, isIncome: false, isSystem: true),
      Category(id: 'maas', name: 'Maaş', icon: '💰', colorValue: 0xFF4CAF50, isIncome: true, isSystem: true),
    ];

void registerTestAdapters() {
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CategoryAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TransactionAdapter());
}

int _seq = 0;

/// Bellek içi Hive kutuları: diske yazmaz, testler birbirini etkilemez.
class TestBoxes {
  final Box<Category> categories;
  final Box<Transaction> transactions;

  TestBoxes(this.categories, this.transactions);

  static Future<TestBoxes> open({List<Category>? categories}) async {
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_seq++}';
    final c = await Hive.openBox<Category>('categories_$id', bytes: Uint8List(0));
    final t = await Hive.openBox<Transaction>('transactions_$id', bytes: Uint8List(0));
    final seed = categories ?? testCategories();
    await c.putAll({for (final x in seed) x.id: x});
    return TestBoxes(c, t);
  }

  List<Override> get overrides => [
        transactionRepositoryProvider.overrideWithValue(TransactionRepository(transactions)),
        categoryRepositoryProvider.overrideWithValue(CategoryRepository(categories)),
      ];

  ProviderContainer container() => ProviderContainer(overrides: overrides);

  Widget app(Widget home) => ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: const Locale('tr', 'TR'),
          supportedLocales: const [Locale('tr', 'TR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: home,
        ),
      );

  Future<void> close() async {
    await categories.close();
    await transactions.close();
  }
}
