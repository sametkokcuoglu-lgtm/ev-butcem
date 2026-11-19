import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ui_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/content_frame.dart';
import 'accounts_screen.dart';
import 'bills_screen.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';
import 'statements_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diğer')),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xl),
          children: [
            const _Group(
              title: 'Finans',
              tiles: [
                _Destination(icon: Icons.receipt_long_rounded, title: 'Faturalar', subtitle: 'Yaklaşan ve ödenen ödemeler', screen: BillsScreen()),
                _Destination(icon: Icons.credit_card_rounded, title: 'Ekstreler', subtitle: 'Kart dönemi ve asgari ödeme', screen: StatementsScreen()),
                _Destination(icon: Icons.account_balance_wallet_outlined, title: 'Hesaplar & Kartlar', subtitle: 'Banka hesabı ve kartlar', screen: AccountsScreen()),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            _Group(
              title: 'Yönetim',
              tiles: [
                const _Destination(icon: Icons.category_outlined, title: 'Kategoriler', subtitle: 'Gelir ve gider kategorileri', screen: CategoriesScreen()),
                _Destination(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'Raporlar',
                  subtitle: 'Kategori ve aylık grafik',
                  onTap: () => ref.read(homeTabProvider.notifier).select(HomeTab.reports),
                ),
                _Destination(
                  icon: Icons.savings_rounded,
                  title: 'Bütçe',
                  subtitle: 'Kategori limitleri',
                  onTap: () => ref.read(homeTabProvider.notifier).select(HomeTab.budget),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            _Group(
              title: 'Uygulama',
              tiles: [
                _Destination(
                  icon: Icons.calendar_month_outlined,
                  title: 'Finans Takvimi',
                  subtitle: 'Çok yakında',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Finans takvimi çok yakında.')),
                    );
                  },
                ),
                const _Destination(icon: Icons.settings_outlined, title: 'Ayarlar', subtitle: 'Tema', screen: SettingsScreen()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<_Destination> tiles;

  const _Group({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finance = FinanceColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i != tiles.length - 1) Divider(height: 1, color: finance.line),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Destination extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? screen;
  final VoidCallback? onTap;

  const _Destination({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.screen,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(icon, size: 20, color: theme.colorScheme.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded, size: 16),
      onTap: onTap ??
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen!)),
    );
  }
}
