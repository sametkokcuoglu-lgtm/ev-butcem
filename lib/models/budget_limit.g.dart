// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'budget_limit.dart';

class BudgetLimitAdapter extends TypeAdapter<BudgetLimit> {
  @override
  final int typeId = 5;

  @override
  BudgetLimit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetLimit(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, BudgetLimit obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetLimitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
