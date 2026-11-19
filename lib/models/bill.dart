import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'planned_payment.dart';

part 'bill.g.dart';

/// Kullanıcının kaydettiği fatura (elektrik, su, internet, aidat...).
@HiveType(typeId: 6)
class Bill extends HiveObject {
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
  final bool isPaid;

  @HiveField(6)
  final String? categoryId;

  @HiveField(7)
  final String? note;

  @HiveField(8)
  final DateTime createdAt;

  Bill({
    String? id,
    required this.title,
    required this.amount,
    required DateTime dueDate,
    PaymentRecurrence recurrence = PaymentRecurrence.none,
    int? recurrenceIndex,
    this.isPaid = false,
    this.categoryId,
    this.note,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day),
        recurrenceIndex = recurrenceIndex ?? recurrence.index,
        createdAt = createdAt ?? DateTime.now();

  PaymentRecurrence get recurrence =>
      PaymentRecurrence.fromIndex(recurrenceIndex);

  Bill copyWith({
    String? title,
    double? amount,
    DateTime? dueDate,
    PaymentRecurrence? recurrence,
    bool? isPaid,
    String? categoryId,
    String? note,
    bool clearCategoryId = false,
    bool clearNote = false,
  }) {
    return Bill(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      recurrence: recurrence ?? this.recurrence,
      isPaid: isPaid ?? this.isPaid,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt,
    );
  }
}
