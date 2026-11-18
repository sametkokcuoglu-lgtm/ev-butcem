import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'categories_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diğer')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Iconsax.category),
            title: const Text('Kategoriler'),
            subtitle: const Text('Gelir ve gider kategorilerini yönet'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
          ),
          const ListTile(leading: Icon(Iconsax.chart_2), title: Text('Raporlar')),
          const ListTile(leading: Icon(Iconsax.calendar_1), title: Text('Finans Takvimi')),
          const ListTile(leading: Icon(Iconsax.setting_2), title: Text('Ayarlar')),
        ],
      ),
    );
  }
}
