import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../constants/hive_boxes.dart';
import '../models/account.dart';
import '../models/card_statement.dart';
import '../models/credit_card.dart';

final accountsProvider =
    StateNotifierProvider<HiveListNotifier<Account>, List<Account>>((ref) {
  return HiveListNotifier<Account>(
    box: Hive.box<Account>(HiveBoxes.accounts),
    idOf: (account) => account.id,
    compare: _newestFirst(
      (account) => account.createdAt,
      (account) => account.name,
    ),
  );
});

final creditCardsProvider =
    StateNotifierProvider<HiveListNotifier<CreditCard>, List<CreditCard>>((
  ref,
) {
  return HiveListNotifier<CreditCard>(
    box: Hive.box<CreditCard>(HiveBoxes.creditCards),
    idOf: (card) => card.id,
    compare: _newestFirst((card) => card.createdAt, (card) => card.name),
  );
});

final statementsProvider =
    StateNotifierProvider<HiveListNotifier<CardStatement>, List<CardStatement>>(
  (ref) {
    return HiveListNotifier<CardStatement>(
      box: Hive.box<CardStatement>(HiveBoxes.statements),
      idOf: (statement) => statement.id,
      compare: (a, b) {
        final byPeriod = b.periodDate.compareTo(a.periodDate);
        if (byPeriod != 0) return byPeriod;
        return b.createdAt.compareTo(a.createdAt);
      },
    );
  },
);

int Function(T, T) _newestFirst<T>(
  DateTime Function(T item) createdAt,
  String Function(T item) name,
) {
  return (a, b) {
    final byDate = createdAt(b).compareTo(createdAt(a));
    if (byDate != 0) return byDate;
    return name(a).toLowerCase().compareTo(name(b).toLowerCase());
  };
}

class HiveListNotifier<T> extends StateNotifier<List<T>> {
  HiveListNotifier({
    required Box<T> box,
    required String Function(T item) idOf,
    required int Function(T a, T b) compare,
  })  : _box = box,
        _idOf = idOf,
        _compare = compare,
        super(<T>[]) {
    _emit();
    _subscription = _box.watch().listen((_) => _emit());
  }

  final Box<T> _box;
  final String Function(T item) _idOf;
  final int Function(T a, T b) _compare;
  late final StreamSubscription<BoxEvent> _subscription;

  Future<void> save(T item) => _box.put(_idOf(item), item);

  Future<void> delete(String id) => _box.delete(id);

  void _emit() {
    if (!mounted) return;
    final items = _box.values.toList()..sort(_compare);
    state = items;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
