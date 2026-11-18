import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final String? accountId; // Banka hesabı veya kart

  @HiveField(4)
  final String? creditCardId;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final String? note;

  @HiveField(7)
  final bool isIncome;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  Transaction({
    String? id,
    required this.amount,
    required this.categoryId,
    this.accountId,
    this.creditCardId,
    required this.date,
    this.note,
    required this.isIncome,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Transaction copyWith({
    double? amount,
    String? categoryId,
    String? accountId,
    String? creditCardId,
    DateTime? date,
    String? note,
    bool? isIncome,
  }) {
    return Transaction(
      id: id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      creditCardId: creditCardId ?? this.creditCardId,
      date: date ?? this.date,
      note: note ?? this.note,
      isIncome: isIncome ?? this.isIncome,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
