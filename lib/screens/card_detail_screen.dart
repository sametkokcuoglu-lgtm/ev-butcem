import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../models/card_statement.dart';
import '../models/credit_card.dart';
import '../providers/statement_actions.dart';
import '../providers/wallet_providers.dart';
import '../theme/app_theme.dart';
import '../utils/account_style.dart';
import '../utils/money.dart';
import '../widgets/delete_dialog.dart';
import '../widgets/statement_tile.dart';
import 'credit_card_form_screen.dart';
import 'statement_form_screen.dart';

class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(creditCardsProvider);
    CreditCard? card;
    for (final candidate in cards) {
      if (candidate.id == cardId) {
        card = candidate;
        break;
      }
    }
    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kart')),
        body: const Center(child: Text('Kart bulunamadı')),
      );
    }
    final current = card;
    final statements = ref
        .watch(statementsProvider)
        .where((statement) => statement.creditCardId == cardId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(current.name),
        actions: [
          IconButton(
            tooltip: 'Düzenle',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CreditCardFormScreen(card: current),
                ),
              );
            },
            icon: const Icon(Iconsax.edit_2),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'statement-fab',
        onPressed: () => _openForm(context, current),
        icon: const Icon(Iconsax.add),
        label: const Text('Ekstre Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _CardSummary(card: current),
          const SizedBox(height: 20),
          const Text(
            'Ekstreler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (statements.isEmpty)
            Text(
              'Henüz ekstre eklenmedi',
              key: const Key('empty-statements'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final statement in statements)
              StatementTile(
                key: ValueKey('statement-${statement.id}'),
                statement: statement,
                onEdit: () => _openForm(context, current, statement),
                onDelete: () => _delete(context, ref, statement),
                onMarkPaid: () => StatementActions(ref).markPaid(statement),
              ),
        ],
      ),
    );
  }

  void _openForm(
    BuildContext context,
    CreditCard card, [
    CardStatement? statement,
  ]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatementFormScreen(card: card, statement: statement),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CardStatement statement,
  ) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Ekstreyi sil',
      message:
          '${formatTrDate(statement.periodDate)} tarihli ekstre silinsin mi? Ödenen tutar karta geri yazılır.',
    );
    if (!confirmed || !context.mounted) return;
    await StatementActions(ref).delete(statement);
  }
}

class _CardSummary extends StatelessWidget {
  const _CardSummary({required this.card});

  final CreditCard card;

  @override
  Widget build(BuildContext context) {
    final accent = parseHexColor(card.color);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.bankName, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(label: 'Limit', value: formatMoney(card.limit)),
              ),
              Expanded(
                child: _Metric(
                  label: 'Borç',
                  value: formatMoney(card.currentDebt),
                  color: card.currentDebt > 0 ? AppTheme.expenseColor : null,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Kullanılabilir',
                  value: formatMoney(card.availableLimit),
                  color: card.availableLimit < 0
                      ? AppTheme.expenseColor
                      : AppTheme.incomeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: card.usageRatio,
              minHeight: 8,
              backgroundColor: accent.withValues(alpha: 0.12),
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }
}
