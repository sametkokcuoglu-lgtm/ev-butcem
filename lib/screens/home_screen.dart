import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ui_provider.dart';
import '../theme/app_theme.dart';
import 'budget_screen.dart';
import 'dashboard_screen.dart';
import 'more_screen.dart';
import 'reports_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabProvider);
    final finance = FinanceColors.of(context);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          DashboardScreen(),
          TransactionsScreen(),
          ReportsScreen(),
          BudgetScreen(),
          MoreScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: finance.line)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => ref.read(homeTabProvider.notifier).select(i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Özet'),
            NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'İşlemler'),
            NavigationDestination(icon: Icon(Icons.pie_chart_outline_rounded), label: 'Raporlar'),
            NavigationDestination(icon: Icon(Icons.savings_rounded), label: 'Bütçe'),
            NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Diğer'),
          ],
        ),
      ),
    );
  }
}
