import 'package:ev_butcem/main.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ev_butcem/models/category.dart';
import 'package:ev_butcem/models/transaction.dart';
import 'package:ev_butcem/providers/budget_providers.dart';
import 'package:ev_butcem/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _SeedCategories extends CategoriesNotifier {
  _SeedCategories(this.items);

  final List<Category> items;

  @override
  List<Category> build() => items;
}

class _SeedTransactions extends TransactionsNotifier {
  _SeedTransactions(this.items);

  final List<Transaction> items;

  @override
  List<Transaction> build() => items;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Widget buildApp({
    List<Category> categories = const [],
    List<Transaction> transactions = const [],
  }) {
    return ProviderScope(
      overrides: [
        categoriesProvider.overrideWith(() => _SeedCategories(categories)),
        transactionsProvider.overrideWith(
          () => _SeedTransactions(transactions),
        ),
      ],
      child: const EvButcemApp(),
    );
  }

  testWidgets('home screen shows the existing navigation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp());
    await settle(tester);

    expect(find.text('Ev Bütçem'), findsOneWidget);
    expect(find.text('Genel Bakış'), findsOneWidget);
    expect(find.text('İşlemler'), findsOneWidget);
    expect(find.text('Hesaplar'), findsOneWidget);
    expect(find.text('Diğer'), findsOneWidget);
  });

  testWidgets('reports screen shows net balance and category chart', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final bills = Category(
      id: 'bills',
      name: 'Faturalar',
      icon: '💡',
      colorValue: 0xFFF59E0B,
      isIncome: false,
    );
    final salary = Category(
      id: 'salary',
      name: 'Maaş',
      icon: '💰',
      colorValue: 0xFF16A34A,
      isIncome: true,
    );

    await tester.pumpWidget(
      buildApp(
        categories: [bills, salary],
        transactions: [
          Transaction(
            amount: 1234.56,
            categoryId: bills.id,
            date: DateTime(now.year, now.month, 2),
            isIncome: false,
          ),
          Transaction(
            amount: 200,
            categoryId: salary.id,
            date: DateTime(now.year, now.month, 3),
            isIncome: true,
          ),
        ],
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Diğer'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Raporlar'));
    await settle(tester);

    expect(find.text('Net durum'), findsOneWidget);
    expect(find.text('Gelir − gider'), findsOneWidget);
    expect(find.text(formatTry(200 - 1234.56)), findsOneWidget);
    expect(find.text('Aylık gelir-gider özeti'), findsOneWidget);
    expect(find.text('Toplam gelir'), findsOneWidget);
    expect(find.text('Toplam gider'), findsOneWidget);
    expect(find.text(formatTry(200)), findsWidgets);
    expect(find.text(formatTry(1234.56)), findsWidgets);
    expect(find.text('Kategori dağılımı'), findsOneWidget);
    expect(find.text('Faturalar'), findsOneWidget);
    expect(find.text('%100'), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);

    final netDecoration = tester
        .widget<Container>(find.byKey(const Key('net-durum')))
        .decoration! as BoxDecoration;
    final netGradient = netDecoration.gradient! as LinearGradient;
    expect(netGradient.colors.first, const Color(0xFFDC2626));

    await tester.tap(find.text('Gelirler'));
    await settle(tester);
    expect(find.text('Maaş'), findsOneWidget);
    expect(find.text('Bu ay için gelir kaydı yok'), findsNothing);

    await tester.tap(find.byKey(const Key('previous-month')));
    await settle(tester);
    expect(find.text('Bu ay için gelir kaydı yok'), findsOneWidget);
    expect(find.byType(PieChart), findsNothing);
  });

  testWidgets('positive net durum card is green', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final salary = Category(
      id: 'salary',
      name: 'Maaş',
      icon: '💰',
      colorValue: 0xFF16A34A,
      isIncome: true,
    );

    await tester.pumpWidget(
      buildApp(
        categories: [salary],
        transactions: [
          Transaction(
            amount: 500,
            categoryId: salary.id,
            date: DateTime(now.year, now.month, 1),
            isIncome: true,
          ),
        ],
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Diğer'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ListTile, 'Raporlar'));
    await settle(tester);

    expect(find.text(formatTry(500)), findsWidgets);
    final netDecoration = tester
        .widget<Container>(find.byKey(const Key('net-durum')))
        .decoration! as BoxDecoration;
    final netGradient = netDecoration.gradient! as LinearGradient;
    expect(netGradient.colors.first, const Color(0xFF16A34A));
  });
}
