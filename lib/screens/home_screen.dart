import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'accounts_screen.dart';
import 'more_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Iconsax.home), label: 'Genel Bakış'),
          NavigationDestination(icon: Icon(Iconsax.receipt_item), label: 'İşlemler'),
          NavigationDestination(icon: Icon(Iconsax.wallet_2), label: 'Hesaplar'),
          NavigationDestination(icon: Icon(Iconsax.more), label: 'Diğer'),
        ],
      ),
    );
  }
}