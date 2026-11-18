import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'reports_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diğer')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Iconsax.chart_2),
            title: const Text('Raporlar'),
            trailing: const Icon(Iconsax.arrow_right_3),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const ReportsScreen(),
                ),
              );
            },
          ),
          const ListTile(
            leading: Icon(Iconsax.calendar_1),
            title: Text('Finans Takvimi'),
          ),
          const ListTile(
            leading: Icon(Iconsax.setting_2),
            title: Text('Ayarlar'),
          ),
        ],
      ),
    );
  }
}
