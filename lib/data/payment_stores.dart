import 'package:hive/hive.dart';

import '../models/installment.dart';
import '../models/planned_payment.dart';
import 'local_database.dart';

abstract class PlannedPaymentStore {
  List<PlannedPayment> load();
  Future<void> save(PlannedPayment payment);
  Future<void> delete(String id);
}

abstract class InstallmentStore {
  List<Installment> load();
  Future<void> save(Installment installment);
}

class HivePlannedPaymentStore implements PlannedPaymentStore {
  Box<PlannedPayment>? get _box {
    if (!Hive.isBoxOpen(plannedPaymentBoxName)) return null;
    return Hive.box<PlannedPayment>(plannedPaymentBoxName);
  }

  @override
  List<PlannedPayment> load() => _box?.values.toList() ?? const [];

  @override
  Future<void> save(PlannedPayment payment) async {
    final box = _box;
    if (box == null) {
      throw StateError('Planlı ödemeler kutusu açık değil');
    }
    await box.put(payment.id, payment);
  }

  @override
  Future<void> delete(String id) async {
    final box = _box;
    if (box == null) {
      throw StateError('Planlı ödemeler kutusu açık değil');
    }
    await box.delete(id);
  }
}

class MemoryPlannedPaymentStore implements PlannedPaymentStore {
  MemoryPlannedPaymentStore([List<PlannedPayment>? initial])
      : _items = [...?initial];

  final List<PlannedPayment> _items;

  @override
  List<PlannedPayment> load() => List<PlannedPayment>.of(_items);

  @override
  Future<void> save(PlannedPayment payment) async {
    final index = _items.indexWhere((item) => item.id == payment.id);
    if (index >= 0) {
      _items[index] = payment;
    } else {
      _items.add(payment);
    }
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}

class HiveInstallmentStore implements InstallmentStore {
  Box<Installment>? get _box {
    if (!Hive.isBoxOpen(installmentBoxName)) return null;
    return Hive.box<Installment>(installmentBoxName);
  }

  @override
  List<Installment> load() => _box?.values.toList() ?? const [];

  @override
  Future<void> save(Installment installment) async {
    final box = _box;
    if (box == null) {
      throw StateError('Taksit kutusu açık değil');
    }
    await box.put(installment.id, installment);
  }
}

class MemoryInstallmentStore implements InstallmentStore {
  MemoryInstallmentStore([List<Installment>? initial]) : _items = [...?initial];

  final List<Installment> _items;

  @override
  List<Installment> load() => List<Installment>.of(_items);

  @override
  Future<void> save(Installment installment) async {
    final index = _items.indexWhere((item) => item.id == installment.id);
    if (index >= 0) {
      _items[index] = installment;
    } else {
      _items.add(installment);
    }
  }
}

List<T> readHiveList<T>(String boxName) {
  if (!Hive.isBoxOpen(boxName)) return const [];
  return Hive.box<T>(boxName).values.toList();
}
