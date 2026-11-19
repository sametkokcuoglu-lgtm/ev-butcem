import 'package:ev_butcem/models/transaction.dart';
import 'package:ev_butcem/screens/accounts_screen.dart';
import 'package:ev_butcem/screens/add_transaction_screen.dart';
import 'package:ev_butcem/screens/bills_screen.dart';
import 'package:ev_butcem/screens/categories_screen.dart';
import 'package:ev_butcem/screens/home_screen.dart';
import 'package:ev_butcem/screens/settings_screen.dart';
import 'package:ev_butcem/screens/statements_screen.dart';
import 'package:ev_butcem/theme/app_theme.dart';
import 'package:ev_butcem/utils/default_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
    registerTestAdapters();
  });

  testWidgets('dar ve geniş ekranda, açık ve koyu temada taşma yok', (tester) async {
    final reports = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      reports.add(details);
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
    final boxes = await TestBoxes.open(categories: DefaultData.defaultCategories);
    addTearDown(boxes.close);

    final now = DateTime.now();
    Future<void> add(
      double amount,
      String categoryId, {
      bool income = false,
      int monthsAgo = 0,
      int day = 3,
      String? note,
    }) async {
      final date = DateTime(now.year, now.month - monthsAgo, day);
      final transaction = Transaction(
        amount: amount,
        categoryId: categoryId,
        date: date,
        isIncome: income,
        note: note,
      );
      await boxes.transactions.put(transaction.id, transaction);
    }

    await add(42500, 'default_maas', income: true, day: 1, note: 'Maaş');
    await add(18000, 'default_kira', day: 2);
    await add(1860.5, 'default_market', day: now.day, note: 'Haftalık');
    await add(420, 'default_yemek', monthsAgo: 0, day: 8);
    await add(640, 'default_faturalar', monthsAgo: 1, day: 12);
    await add(39000, 'default_maas', income: true, monthsAgo: 1, day: 1);
    await add(2100, 'default_market', monthsAgo: 2, day: 6);

    const screens = <Widget>[
      HomeScreen(),
      BillsScreen(),
      StatementsScreen(),
      AddTransactionScreen(),
      AddTransactionScreen(initialIsIncome: true),
      SettingsScreen(),
      AccountsScreen(),
      CategoriesScreen(),
    ];

    for (final size in const [Size(320, 640), Size(390, 844), Size(1024, 800)]) {
      for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
        for (final screen in screens) {
          await tester.binding.setSurfaceSize(size);
          tester.view.devicePixelRatio = 1;
          await tester.pumpWidget(
            ProviderScope(
              overrides: boxes.overrides,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: mode,
                locale: const Locale('tr', 'TR'),
                supportedLocales: const [Locale('tr', 'TR')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: screen,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          final exception = tester.takeException();
          if (exception != null) {
            final text = reports.map((d) => d.toString()).join('\n---\n');
            fail('${screen.runtimeType} $size $mode\n$text');
          }
        }
      }
    }

    await tester.binding.setSurfaceSize(null);
  });
}
