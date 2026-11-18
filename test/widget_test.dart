import 'package:ev_butcem/data/payment_stores.dart';
import 'package:ev_butcem/models/planned_payment.dart';
import 'package:ev_butcem/providers/finance_providers.dart';
import 'package:ev_butcem/screens/dashboard_screen.dart';
import 'package:ev_butcem/screens/finance_calendar_screen.dart';
import 'package:ev_butcem/screens/more_screen.dart';
import 'package:ev_butcem/screens/payment_form_screen.dart';
import 'package:ev_butcem/screens/upcoming_payments_screen.dart';
import 'package:ev_butcem/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
  });

  final clock = DateTime(2026, 11, 18);

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    List<Override> overrides = const [],
    Size size = const Size(400, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWith((ref) => () => clock),
          ...overrides,
        ],
        child: MaterialApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('genel bakış yaklaşan ödemeleri ve takvimi gösterir',
      (tester) async {
    final store = MemoryPlannedPaymentStore([
      PlannedPayment(
          id: 'a',
          title: 'Geciken',
          amount: 10,
          dueDate: DateTime(2026, 11, 1)),
      PlannedPayment(
          id: 'b',
          title: 'Bugünkü',
          amount: 20,
          dueDate: DateTime(2026, 11, 18)),
      PlannedPayment(
          id: 'c',
          title: 'Haftalık',
          amount: 30,
          dueDate: DateTime(2026, 11, 20)),
      PlannedPayment(
          id: 'd', title: 'Uzak', amount: 40, dueDate: DateTime(2026, 12, 1)),
    ]);

    await pump(
      tester,
      const DashboardScreen(),
      overrides: [plannedPaymentStoreProvider.overrideWith((ref) => store)],
    );

    expect(find.text('Kasım 2026'), findsOneWidget);
    expect(find.text('Yaklaşan Ödemeler'), findsOneWidget);
    expect(find.text('Geciken'), findsOneWidget);
    expect(find.text('Bugünkü'), findsOneWidget);
    expect(find.text('Haftalık'), findsOneWidget);
    expect(find.text('Uzak'), findsNothing);
    expect(find.text('Tümünü gör'), findsOneWidget);

    await tester.tap(find.byTooltip('Finans Takvimi'));
    await tester.pumpAndSettle();
    expect(find.text('Toplam'), findsOneWidget);
    expect(find.text('Kalan'), findsOneWidget);
  });

  testWidgets(
      'yaklaşan ödemeler gruplanır ve ödendi işareti gecikmişi kaldırır',
      (tester) async {
    final store = MemoryPlannedPaymentStore([
      PlannedPayment(
        id: 'rent',
        title: 'Kira',
        amount: 15000,
        dueDate: DateTime(2026, 11, 10),
        recurrence: PaymentRecurrence.monthly,
      ),
      PlannedPayment(
          id: 'net',
          title: 'İnternet',
          amount: 400,
          dueDate: DateTime(2026, 11, 18)),
      PlannedPayment(
          id: 'water',
          title: 'Su',
          amount: 180,
          dueDate: DateTime(2026, 11, 20)),
    ]);

    await pump(
      tester,
      const UpcomingPaymentsScreen(),
      overrides: [plannedPaymentStoreProvider.overrideWith((ref) => store)],
      size: const Size(400, 1400),
    );

    expect(find.text('Gecikmiş'), findsOneWidget);
    expect(find.text('Bugün'), findsWidgets);
    expect(find.text('Bu hafta'), findsOneWidget);
    expect(find.text('Daha sonra'), findsOneWidget);
    expect(find.text(formatTry(15000)), findsWidgets);

    await tester
        .tap(find.byKey(const ValueKey('toggle-planned:rent:2026-11-10')));
    await tester.pumpAndSettle();

    expect(find.text('Gecikmiş'), findsNothing);
    expect(find.text('Kira'), findsOneWidget);
    expect(
        store.load().singleWhere((item) => item.id == 'rent').isPaid, isTrue);

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('diğer menü takvime ve ödeme listesine gider', (tester) async {
    await pump(tester, const MoreScreen());

    await tester.tap(find.text('Yaklaşan Ödemeler'));
    await tester.pumpAndSettle();
    expect(find.text('Yaklaşan ödeme yok'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Finans Takvimi'));
    await tester.pumpAndSettle();
    expect(find.text('Kasım 2026'), findsOneWidget);
    expect(find.text('Bu günde kayıt yok'), findsOneWidget);

    await tester.tap(find.byTooltip('Sonraki ay'));
    await tester.pumpAndSettle();
    expect(find.text('Aralık 2026'), findsOneWidget);
  });

  testWidgets('takvim günündeki ödemeyi listeler', (tester) async {
    final store = MemoryPlannedPaymentStore([
      PlannedPayment(
          id: 'rent',
          title: 'Kira',
          amount: 15000,
          dueDate: DateTime(2026, 11, 18)),
    ]);

    await pump(
      tester,
      const FinanceCalendarScreen(),
      overrides: [plannedPaymentStoreProvider.overrideWith((ref) => store)],
    );

    expect(find.text('18 Kasım 2026'), findsOneWidget);
    expect(find.text('Kira'), findsOneWidget);
    expect(find.text('Ödenen'), findsOneWidget);
  });

  testWidgets('ödeme formu doğrular ve kaydeder', (tester) async {
    final store = MemoryPlannedPaymentStore();
    await pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaymentFormScreen()),
            );
          },
          child: const Text('Formu aç'),
        ),
      ),
      overrides: [plannedPaymentStoreProvider.overrideWith((ref) => store)],
      size: const Size(400, 1600),
    );

    await tester.tap(find.text('Formu aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pump();
    expect(find.text('Başlık gerekli'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Aidat');
    await tester.enterText(find.byType(TextFormField).at(1), '1.250,50');
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(store.load().single.title, 'Aidat');
    expect(store.load().single.amount, 1250.50);
    expect(find.text('Formu aç'), findsOneWidget);
  });
}
