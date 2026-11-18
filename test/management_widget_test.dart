import 'package:ev_butcem/models/transaction.dart';
import 'package:ev_butcem/screens/add_transaction_screen.dart';
import 'package:ev_butcem/screens/categories_screen.dart';
import 'package:ev_butcem/screens/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'test_helpers.dart';

void main() {
  late TestBoxes boxes;

  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
    registerTestAdapters();
  });
  setUp(() async => boxes = await TestBoxes.open());
  tearDown(() async => boxes.close());

  Future<Transaction> seed(double amount, String categoryId,
      {bool income = false, DateTime? date, String? note}) async {
    final t = Transaction(
      amount: amount,
      categoryId: categoryId,
      date: date ?? DateUtils.dateOnly(DateTime.now()),
      isIncome: income,
      note: note,
    );
    await boxes.transactions.put(t.id, t);
    return t;
  }

  group('İşlem silme', () {
    testWidgets('Menüden silinen işlem Geri Al ile geri gelir', (tester) async {
      final t = await seed(850, 'market', note: 'Haftalık');
      await tester.pumpWidget(boxes.app(const TransactionsScreen()));
      expect(find.text('-₺850,00'), findsOneWidget);

      await tester.longPress(find.text('Market'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDeleteButton')));
      await tester.pumpAndSettle();

      expect(find.text('-₺850,00'), findsNothing);
      expect(boxes.transactions.isEmpty, isTrue);
      expect(find.text('İşlem silindi'), findsOneWidget);

      await tester.tap(find.text('Geri Al'));
      await tester.pumpAndSettle();
      expect(find.text('-₺850,00'), findsOneWidget);
      final back = boxes.transactions.get(t.id)!;
      expect(back.createdAt, t.createdAt);
      expect(back.note, 'Haftalık');
    });

    testWidgets('Kaydırarak silmede onay istenir; Vazgeç satırı korur', (tester) async {
      await seed(120, 'kira');
      await tester.pumpWidget(boxes.app(const TransactionsScreen()));

      await tester.drag(find.text('Kira'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('İşlem silinsin mi?'), findsOneWidget);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(find.text('Kira'), findsOneWidget);
      expect(boxes.transactions.length, 1);

      await tester.drag(find.text('Kira'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDeleteButton')));
      await tester.pumpAndSettle();
      expect(find.text('Kira'), findsNothing);
      expect(boxes.transactions.isEmpty, isTrue);
      expect(find.text('Geri Al'), findsOneWidget);
    });

    testWidgets('Düzenleme ekranından silinir ve listede geri alınabilir', (tester) async {
      final t = await seed(42500, 'maas', income: true);
      await tester.pumpWidget(boxes.app(const TransactionsScreen()));
      await tester.tap(find.text('Maaş'));
      await tester.pumpAndSettle();
      expect(find.byType(AddTransactionScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('deleteTransactionButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmDeleteButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AddTransactionScreen), findsNothing);
      expect(boxes.transactions.isEmpty, isTrue);
      await tester.tap(find.text('Geri Al'));
      await tester.pumpAndSettle();
      expect(boxes.transactions.get(t.id), isNotNull);
      expect(find.text('+₺42.500,00'), findsOneWidget);
    });

    testWidgets('Düzenleme id ve createdAt korur, updatedAt yenilenir', (tester) async {
      final t = Transaction(
        amount: 100,
        categoryId: 'market',
        date: DateUtils.dateOnly(DateTime.now()),
        isIncome: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      await boxes.transactions.put(t.id, t);
      await tester.pumpWidget(boxes.app(const TransactionsScreen()));
      await tester.tap(find.text('Market'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('amountField')), '250');
      await tester.tap(find.byKey(const Key('saveButton')));
      await tester.pumpAndSettle();

      final saved = boxes.transactions.get(t.id)!;
      expect(boxes.transactions.length, 1);
      expect(saved.amount, 250);
      expect(saved.createdAt, DateTime(2026, 1, 1));
      expect(saved.updatedAt.isAfter(DateTime(2026, 1, 1)), isTrue);
    });
  });

  group('İşlem listesi', () {
    testWidgets('Kategorisi olmayan işlem "Kategorisiz" görünür', (tester) async {
      await seed(10, 'silinmis');
      await tester.pumpWidget(boxes.app(const TransactionsScreen()));
      expect(find.text('Kategorisiz'), findsOneWidget);
      expect(find.text('❔'), findsOneWidget);
    });

    testWidgets('Tür ve ay filtreleri çalışır', (tester) async {
      final now = DateTime.now();
      await seed(42500, 'maas', income: true);
      await seed(850, 'market');
      await seed(5000, 'kira', date: DateTime(now.year, now.month - 1, 10));
      await tester.pumpWidget(boxes.app(const TransactionsScreen()));
      expect(find.text('3 işlem · Gelir ₺42.500,00 · Gider ₺5.850,00'), findsOneWidget);

      await tester.tap(find.descendant(of: find.byKey(const Key('typeFilter')), matching: find.text('Gider')));
      await tester.pumpAndSettle();
      expect(find.text('Maaş'), findsNothing);
      expect(find.text('Market'), findsOneWidget);
      expect(find.text('Kira'), findsOneWidget);

      // Bu ay
      await tester.tap(find.byKey(const Key('monthFilterButton')));
      await tester.pumpAndSettle();
      expect(find.text('Kira'), findsNothing);
      expect(find.text('Market'), findsOneWidget);

      // Önceki ay
      await tester.tap(find.byKey(const Key('prevMonthButton')));
      await tester.pumpAndSettle();
      expect(find.text('Kira'), findsOneWidget);
      expect(find.text('Market'), findsNothing);

      await tester.tap(find.byKey(const Key('prevMonthButton')));
      await tester.pumpAndSettle();
      expect(find.text('Bu filtreye uygun işlem yok'), findsOneWidget);
    });
  });

  group('Kategoriler ekranı', () {
    testWidgets('Yeni kategori eklenir; aynı ad tekrar eklenemez', (tester) async {
      await tester.pumpWidget(boxes.app(const CategoriesScreen()));
      expect(find.text('Market'), findsOneWidget);
      expect(find.text('Maaş'), findsNothing); // Gider sekmesi açık

      await tester.tap(find.byKey(const Key('addCategoryButton')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('categoryNameField')), '  MARKET ');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();
      expect(find.textContaining('zaten var'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('categoryNameField')), 'Aidat');
      await tester.tap(find.byKey(const ValueKey('icon-🏢')));
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.text('Aidat'), findsOneWidget);
      final saved = boxes.categories.values.firstWhere((c) => c.name == 'Aidat');
      expect(saved.icon, '🏢');
      expect(saved.isIncome, isFalse);
    });

    testWidgets('Kullanılan kategori silinirken işlemler taşınır', (tester) async {
      await seed(850, 'market');
      await seed(900, 'market');
      await tester.pumpWidget(boxes.app(const CategoriesScreen()));
      expect(find.text('2 işlem · Varsayılan'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('categoryMenu-market')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();
      expect(find.text('İşlemler taşınsın'), findsOneWidget);

      await tester.tap(find.byKey(const Key('moveTargetDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🏠  Kira').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('moveAndDeleteButton')));
      await tester.pumpAndSettle();

      expect(boxes.categories.get('market'), isNull);
      expect(boxes.transactions.values.every((t) => t.categoryId == 'kira'), isTrue);
      expect(find.text('Kategori silindi, 2 işlem taşındı'), findsOneWidget);
      expect(find.text('2 işlem · Varsayılan'), findsOneWidget); // Kira satırı
    });

    testWidgets('Türün son kategorisi silinemez', (tester) async {
      await tester.pumpWidget(boxes.app(const CategoriesScreen()));
      await tester.tap(find.text('Gelir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('categoryMenu-maas')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();
      expect(find.text('Kategori silinemez'), findsOneWidget);
      expect(boxes.categories.get('maas'), isNotNull);
    });

    testWidgets('Formdan eklenen kategori dropdown\'da hemen seçili gelir', (tester) async {
      await tester.pumpWidget(boxes.app(const AddTransactionScreen()));
      await tester.tap(find.byKey(const Key('newCategoryButton')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('categoryNameField')), 'Aidat');
      await tester.tap(find.byKey(const Key('saveCategoryButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AddTransactionScreen), findsOneWidget);
      expect(find.text('📌  Aidat'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
