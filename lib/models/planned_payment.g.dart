// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'planned_payment.dart';

class PlannedPaymentAdapter extends TypeAdapter<PlannedPayment> {
  @override
  final int typeId = 5;

  @override
  PlannedPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlannedPayment(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      dueDate: fields[3] as DateTime,
      recurrenceIndex: fields[4] as int,
      accountId: fields[5] as String?,
      creditCardId: fields[6] as String?,
      isPaid: fields[7] as bool,
      categoryId: fields[8] as String?,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PlannedPayment obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.recurrenceIndex)
      ..writeByte(5)
      ..write(obj.accountId)
      ..writeByte(6)
      ..write(obj.creditCardId)
      ..writeByte(7)
      ..write(obj.isPaid)
      ..writeByte(8)
      ..write(obj.categoryId)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlannedPaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
