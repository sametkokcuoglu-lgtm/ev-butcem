import 'package:ev_butcem/models/transaction.dart';
import 'package:ev_butcem/providers/transaction_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  late TestBoxes boxes;
  late ProviderContainer container;

  setUpAll(registerTestAdapters);
  setUp(() async {
    boxes = await TestBoxes.open();
    container = boxes.container();
  });
  tearDown(() async {
    container.dispose();
    await boxes.close();
  });

  test('Silinen işlem geri alınınca tüm alanlarıyla geri gelir', () async {
    final notifier = container.read(transactionsProvider.notifier);
    final t = Transaction(
      amount: 850,
      categoryId: 'market',
      date: DateTime(2026, 11, 3),
      note: 'Haftalık',
      isIncome: false,
      createdAt: DateTime(2026, 11, 3, 10),
      updatedAt: DateTime(2026, 11, 4, 9),
    );
    await notifier.add(t);

    final removed = await notifier.remove(t.id);
    expect(removed, isNotNull);
    expect(boxes.transactions.isEmpty, isTrue);
    expect(container.read(transactionsProvider), isEmpty);

    await notifier.restore(removed!);
    final back = boxes.transactions.get(t.id)!;
    expect(back.amount, 850);
    expect(back.note, 'Haftalık');
    expect(back.categoryId, 'market');
    expect(back.date, DateTime(2026, 11, 3));
    expect(back.createdAt, DateTime(2026, 11, 3, 10));
    expect(back.updatedAt, DateTime(2026, 11, 4, 9));
    expect(container.read(transactionsProvider).single.id, t.id);
  });

  test('Düzenleme id ve createdAt korur, updatedAt yenilenir', () async {
    final notifier = container.read(transactionsProvider.notifier);
    final created = DateTime(2026, 1, 1);
    final t = Transaction(amount: 10, categoryId: 'market', date: DateTime(2026, 1, 1), isIncome: false, createdAt: created, updatedAt: created);
    await notifier.add(t);
    await notifier.edit(t.copyWith(amount: 20));

    final saved = boxes.transactions.get(t.id)!;
    expect(boxes.transactions.length, 1);
    expect(saved.amount, 20);
    expect(saved.createdAt, created);
    expect(saved.updatedAt.isAfter(created), isTrue);
  });

  test('Var olmayan işlem silinince null döner', () async {
    expect(await container.read(transactionsProvider.notifier).remove('yok'), isNull);
  });
}
