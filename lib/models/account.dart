import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'account.g.dart';

@HiveType(typeId: 2)
class Account extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name; // Örn: "Ziraat Vadesiz"

  @HiveField(2)
  final String bankName; // Örn: "Ziraat Bankası"

  @HiveField(3)
  final double balance;

  @HiveField(4)
  final String currency; // TRY, USD, EUR

  @HiveField(5)
  final String? color; // Hex renk

  @HiveField(6)
  final bool isActive;

  @HiveField(7)
  final DateTime createdAt;

  Account({
    String? id,
    required this.name,
    required this.bankName,
    this.balance = 0.0,
    this.currency = 'TRY',
    this.color,
    this.isActive = true,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Account copyWith({
    String? name,
    String? bankName,
    double? balance,
    String? currency,
    String? color,
    bool? isActive,
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
    );
  }
}
