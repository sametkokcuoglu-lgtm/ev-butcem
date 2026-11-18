import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String icon;
  @HiveField(3)
  final int colorValue;
  @HiveField(4)
  final bool isIncome;
  @HiveField(5)
  final bool isSystem;

  Category({
    String? id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.isIncome,
    this.isSystem = false,
  }) : id = id ?? const Uuid().v4();

  /// Düzenleme için kopya üretir; [id] ve [isSystem] korunur.
  Category copyWith({
    String? name,
    String? icon,
    int? colorValue,
    bool? isIncome,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      isIncome: isIncome ?? this.isIncome,
      isSystem: isSystem,
    );
  }
}
