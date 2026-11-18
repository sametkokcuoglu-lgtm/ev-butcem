import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../models/account.dart';
import '../models/card_statement.dart';
import '../models/credit_card.dart';
import '../providers/statement_actions.dart';
import '../providers/wallet_providers.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';
import '../utils/wallet_totals.dart';
import '../widgets/account_list_card.dart';
import '../widgets/credit_card_list_card.dart';
import '../widgets/delete_dialog.dart';
import '../widgets/statement_tile.dart';
import 'account_form_screen.dart';
import 'card_detail_screen.dart';
import 'credit_card_form_screen.dart';
import 'statement_form_screen.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  var _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == _tabIndex) return;
    _tabIndex = _tabController.index;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _create() {
    final screen = _tabIndex == 0
        ? const AccountFormScreen()
        : const CreditCardFormScreen();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _editAccount(Account account) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountFormScreen(account: account),
      ),
    );
  }

  void _editCard(CreditCard card) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CreditCardFormScreen(card: card)),
    );
  }

  Future<void> _deleteAccount(Account account) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hesabı sil',
      message: '${account.name} hesabını silmek istediğinize emin misiniz?',
    );
    if (!confirmed || !mounted) return;
    await ref.read(accountsProvider.notifier).delete(account.id);
  }

  Future<void> _deleteCard(CreditCard card) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Kartı sil',
      message: '${card.name} kartını silmek istediğinize emin misiniz?',
    );
    if (!confirmed || !mounted) return;
    await StatementActions(ref).deleteCard(card);
  }

  CreditCard? _cardById(List<CreditCard> cards, String id) {
    for (final card in cards) {
      if (card.id == id) return card;
    }
    return null;
  }

  void _openCard(CreditCard card) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CardDetailScreen(cardId: card.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final cards = ref.watch(creditCardsProvider);
    final statements = ref.watch(statementsProvider);
    final now = DateTime.now();
    final onAccountsTab = _tabIndex == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesaplar & Kartlar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hesaplar'),
            Tab(text: 'Kartlar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _accountsBody(accounts),
          _cardsBody(cards, statements, now),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'accounts-fab',
        onPressed: _create,
        icon: const Icon(Iconsax.add),
        label: Text(onAccountsTab ? 'Hesap Ekle' : 'Kart Ekle'),
      ),
    );
  }

  Widget _accountsBody(List<Account> accounts) {
    if (accounts.isEmpty) {
      return const _EmptyState(
        key: Key('empty-accounts'),
        icon: Iconsax.wallet_2,
        title: 'Henüz banka hesabı eklenmedi',
        message:
            'Maaş, vadesiz veya birikim hesabı ekleyerek bakiyeni takip et.',
      );
    }

    final totals = WalletTotals.sortedCurrencyTotals(
      WalletTotals.balancesByCurrency(accounts),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _BalanceTotals(totals: totals),
        const SizedBox(height: 16),
        for (final account in accounts)
          AccountListCard(
            key: ValueKey('account-${account.id}'),
            account: account,
            onEdit: () => _editAccount(account),
            onDelete: () => _deleteAccount(account),
          ),
      ],
    );
  }

  Widget _cardsBody(
    List<CreditCard> cards,
    List<CardStatement> statements,
    DateTime now,
  ) {
    if (cards.isEmpty) {
      return const _EmptyState(
        key: Key('empty-cards'),
        icon: Iconsax.card,
        title: 'Henüz kredi kartı eklenmedi',
        message: 'Limit, borç ve son ödeme gününü buradan takip et.',
      );
    }

    final debt = WalletTotals.totalDebt(cards);
    final available = WalletTotals.totalAvailableLimit(cards);
    final openStatements = statements
        .where((statement) => !statement.isSettled)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Row(
          children: [
            Expanded(
              child: _TotalTile(
                title: 'Toplam borç',
                amount: formatMoney(debt),
                color: AppTheme.expenseColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TotalTile(
                title: 'Kullanılabilir limit',
                amount: formatMoney(available),
                color: available < 0
                    ? AppTheme.expenseColor
                    : AppTheme.incomeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Ekstreler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (openStatements.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Açık ekstre yok',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          for (final statement in openStatements)
            InkWell(
              onTap: () {
                final match = _cardById(cards, statement.creditCardId);
                if (match != null) _openCard(match);
              },
              child: StatementTile(
                statement: statement,
                now: now,
                onEdit: () {
                  final match = _cardById(cards, statement.creditCardId);
                  if (match == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => StatementFormScreen(
                        card: match,
                        statement: statement,
                      ),
                    ),
                  );
                },
                onDelete: () async {
                  final confirmed = await confirmDelete(
                    context,
                    title: 'Ekstreyi sil',
                    message:
                        '${formatTrDate(statement.periodDate)} tarihli ekstre silinsin mi?',
                  );
                  if (!confirmed || !mounted) return;
                  await StatementActions(ref).delete(statement);
                },
                onMarkPaid: () => StatementActions(ref).markPaid(statement),
              ),
            ),
          const SizedBox(height: 8),
        ],
        for (final card in cards)
          CreditCardListCard(
            key: ValueKey('card-${card.id}'),
            card: card,
            now: now,
            onOpen: () => _openCard(card),
            onEdit: () => _editCard(card),
            onDelete: () => _deleteCard(card),
          ),
      ],
    );
  }
}

class _BalanceTotals extends StatelessWidget {
  const _BalanceTotals({required this.totals});

  final List<MapEntry<String, double>> totals;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Toplam bakiye',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (totals.length == 1)
            Text(
              formatMoney(totals.first.value, currency: totals.first.key),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            )
          else
            for (final entry in totals)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      formatMoney(entry.value, currency: entry.key),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _TotalTile extends StatelessWidget {
  const _TotalTile({
    required this.title,
    required this.amount,
    required this.color,
  });

  final String title;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
