import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/budget_limit.dart';
import 'models/category.dart';
import 'models/transaction.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'utils/default_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(BudgetLimitAdapter());
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<BudgetLimit>('budget_limits');

  final categoryBox = Hive.box<Category>('categories');
  if (categoryBox.isEmpty) {
    for (final category in DefaultData.defaultCategories) {
      await categoryBox.put(category.id, category);
    }
  }

  runApp(const ProviderScope(child: EvButcemApp()));
}

class EvButcemApp extends ConsumerWidget {
  const EvButcemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Ev Bütçem',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
