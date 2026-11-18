// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'card_statement.dart';

class CardStatementAdapter extends TypeAdapter<CardStatement> {
  @override
  final int typeId = 5;

  @override
  CardStatement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final periodDate = fields[2] as DateTime;
    return CardStatement(
      id: fields[0] as String,
      creditCardId: fields[1] as String,
      periodDate: periodDate,
      dueDate: fields[3] as DateTime,
      totalAmount: fields[4] as double,
      // Older rows may omit minimum, paid amount and status.
      minimumPayment: fields[5] == null ? 0.0 : fields[5] as double,
      paidAmount: fields[6] == null ? 0.0 : fields[6] as double,
      status: fields[7] == null ? 'unpaid' : fields[7] as String,
      createdAt: fields[8] is DateTime ? fields[8] as DateTime : periodDate,
    );
  }

  @override
  void write(BinaryWriter writer, CardStatement obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.creditCardId)
      ..writeByte(2)
      ..write(obj.periodDate)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.totalAmount)
      ..writeByte(5)
      ..write(obj.minimumPayment)
      ..writeByte(6)
      ..write(obj.paidAmount)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardStatementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
