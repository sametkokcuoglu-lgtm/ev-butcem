import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpcomingPaymentTile extends StatelessWidget {
  final String title;
  final double amount;
  final DateTime date;
  final String icon;

  const UpcomingPaymentTile({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 0,
    );

    final daysLeft = date.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent
              ? Colors.red.withOpacity(0.3)
              : Colors.grey.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  daysLeft == 0
                      ? 'Bugün'
                      : daysLeft == 1
                          ? 'Yarın'
                          : '$daysLeft gün sonra',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUrgent ? Colors.red : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isUrgent ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}
