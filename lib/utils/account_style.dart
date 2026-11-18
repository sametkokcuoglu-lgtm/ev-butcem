import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../models/account.dart';

const accountColorOptions = <String>[
  '#2563EB',
  '#0EA5E9',
  '#0891B2',
  '#16A34A',
  '#059669',
  '#F59E0B',
  '#EA580C',
  '#DC2626',
  '#DB2777',
  '#7C3AED',
];

const defaultAccountColor = '#2563EB';

class AccountIconOption {
  const AccountIconOption(this.key, this.icon);

  final String key;
  final IconData icon;
}

const accountIconOptions = <AccountIconOption>[
  AccountIconOption('wallet', Iconsax.wallet_2),
  AccountIconOption('bank', Iconsax.bank),
  AccountIconOption('safe', Iconsax.strongbox_2),
  AccountIconOption('money', Iconsax.money),
  AccountIconOption('card', Iconsax.card),
  AccountIconOption('building', Iconsax.building),
];

String defaultIconKeyFor(AccountType type) {
  switch (type) {
    case AccountType.vadesiz:
      return 'wallet';
    case AccountType.vadeli:
      return 'bank';
    case AccountType.birikim:
      return 'safe';
    case AccountType.maas:
      return 'money';
    case AccountType.diger:
      return 'building';
  }
}

IconData iconByKey(String? key) {
  for (final option in accountIconOptions) {
    if (option.key == key) return option.icon;
  }
  return Iconsax.wallet_2;
}

IconData iconForAccount(Account account) {
  if (account.icon != null) return iconByKey(account.icon);
  return iconByKey(defaultIconKeyFor(account.type));
}

Color parseHexColor(String? hex, {Color fallback = const Color(0xFF2563EB)}) {
  if (hex == null) return fallback;
  var value = hex.trim();
  if (value.isEmpty) return fallback;
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return fallback;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}
