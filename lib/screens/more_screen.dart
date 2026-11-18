import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diğer')),
      body: ListView(
        children: const [
          ListTile(leading: Icon(Iconsax.chart_2), title: Text('Raporlar')),
          ListTile(leading: Icon(Iconsax.calendar_1), title: Text('Finans Takvimi')),
          ListTile(leading: Icon(Iconsax.setting_2), title: Text('Ayarlar')),
        ],
      ),
    );
  }
}