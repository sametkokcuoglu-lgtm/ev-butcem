import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'installment.g.dart';

@HiveType(typeId: 4)
class Installment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title; // Örn: "iPhone 15"

  @HiveField(2)
  final double totalAmount;

  @HiveField(3)
  final int totalInstallments; // Toplam taksit sayısı

  @HiveField(4)
  final int paidInstallments; // Ödenen taksit sayısı

  @HiveField(5)
  final DateTime startDate; // İlk taksit tarihi

  @HiveField(6)
  final String? creditCardId;

  @HiveField(7)
  final String? note;

  @HiveField(8)
  final DateTime createdAt;

  Installment({
    String? id,
    required this.title,
    required this.totalAmount,
    required this.totalInstallments,
    this.paidInstallments = 0,
    required this.startDate,
    this.creditCardId,
    this.note,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get monthlyAmount => totalAmount / totalInstallments;

  int get remainingInstallments => totalInstallments - paidInstallments;

  double get remainingAmount => monthlyAmount * remainingInstallments;

  bool get isCompleted => paidInstallments >= totalInstallments;

  Installment copyWith({
    String? title,
    double? totalAmount,
    int? totalInstallments,
    int? paidInstallments,
    DateTime? startDate,
    String? creditCardId,
    String? note,
  }) {
    return Installment(
      id: id,
      title: title ?? this.title,
      totalAmount: totalAmount ?? this.totalAmount,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      startDate: startDate ?? this.startDate,
      creditCardId: creditCardId ?? this.creditCardId,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }
}
