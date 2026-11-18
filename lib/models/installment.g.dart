// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'installment.dart';

class InstallmentAdapter extends TypeAdapter<Installment> {
  @override
  final int typeId = 4;

  @override
  Installment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Installment(
      id: fields[0] as String,
      title: fields[1] as String,
      totalAmount: fields[2] as double,
      totalInstallments: fields[3] as int,
      paidInstallments: fields[4] as int,
      startDate: fields[5] as DateTime,
      creditCardId: fields[6] as String?,
      note: fields[7] as String?,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Installment obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.totalAmount)
      ..writeByte(3)
      ..write(obj.totalInstallments)
      ..writeByte(4)
      ..write(obj.paidInstallments)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.creditCardId)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
