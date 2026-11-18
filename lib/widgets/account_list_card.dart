import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../models/account.dart';
import '../theme/app_theme.dart';
import '../utils/account_style.dart';
import '../utils/money.dart';

class AccountListCard extends StatelessWidget {
  const AccountListCard({
    super.key,
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  final Account account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = parseHexColor(account.color);
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [
      account.bankName,
      account.type.label,
      account.currency.toUpperCase(),
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconForAccount(account), color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    formatMoney(account.balance, currency: account.currency),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: account.balance < 0
                          ? AppTheme.expenseColor
                          : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (account.iban != null && account.iban!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              formatIban(account.iban!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
          if (account.hasOverdraft) ...[
            const SizedBox(height: 6),
            Text(
              'KMH limiti ${formatMoney(account.overdraftLimit!, currency: account.currency)}',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Düzenle',
                onPressed: onEdit,
                icon: const Icon(Iconsax.edit_2, size: 18),
              ),
              IconButton(
                tooltip: 'Sil',
                onPressed: onDelete,
                icon: const Icon(
                  Iconsax.trash,
                  size: 18,
                  color: AppTheme.expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
