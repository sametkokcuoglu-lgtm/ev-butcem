// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'account.dart';

class AccountAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = 2;

  @override
  Account read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Account(
      id: fields[0] as String,
      name: fields[1] as String,
      bankName: fields[2] as String,
      balance: fields[3] as double,
      currency: fields[4] as String,
      color: fields[5] as String?,
      isActive: fields[6] as bool,
      createdAt: fields[7] as DateTime,
      // Missing on data saved before account type / IBAN / icon / KMH existed.
      accountType: fields[8] == null ? 'vadesiz' : fields[8] as String,
      iban: fields[9] as String?,
      icon: fields[10] as String?,
      overdraftLimit: fields[11] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.bankName)
      ..writeByte(3)
      ..write(obj.balance)
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.color)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.accountType)
      ..writeByte(9)
      ..write(obj.iban)
      ..writeByte(10)
      ..write(obj.icon)
      ..writeByte(11)
      ..write(obj.overdraftLimit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
