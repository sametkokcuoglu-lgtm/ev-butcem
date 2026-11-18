import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'credit_card.g.dart';

@HiveType(typeId: 3)
class CreditCard extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name; // Örn: "Ziraat Bankası Platinum"

  @HiveField(2)
  final String bankName;

  @HiveField(3)
  final double limit;

  @HiveField(4)
  final double currentDebt;

  @HiveField(5)
  final int statementDay; // Ekstre kesim günü (1-31)

  @HiveField(6)
  final int dueDay; // Son ödeme günü (1-31)

  @HiveField(7)
  final String? color;

  @HiveField(8)
  final bool isActive;

  @HiveField(9)
  final DateTime createdAt;

  CreditCard({
    String? id,
    required this.name,
    required this.bankName,
    required this.limit,
    this.currentDebt = 0.0,
    required this.statementDay,
    required this.dueDay,
    this.color,
    this.isActive = true,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get availableLimit => limit - currentDebt;

  double get usagePercentage => limit > 0 ? (currentDebt / limit) * 100 : 0;

  CreditCard copyWith({
    String? name,
    String? bankName,
    double? limit,
    double? currentDebt,
    int? statementDay,
    int? dueDay,
    String? color,
    bool? isActive,
  }) {
    return CreditCard(
      id: id,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      limit: limit ?? this.limit,
      currentDebt: currentDebt ?? this.currentDebt,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
