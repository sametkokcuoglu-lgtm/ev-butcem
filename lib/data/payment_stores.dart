import 'package:hive/hive.dart';

import '../models/bill.dart';
import '../models/credit_card.dart';
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

abstract class BillStore {
  List<Bill> load();
  Future<void> save(Bill bill);
  Future<void> delete(String id);
}

class HiveBillStore implements BillStore {
  Box<Bill>? get _box {
    if (!Hive.isBoxOpen(billBoxName)) return null;
    return Hive.box<Bill>(billBoxName);
  }

  @override
  List<Bill> load() => _box?.values.toList() ?? const [];

  @override
  Future<void> save(Bill bill) async {
    final box = _box;
    if (box == null) throw StateError('Faturalar kutusu açık değil');
    await box.put(bill.id, bill);
  }

  @override
  Future<void> delete(String id) async {
    final box = _box;
    if (box == null) throw StateError('Faturalar kutusu açık değil');
    await box.delete(id);
  }
}

class MemoryBillStore implements BillStore {
  MemoryBillStore([List<Bill>? initial]) : _items = [...?initial];

  final List<Bill> _items;

  @override
  List<Bill> load() => List<Bill>.of(_items);

  @override
  Future<void> save(Bill bill) async {
    final index = _items.indexWhere((item) => item.id == bill.id);
    if (index >= 0) {
      _items[index] = bill;
    } else {
      _items.add(bill);
    }
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}

abstract class CreditCardStore {
  List<CreditCard> load();
  Future<void> save(CreditCard card);
  Future<void> delete(String id);
}

class HiveCreditCardStore implements CreditCardStore {
  Box<CreditCard>? get _box {
    if (!Hive.isBoxOpen(creditCardBoxName)) return null;
    return Hive.box<CreditCard>(creditCardBoxName);
  }

  @override
  List<CreditCard> load() => _box?.values.toList() ?? const [];

  @override
  Future<void> save(CreditCard card) async {
    final box = _box;
    if (box == null) throw StateError('Kredi kartları kutusu açık değil');
    await box.put(card.id, card);
  }

  @override
  Future<void> delete(String id) async {
    final box = _box;
    if (box == null) throw StateError('Kredi kartları kutusu açık değil');
    await box.delete(id);
  }
}

class MemoryCreditCardStore implements CreditCardStore {
  MemoryCreditCardStore([List<CreditCard>? initial]) : _items = [...?initial];

  final List<CreditCard> _items;

  @override
  List<CreditCard> load() => List<CreditCard>.of(_items);

  @override
  Future<void> save(CreditCard card) async {
    final index = _items.indexWhere((item) => item.id == card.id);
    if (index >= 0) {
      _items[index] = card;
    } else {
      _items.add(card);
    }
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}

List<T> readHiveList<T>(String boxName) {
  if (!Hive.isBoxOpen(boxName)) return const [];
  return Hive.box<T>(boxName).values.toList();
}
