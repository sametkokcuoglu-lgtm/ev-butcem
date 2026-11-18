import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'finance_calendar_screen.dart';
import 'upcoming_payments_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diğer')),
      body: ListView(
        children: [
          const ListTile(
              leading: Icon(Iconsax.chart_2), title: Text('Raporlar')),
          ListTile(
            leading: const Icon(Iconsax.money_time),
            title: const Text('Yaklaşan Ödemeler'),
            trailing: const Icon(Iconsax.arrow_right_3),
            onTap: () => _open(context, const UpcomingPaymentsScreen()),
          ),
          ListTile(
            leading: const Icon(Iconsax.calendar_1),
            title: const Text('Finans Takvimi'),
            trailing: const Icon(Iconsax.arrow_right_3),
            onTap: () => _open(context, const FinanceCalendarScreen()),
          ),
          const ListTile(
              leading: Icon(Iconsax.setting_2), title: Text('Ayarlar')),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
