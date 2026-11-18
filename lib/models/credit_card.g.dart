// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'credit_card.dart';

class CreditCardAdapter extends TypeAdapter<CreditCard> {
  @override
  final int typeId = 3;

  @override
  CreditCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CreditCard(
      id: fields[0] as String,
      name: fields[1] as String,
      bankName: fields[2] as String,
      limit: fields[3] as double,
      currentDebt: fields[4] as double,
      statementDay: fields[5] as int,
      dueDay: fields[6] as int,
      color: fields[7] as String?,
      isActive: fields[8] as bool,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CreditCard obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.bankName)
      ..writeByte(3)
      ..write(obj.limit)
      ..writeByte(4)
      ..write(obj.currentDebt)
      ..writeByte(5)
      ..write(obj.statementDay)
      ..writeByte(6)
      ..write(obj.dueDay)
      ..writeByte(7)
      ..write(obj.color)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
