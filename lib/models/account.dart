import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'account.g.dart';

enum AccountType {
  vadesiz('Vadesiz'),
  vadeli('Vadeli'),
  birikim('Birikim'),
  maas('Maaş'),
  diger('Diğer');

  const AccountType(this.label);

  final String label;

  static AccountType fromName(String? value) {
    for (final type in AccountType.values) {
      if (type.name == value) return type;
    }
    return AccountType.vadesiz;
  }
}

@HiveType(typeId: 2)
class Account extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String bankName;

  @HiveField(3)
  final double balance;

  @HiveField(4)
  final String currency;

  @HiveField(5)
  final String? color;

  @HiveField(6)
  final bool isActive;

  @HiveField(7)
  final DateTime createdAt;

  /// `vadesiz`, `vadeli`, `birikim`, `maas` or `diger`.
  /// Older saves do not have this field; readers fall back to `vadesiz`.
  @HiveField(8, defaultValue: 'vadesiz')
  final String accountType;

  @HiveField(9)
  final String? iban;

  /// Icon key such as `wallet`, `bank`, `safe`.
  @HiveField(10)
  final String? icon;

  /// Optional overdraft (KMH) limit. Null when the account has no KMH.
  @HiveField(11)
  final double? overdraftLimit;

  Account({
    String? id,
    required this.name,
    required this.bankName,
    this.balance = 0.0,
    this.currency = 'TRY',
    this.color,
    this.isActive = true,
    DateTime? createdAt,
    this.accountType = 'vadesiz',
    this.iban,
    this.icon,
    this.overdraftLimit,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  AccountType get type => AccountType.fromName(accountType);

  bool get hasOverdraft => overdraftLimit != null && overdraftLimit! > 0;

  /// Spendable amount including the overdraft limit.
  double get availableWithOverdraft => balance + (overdraftLimit ?? 0);

  Account copyWith({
    String? name,
    String? bankName,
    double? balance,
    String? currency,
    String? color,
    bool? isActive,
    String? accountType,
    String? iban,
    String? icon,
    double? overdraftLimit,
    bool clearIban = false,
    bool clearOverdraft = false,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      accountType: accountType ?? this.accountType,
      iban: clearIban ? null : (iban ?? this.iban),
      icon: icon ?? this.icon,
      overdraftLimit:
          clearOverdraft ? null : (overdraftLimit ?? this.overdraftLimit),
    );
  }
}
