import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'constants/hive_boxes.dart';
import 'models/account.dart';
import 'models/card_statement.dart';
import 'models/category.dart';
import 'models/credit_card.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'utils/default_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(AccountAdapter());
  Hive.registerAdapter(CreditCardAdapter());
  Hive.registerAdapter(CardStatementAdapter());
  await Hive.openBox<Category>(HiveBoxes.categories);
  await Hive.openBox<Account>(HiveBoxes.accounts);
  await Hive.openBox<CreditCard>(HiveBoxes.creditCards);
  await Hive.openBox<CardStatement>(HiveBoxes.statements);

  final categoryBox = Hive.box<Category>(HiveBoxes.categories);
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
      home: const HomeScreen(),
    );
  }
}
