import 'dart:typed_data';

import 'package:ev_butcem/models/category.dart';
import 'package:ev_butcem/models/transaction.dart';
import 'package:ev_butcem/providers/transaction_provider.dart';
import 'package:ev_butcem/screens/add_transaction_screen.dart';
import 'package:ev_butcem/screens/dashboard_screen.dart';
import 'package:ev_butcem/screens/transactions_screen.dart';
import 'package:ev_butcem/services/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';

final _categories = [
  Category(id: 'market', name: 'Market', icon: '🛒', colorValue: 0xFF4CAF50, isIncome: false),
  Category(id: 'kira', name: 'Kira', icon: '🏠', colorValue: 0xFF3F51B5, isIncome: false),
  Category(id: 'maas', name: 'Maaş', icon: '💰', colorValue: 0xFF4CAF50, isIncome: true),
];

late Box<Transaction> _box;

Widget _app(Widget home) => ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(TransactionRepository(_box)),
        categoriesProvider.overrideWithValue(_categories),
      ],
      child: MaterialApp(
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [Locale('tr', 'TR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: home,
      ),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
    Hive.registerAdapter(TransactionAdapter());
  });

  setUp(() async {
    // Bellek içi Hive kutusu: diske yazmaz, testler birbirini etkilemez.
    _box = await Hive.openBox<Transaction>(
      'transactions_${DateTime.now().microsecondsSinceEpoch}',
      bytes: Uint8List(0),
    );
  });

  tearDown(() async => _box.close());

  testWidgets('Gider kaydedilir, listelenir ve Hive kutusuna yazılır', (tester) async {
    await tester.pumpWidget(_app(const TransactionsScreen()));
    expect(find.text('Henüz işlem yok'), findsOneWidget);

    await tester.tap(find.text('Yeni İşlem'));
    await tester.pumpAndSettle();

    // Doğrulama: boş form kaydedilmez.
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();
    expect(find.text('Tutar girin'), findsOneWidget);
    expect(find.text('Kategori seçin'), findsWidgets);

    await tester.enterText(find.byKey(const Key('amountField')), '1.250,50');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🛒  Market').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('noteField')), 'Haftalık alışveriş');
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();

    expect(find.byType(AddTransactionScreen), findsNothing);
    expect(find.text('Market'), findsOneWidget);
    expect(find.textContaining('Haftalık alışveriş'), findsOneWidget);
    expect(find.text('-₺1.250,50'), findsOneWidget);

    expect(_box.length, 1);
    final saved = _box.values.single;
    expect(saved.amount, 1250.5);
    expect(saved.isIncome, isFalse);
    expect(saved.categoryId, 'market');
  });

  testWidgets('Gelir/Gider değiştirildiğinde dropdown hata vermez ve seçim sıfırlanır', (tester) async {
    await tester.pumpWidget(_app(const AddTransactionScreen()));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🏠  Kira').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gelir'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('🏠  Kira'), findsNothing);
    expect(find.text('Kategori seçin'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('💰  Maaş'), findsWidgets);
    expect(find.text('🛒  Market'), findsNothing);
  });

  testWidgets('Silinmiş kategoriye ait işlem düzenlenirken assertion oluşmaz', (tester) async {
    final orphan = Transaction(amount: 10, categoryId: 'silinmis', date: DateTime.now(), isIncome: false);
    await tester.pumpWidget(_app(AddTransactionScreen(transaction: orphan)));
    expect(tester.takeException(), isNull);
    expect(find.text('Kategori seçin'), findsOneWidget);
  });

  testWidgets('Genel Bakış toplamları ekleme, düzenleme ve silmeyle güncellenir', (tester) async {
    final now = DateTime.now();
    late WidgetRef ref;
    await tester.pumpWidget(_app(Consumer(builder: (context, r, _) {
      ref = r;
      return const DashboardScreen();
    })));
    expect(find.text('₺0,00'), findsNWidgets(3));

    final notifier = ref.read(transactionsProvider.notifier);
    final salary = Transaction(amount: 42500, categoryId: 'maas', date: now, isIncome: true);
    final market = Transaction(amount: 850, categoryId: 'market', date: now, isIncome: false);
    await notifier.add(salary);
    await notifier.add(market);
    await notifier.add(Transaction(amount: 5000, categoryId: 'kira', date: DateTime(now.year - 1, now.month, 1), isIncome: false));
    await tester.pump();
    expect(find.text('₺42.500,00'), findsOneWidget);
    expect(find.text('₺850,00'), findsOneWidget);
    expect(find.text('₺41.650,00'), findsOneWidget);

    await notifier.edit(Transaction(id: market.id, amount: 1000, categoryId: 'market', date: now, isIncome: false, createdAt: market.createdAt));
    await tester.pump();
    expect(find.text('₺41.500,00'), findsOneWidget);
    expect(_box.get(market.id)!.amount, 1000);

    await notifier.remove(salary.id);
    await tester.pump();
    expect(find.text('-₺1.000,00'), findsOneWidget);
    expect(_box.length, 2);
  });
}
