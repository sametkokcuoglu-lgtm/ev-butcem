import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İşlemler')),
      body: const Center(child: Text('Henüz işlem yok')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Iconsax.add),
        label: const Text('Yeni İşlem'),
      ),
    );
  }
}