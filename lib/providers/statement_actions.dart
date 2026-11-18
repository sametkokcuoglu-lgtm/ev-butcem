import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_statement.dart';
import '../models/credit_card.dart';
import 'wallet_providers.dart';

/// Saves statements and keeps the linked card debt aligned with payments.
class StatementActions {
  const StatementActions(this._ref);

  final WidgetRef _ref;

  Future<void> save(
    CardStatement statement, {
    CardStatement? previous,
  }) async {
    final normalized = statement.normalized();
    await _applyDebt(
      cardId: normalized.creditCardId,
      previousPaid: previous?.paidAmount ?? 0,
      nextPaid: normalized.paidAmount,
    );
    await _ref.read(statementsProvider.notifier).save(normalized);
  }

  Future<void> markPaid(CardStatement statement) {
    return save(statement.markPaid(), previous: statement);
  }

  Future<void> delete(CardStatement statement) async {
    await _applyDebt(
      cardId: statement.creditCardId,
      previousPaid: statement.paidAmount,
      nextPaid: 0,
    );
    await _ref.read(statementsProvider.notifier).delete(statement.id);
  }

  Future<void> deleteCard(CreditCard card) async {
    final related = _ref
        .read(statementsProvider)
        .where((statement) => statement.creditCardId == card.id)
        .toList();
    for (final statement in related) {
      await _ref.read(statementsProvider.notifier).delete(statement.id);
    }
    await _ref.read(creditCardsProvider.notifier).delete(card.id);
  }

  Future<void> _applyDebt({
    required String cardId,
    required double previousPaid,
    required double nextPaid,
  }) async {
    CreditCard? card;
    for (final candidate in _ref.read(creditCardsProvider)) {
      if (candidate.id == cardId) {
        card = candidate;
        break;
      }
    }
    if (card == null || previousPaid == nextPaid) return;
    final nextDebt = StatementLedger.debtAfterPaidChange(
      debt: card.currentDebt,
      previousPaid: previousPaid,
      nextPaid: nextPaid,
    );
    await _ref
        .read(creditCardsProvider.notifier)
        .save(card.copyWith(currentDebt: nextDebt));
  }
}
