import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'planned_payment.g.dart';

enum PaymentRecurrence {
  none,
  monthly,
  yearly;

  String get label => switch (this) {
        PaymentRecurrence.none => 'Tek seferlik',
        PaymentRecurrence.monthly => 'Aylık',
        PaymentRecurrence.yearly => 'Yıllık',
      };

  static PaymentRecurrence fromIndex(int index) {
    if (index < 0 || index >= PaymentRecurrence.values.length) {
      return PaymentRecurrence.none;
    }
    return PaymentRecurrence.values[index];
  }
}

@HiveType(typeId: 5)
class PlannedPayment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime dueDate;

  @HiveField(4)
  final int recurrenceIndex;

  @HiveField(5)
  final String? accountId;

  @HiveField(6)
  final String? creditCardId;

  @HiveField(7)
  final bool isPaid;

  @HiveField(8)
  final String? categoryId;

  @HiveField(9)
  final DateTime createdAt;

  PlannedPayment({
    String? id,
    required this.title,
    required this.amount,
    required DateTime dueDate,
    PaymentRecurrence recurrence = PaymentRecurrence.none,
    int? recurrenceIndex,
    this.accountId,
    this.creditCardId,
    this.categoryId,
    this.isPaid = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day),
        recurrenceIndex = recurrenceIndex ?? recurrence.index,
        createdAt = createdAt ?? DateTime.now();

  PaymentRecurrence get recurrence =>
      PaymentRecurrence.fromIndex(recurrenceIndex);

  PlannedPayment copyWith({
    String? title,
    double? amount,
    DateTime? dueDate,
    PaymentRecurrence? recurrence,
    String? accountId,
    String? creditCardId,
    String? categoryId,
    bool? isPaid,
    bool clearAccountId = false,
    bool clearCreditCardId = false,
    bool clearCategoryId = false,
  }) {
    return PlannedPayment(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      recurrence: recurrence ?? this.recurrence,
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      creditCardId:
          clearCreditCardId ? null : (creditCardId ?? this.creditCardId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt,
    );
  }
}
