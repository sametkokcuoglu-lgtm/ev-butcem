import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// "İşlem silinsin mi?" onayı. Kullanıcı Sil'e basarsa `true` döner.
Future<bool> confirmTransactionDelete(
  BuildContext context,
  Transaction transaction,
  Category? category,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('İşlem silinsin mi?'),
      content: Text(
        '${category?.name ?? 'Kategorisiz'} · ${AppFormatters.money(transaction.amount)} '
        'tutarındaki işlem silinecek.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
        FilledButton(
          key: const Key('confirmDeleteButton'),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.expenseColor),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Sil'),
        ),
      ],
    ),
  );
  return ok == true;
}

/// İşlemi siler ve "Geri Al" düğmeli bir bildirim gösterir.
///
/// Bildirim uygulama genelindeki [ScaffoldMessenger] üzerinden gösterildiği
/// için düzenleme ekranı kapansa da alttaki ekranda görünmeye devam eder.
/// Notifier önceden alınır; böylece çağıran ekran kapansa bile geri alma çalışır.
Future<void> deleteTransactionWithUndo(
  BuildContext context,
  WidgetRef ref,
  Transaction transaction,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(transactionsProvider.notifier);
  final removed = await notifier.remove(transaction.id) ?? transaction;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('İşlem silindi'),
        duration: const Duration(seconds: 5),
        persist: false, // Geri Al düğmesi olsa da süre dolunca kapansın.
        action: SnackBarAction(
          label: 'Geri Al',
          onPressed: () => notifier.restore(removed),
        ),
      ),
    );
}
