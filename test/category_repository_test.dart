import 'package:ev_butcem/models/category.dart';
import 'package:ev_butcem/models/transaction.dart';
import 'package:ev_butcem/providers/transaction_provider.dart';
import 'package:ev_butcem/services/category_repository.dart';
import 'package:ev_butcem/utils/default_data.dart';
import 'package:ev_butcem/utils/text_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  late TestBoxes boxes;
  late CategoryRepository repo;

  setUpAll(registerTestAdapters);
  setUp(() async {
    boxes = await TestBoxes.open();
    repo = CategoryRepository(boxes.categories);
  });
  tearDown(() async => boxes.close());

  group('Türkçe metin', () {
    test('Anahtar boşlukları ve Türkçe büyük/küçük harfi yok sayar', () {
      expect(TurkishText.key('  MARKET  '), 'market');
      expect(TurkishText.key('IŞIK'), 'ışık');
      expect(TurkishText.key('İçecek'), 'içecek');
      expect(TurkishText.key('Ek   Gelir'), 'ek gelir');
    });

    test('Türk alfabesine göre sıralar', () {
      final names = ['Ulaşım', 'Çocuk', 'Sağlık', 'Şans', 'Cep', 'Ödeme', 'Oyun'];
      names.sort(TurkishText.compare);
      expect(names, ['Cep', 'Çocuk', 'Oyun', 'Ödeme', 'Sağlık', 'Şans', 'Ulaşım']);
    });
  });

  group('Varsayılan kategoriler', () {
    test('Kimlikler sabittir ve her çağrıda aynıdır', () {
      final a = DefaultData.defaultCategories.map((c) => c.id).toList();
      final b = DefaultData.defaultCategories.map((c) => c.id).toList();
      expect(a, b);
      expect(a.toSet().length, a.length);
      expect(a.every((id) => id.startsWith('default_')), isTrue);
    });

    test('Tohumlama yalnızca kutu boşsa yapılır, mevcut veriye dokunmaz', () async {
      await repo.seedDefaultsIfEmpty();
      expect(repo.getAll().map((c) => c.id), unorderedEquals(['market', 'kira', 'maas']));

      await boxes.categories.clear();
      await repo.seedDefaultsIfEmpty();
      await repo.seedDefaultsIfEmpty();
      expect(repo.getAll().length, DefaultData.defaultCategories.length);
      expect(repo.getById('default_market')!.name, 'Market');
    });
  });

  group('Ad kuralları', () {
    test('Aynı türde aynı ad (büyük/küçük harf, boşluk farkıyla) reddedilir', () {
      expect(repo.validateName('market', isIncome: false), isNotNull);
      expect(repo.validateName('  MARKET ', isIncome: false), isNotNull);
      expect(repo.validateName('maaş', isIncome: true), isNotNull);
      expect(repo.validateName('MAAŞ', isIncome: true), isNotNull);
    });

    test('Farklı türde aynı ad ve kendi adı serbesttir', () {
      expect(repo.validateName('Market', isIncome: true), isNull);
      expect(repo.validateName('market', isIncome: false, excludeId: 'market'), isNull);
      expect(repo.validateName('Aidat', isIncome: false), isNull);
    });

    test('Boş ve çok uzun ad reddedilir', () {
      expect(repo.validateName('   ', isIncome: false), 'Kategori adı girin');
      expect(repo.validateName('a' * 31, isIncome: false), isNotNull);
    });

    test('Kaydederken ad temizlenir, çift kayıt fırlatır', () async {
      final saved = await repo.save(
          Category(name: '  Su   Faturası ', icon: '💧', colorValue: 0, isIncome: false));
      expect(saved.name, 'Su Faturası');
      expect(repo.getById(saved.id)!.name, 'Su Faturası');

      expect(
        () => repo.save(Category(name: 'su faturası', icon: '💧', colorValue: 0, isIncome: false)),
        throwsA(isA<CategoryException>()),
      );
    });

    test('Varsayılan kategori düzenlenebilir, isSystem korunur', () async {
      final market = repo.getById('market')!;
      await repo.save(market.copyWith(name: 'Süpermarket', icon: '🧺'));
      final edited = repo.getById('market')!;
      expect(edited.name, 'Süpermarket');
      expect(edited.icon, '🧺');
      expect(edited.isSystem, isTrue);
    });
  });

  group('Silme kuralları', () {
    test('Her türden en az bir kategori kalmalı', () async {
      expect(repo.deleteBlocker('maas'), contains('En az bir gelir'));
      await expectLater(repo.delete('maas'), throwsA(isA<CategoryException>()));
      expect(repo.deleteBlocker('kira'), isNull);
      await repo.delete('kira');
      expect(repo.deleteBlocker('market'), contains('En az bir gider'));
    });

    test('Türün son kategorisinin türü değiştirilemez', () async {
      final maas = repo.getById('maas')!;
      await expectLater(repo.save(maas.copyWith(isIncome: false)), throwsA(isA<CategoryException>()));
    });
  });

  group('Kategori sağlayıcısı', () {
    late ProviderContainer container;
    setUp(() => container = boxes.container());
    tearDown(() => container.dispose());

    Transaction tx(String categoryId, {bool income = false}) =>
        Transaction(amount: 100, categoryId: categoryId, date: DateTime(2026, 11, 1), isIncome: income);

    test('Ekleme ve silme listeyi anında günceller', () async {
      final notifier = container.read(categoriesProvider.notifier);
      final added = await notifier.save(
          Category(name: 'Aidat', icon: '🏢', colorValue: 0, isIncome: false));
      expect(container.read(categoriesProvider).map((c) => c.name), contains('Aidat'));
      expect(container.read(categoryMapProvider)[added.id]!.name, 'Aidat');

      await notifier.delete(added.id);
      expect(container.read(categoriesProvider).map((c) => c.name), isNot(contains('Aidat')));
      expect(boxes.categories.get(added.id), isNull);
    });

    test('Kullanılan kategori, hedef verilmeden silinemez', () async {
      await container.read(transactionsProvider.notifier).add(tx('market'));
      final notifier = container.read(categoriesProvider.notifier);
      await expectLater(notifier.delete('market'), throwsA(isA<CategoryException>()));
      expect(boxes.categories.get('market'), isNotNull);
    });

    test('Silmede işlemler aynı türden kategoriye taşınır', () async {
      final txs = container.read(transactionsProvider.notifier);
      final a = tx('market');
      final b = tx('market');
      final c = tx('kira');
      await txs.add(a);
      await txs.add(b);
      await txs.add(c);

      final notifier = container.read(categoriesProvider.notifier);
      // Farklı türe taşıma reddedilir.
      await expectLater(notifier.delete('market', moveToId: 'maas'), throwsA(isA<CategoryException>()));
      // Kendisine taşıma reddedilir.
      await expectLater(notifier.delete('market', moveToId: 'market'), throwsA(isA<CategoryException>()));

      final moved = await notifier.delete('market', moveToId: 'kira');
      expect(moved, 2);
      expect(boxes.categories.get('market'), isNull);
      expect(boxes.transactions.values.every((t) => t.categoryId == 'kira'), isTrue);
      expect(container.read(transactionsProvider).every((t) => t.categoryId == 'kira'), isTrue);
      // Taşınan işlemin kimliği ve oluşturulma zamanı korunur.
      expect(boxes.transactions.get(a.id)!.createdAt, a.createdAt);
    });

    test('İşlemi olan kategorinin türü değiştirilemez', () async {
      await container.read(transactionsProvider.notifier).add(tx('kira'));
      final notifier = container.read(categoriesProvider.notifier);
      final kira = container.read(categoryMapProvider)['kira']!;
      await expectLater(notifier.save(kira.copyWith(isIncome: true)), throwsA(isA<CategoryException>()));
    });
  });
}
