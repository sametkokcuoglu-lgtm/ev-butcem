import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo/demo_finance.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/ui_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/budget_view.dart';
import '../utils/date_groups.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/category_avatar.dart';
import '../widgets/content_frame.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/summary_card.dart';
import '../widgets/upcoming_payment_tile.dart';
import 'bills_screen.dart';
import 'statements_screen.dart';
import 'transactions_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(currentMonthSummaryProvider);
    final transactions = ref.watch(transactionsProvider);
    final categories = ref.watch(categoryMapProvider);
    final recent = transactions.take(5).toList();
    final bills = DemoFinance.bills().where((b) => !b.paid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final upcoming = bills.take(3).toList();
    final budget = BudgetView.lines(ref.watch(categoriesProvider), transactions, DateTime.now());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Genel Bakış')),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xl),
          children: [
            Text(
              AppFormatters.monthYear(DateTime.now()),
              style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            _BalanceHero(
              amount: summary.difference,
              income: summary.income,
              expense: summary.expense,
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Gelir',
                    amount: summary.income,
                    color: FinanceColors.of(context).income,
                    icon: Icons.south_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(
                  child: SummaryCard(
                    title: 'Gider',
                    amount: summary.expense,
                    color: FinanceColors.of(context).expense,
                    icon: Icons.north_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            const _QuickActions(),
            const SizedBox(height: AppSpacing.section),
            SectionHeader(
              title: 'Son İşlemler',
              onAction: () => ref.read(homeTabProvider.notifier).select(HomeTab.transactions),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (recent.isEmpty)
              const AppCard(
                child: EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'Henüz işlem yok',
                  message: 'Gelir veya gider eklediğinde hareketler burada görünecek.',
                ),
              )
            else
              _RecentList(transactions: recent, categories: categories),
            const SizedBox(height: AppSpacing.section),
            _BudgetSnapshot(
              lines: budget,
              onOpen: () => ref.read(homeTabProvider.notifier).select(HomeTab.budget),
            ),
            const SizedBox(height: AppSpacing.section),
            SectionHeader(
              title: 'Yaklaşan Ödemeler',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BillsScreen()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final bill in upcoming)
              UpcomingPaymentTile(
                title: bill.title,
                subtitle: bill.provider,
                amount: bill.amount,
                date: bill.dueDate,
                icon: bill.icon,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BillsScreen()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  final double amount;
  final double income;
  final double expense;

  const _BalanceHero({required this.amount, required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final finance = FinanceColors.of(context);
    final positive = amount >= 0;
    final total = income + expense;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [finance.heroStart, finance.heroMid, finance.heroEnd],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: finance.heroMid.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -36,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 36,
              bottom: -48,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withValues(alpha: 0.85), size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Bu ay kalan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          positive ? 'Artıda' : 'Ekside',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppFormatters.money(amount),
                      key: const Key('differenceText'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Gelir − gider',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RatioBar(income: income, expense: expense, total: total),
                  const SizedBox(height: AppSpacing.sm),
                  const Row(
                    children: [
                      _LegendDot(color: Color(0xFF6EE7B7), label: 'Gelir'),
                      SizedBox(width: AppSpacing.md),
                      _LegendDot(color: Color(0xFFFDA4AF), label: 'Gider'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatioBar extends StatelessWidget {
  final double income;
  final double expense;
  final double total;

  const _RatioBar({required this.income, required this.expense, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total <= 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(99),
        ),
      );
    }
    final incomeFlex = (income / total * 1000).round().clamp(1, 1000);
    final expenseFlex = (expense / total * 1000).round().clamp(1, 1000);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            if (income > 0) Expanded(flex: incomeFlex, child: const ColoredBox(color: Color(0xFF6EE7B7))),
            if (expense > 0) Expanded(flex: expenseFlex, child: const ColoredBox(color: Color(0xFFFDA4AF))),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final finance = FinanceColors.of(context);
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.add_circle_outline,
            label: 'Gelir',
            color: finance.income,
            onTap: () => openTransactionForm(context, isIncome: true),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: Icons.remove_circle_outline,
            label: 'Gider',
            color: finance.expense,
            onTap: () => openTransactionForm(context),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: Icons.receipt_long_rounded,
            label: 'Fatura',
            color: finance.warning,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BillsScreen())),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickAction(
            icon: Icons.credit_card_rounded,
            label: 'Ekstre',
            color: Theme.of(context).colorScheme.primary,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatementsScreen())),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: AppSpacing.radiusMd,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + AppSpacing.xs, horizontal: AppSpacing.xs),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  final List<Transaction> transactions;
  final Map<String, Category> categories;

  const _RecentList({required this.transactions, required this.categories});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final rows = <Widget>[];
    String? lastLabel;
    for (final t in transactions) {
      final label = DateGroups.label(t.date);
      if (label != lastLabel) {
        if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpacing.sm));
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: AppSpacing.xs),
          child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ));
        lastLabel = label;
      }
      final category = categories[t.categoryId];
      final color = t.isIncome ? finance.income : finance.expense;
      rows.add(AppCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.item),
        radius: AppSpacing.radiusMd,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + AppSpacing.xs, vertical: AppSpacing.sm),
        onTap: () => openTransactionForm(context, transaction: t),
        child: Row(
          children: [
            CategoryAvatar(icon: category?.icon ?? '❔', colorValue: category?.colorValue, size: 40),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
            Expanded(
              child: Text(
                category?.name ?? 'Kategorisiz',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  AppFormatters.activityAmount(t.amount, income: t.isIncome),
                  style: theme.textTheme.titleSmall?.copyWith(color: color),
                ),
              ),
            ),
          ],
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

class _BudgetSnapshot extends StatelessWidget {
  final List<BudgetLine> lines;
  final VoidCallback onOpen;

  const _BudgetSnapshot({required this.lines, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    final limit = BudgetView.totalLimit(lines);
    final spent = BudgetView.totalSpent(lines);
    final ratio = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    final over = limit > 0 && spent > limit;
    final color = over ? finance.expense : finance.income;
    final caption = limit <= 0
        ? 'Kategori limiti tanımlanmadı'
        : spent <= 0
            ? 'Bu ay henüz harcama yok'
            : over
                ? 'Aylık limit aşıldı'
                : 'Limit kullanımı %${(spent / limit * 100).round()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Bütçe', onAction: onOpen),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(caption, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: color.withValues(alpha: 0.12),
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
