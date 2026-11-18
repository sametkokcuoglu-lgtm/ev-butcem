// ignore_for_file: implementation_imports

// Hive's binary reader/writer implementations are not part of the public
// API, but they are the only way to feed an adapter the exact bytes an older
// version of the app would have written.

import 'package:hive/hive.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';

TypeRegistryImpl hiveTestRegistry() {
  final registry = TypeRegistryImpl();
  registry.registerAdapter<DateTime>(
    DateTimeAdapter<DateTime>(),
    internal: true,
  );
  return registry;
}

T readHive<T>(
  TypeAdapter<T> adapter,
  void Function(BinaryWriter writer) write,
) {
  final registry = hiveTestRegistry();
  final writer = BinaryWriterImpl(registry);
  write(writer);
  final reader = BinaryReaderImpl(writer.toBytes(), registry);
  return adapter.read(reader);
}
