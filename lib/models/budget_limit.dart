import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'budget_limit.g.dart';

/// Recurring monthly spending cap for one expense category.
@HiveType(typeId: 5)
class BudgetLimit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String categoryId;

  @HiveField(2)
  final double amount;

  BudgetLimit({
    String? id,
    required this.categoryId,
    required this.amount,
  }) : id = id ?? const Uuid().v4();
}
