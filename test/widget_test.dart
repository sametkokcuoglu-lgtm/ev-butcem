import 'dart:io';

import 'package:ev_butcem/constants/hive_boxes.dart';
import 'package:ev_butcem/models/account.dart';
import 'package:ev_butcem/models/card_statement.dart';
import 'package:ev_butcem/models/credit_card.dart';
import 'package:ev_butcem/screens/accounts_screen.dart';
import 'package:ev_butcem/screens/home_screen.dart';
import 'package:ev_butcem/widgets/credit_card_list_card.dart';
import 'package:ev_butcem/widgets/statement_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('ev_butcem_widget');
    Hive.init(dir.path);
    Hive.registerAdapter(AccountAdapter());
    Hive.registerAdapter(CreditCardAdapter());
    Hive.registerAdapter(CardStatementAdapter());
    await Hive.openBox<Account>(HiveBoxes.accounts);
    await Hive.openBox<CreditCard>(HiveBoxes.creditCards);
    await Hive.openBox<CardStatement>(HiveBoxes.statements);
  });

  tearDown(() async {
    await Hive.box<Account>(HiveBoxes.accounts).clear();
    await Hive.box<CreditCard>(HiveBoxes.creditCards).clear();
    await Hive.box<CardStatement>(HiveBoxes.statements).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget app(Widget home) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        ),
        home: home,
      ),
    );
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  testWidgets('home shell reaches the accounts screen', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(app(const HomeScreen()));
    await settle(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Hesaplar'),
      ),
    );
    await settle(tester);

    expect(find.text('Hesaplar & Kartlar'), findsOneWidget);
    expect(find.text('Henüz banka hesabı eklenmedi'), findsOneWidget);

    await tester.tap(find.text('Kartlar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Henüz kredi kartı eklenmedi'), findsOneWidget);
  });

  testWidgets('account form requires a name, bank and balance', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(app(const AccountsScreen()));
    await settle(tester);

    await tester.tap(find.text('Hesap Ekle'));
    await settle(tester);
    await tester.tap(find.text('Kaydet'));
    await settle(tester);

    expect(find.text('Hesap adı gerekli'), findsOneWidget);
    expect(find.text('Banka adı gerekli'), findsOneWidget);
    expect(find.text('Bakiye gerekli'), findsOneWidget);
  });

  testWidgets('card form requires limit, debt and payment days',
      (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(app(const AccountsScreen()));
    await settle(tester);

    await tester.tap(find.text('Kartlar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Kart Ekle'));
    await settle(tester);
    await tester.tap(find.text('Kaydet'));
    await settle(tester);

    expect(find.text('Kart adı gerekli'), findsOneWidget);
    expect(find.text('Toplam limit gerekli'), findsOneWidget);
    expect(find.text('Güncel borç gerekli'), findsOneWidget);
    expect(find.text('Son ödeme günü gerekli'), findsOneWidget);
  });

  testWidgets('highlights an overdue card and a card due soon', (tester) async {
    useTallSurface(tester);
    final overdue = CreditCard(
      id: 'overdue',
      name: 'Geciken',
      bankName: 'Akbank',
      limit: 5000,
      currentDebt: 1000,
      statementDay: 1,
      dueDay: 10,
      createdAt: DateTime(2026, 1, 1),
    );
    final soon = CreditCard(
      id: 'soon',
      name: 'Yaklaşan',
      bankName: 'Akbank',
      limit: 5000,
      currentDebt: 0,
      statementDay: 1,
      dueDay: 15,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        ),
        home: Scaffold(
          body: ListView(
            children: [
              CreditCardListCard(
                card: overdue,
                now: DateTime(2026, 11, 12),
                onEdit: () {},
                onDelete: () {},
              ),
              CreditCardListCard(
                card: soon,
                now: DateTime(2026, 11, 12),
                onEdit: () {},
                onDelete: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('2 gün gecikti'), findsOneWidget);
    expect(find.text('Sonraki son ödeme: 10 Ara 2026'), findsOneWidget);
    expect(find.text('3 gün kaldı'), findsOneWidget);
    expect(find.text('Son ödeme: 15 Kas 2026'), findsOneWidget);
    expect(find.text('%20'), findsOneWidget);
    expect(find.text('₺4.000,00'), findsOneWidget);
  });

  testWidgets('statement tile shows unpaid and paid states', (
    tester,
  ) async {
    final unpaid = CardStatement(
      id: 'u',
      creditCardId: 'c',
      periodDate: DateTime(2026, 11, 15),
      dueDate: DateTime(2026, 11, 10),
      totalAmount: 2000,
      minimumPayment: 200,
      paidAmount: 0,
      createdAt: DateTime(2026, 11, 15),
    );
    final paid = CardStatement(
      id: 'p',
      creditCardId: 'c',
      periodDate: DateTime(2026, 10, 15),
      dueDate: DateTime(2026, 10, 25),
      totalAmount: 1500,
      paidAmount: 1500,
      createdAt: DateTime(2026, 10, 15),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              StatementTile(
                statement: unpaid,
                now: DateTime(2026, 11, 12),
                onEdit: () {},
                onDelete: () {},
                onMarkPaid: () {},
              ),
              StatementTile(
                statement: paid,
                now: DateTime(2026, 11, 12),
                onEdit: () {},
                onDelete: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Ödenmedi'), findsOneWidget);
    expect(find.textContaining('2 gün gecikti'), findsOneWidget);
    expect(find.text('Ödendi olarak işaretle'), findsOneWidget);
    expect(find.text('Ödendi'), findsWidgets);
    expect(find.textContaining('Kesim 15 Kas 2026'), findsOneWidget);
  });
}
