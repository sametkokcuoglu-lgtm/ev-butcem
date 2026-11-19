import 'package:flutter/material.dart';

import '../widgets/content_frame.dart';
import '../widgets/empty_state.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hesaplar & Kartlar')),
      body: const ContentFrame(
        child: Center(
          child: EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Henüz hesap eklenmedi',
            message: 'Banka hesabı veya kartlarını eklediğinde bakiyelerini burada göreceksin.',
          ),
        ),
      ),
    );
  }
}
