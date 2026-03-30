import 'dart:io';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tier-1 Audit M-04: Verify Dart and SQL state machines remain in sync.
///
/// The transaction state machine is defined in two places:
/// 1. Dart: [TransactionStatus.validTransitions] (lib/core/models/transaction_status.dart)
/// 2. SQL: validate_transaction_status_transition() trigger
///    (supabase/migrations/20260323005955_transaction_state_machine_b24.sql)
///
/// This test parses the SQL migration and verifies every transition rule
/// matches the Dart implementation. If a developer changes one without
/// the other, this test fails at CI time.
void main() {
  group('TransactionStatus Dart↔SQL sync', () {
    late String sqlContent;

    setUpAll(() {
      final sqlFile = File(
        'supabase/migrations/20260323005955_transaction_state_machine_b24.sql',
      );
      if (!sqlFile.existsSync()) {
        fail(
          'SQL migration file not found. '
          'Run this test from the project root.',
        );
      }
      sqlContent = sqlFile.readAsStringSync();
    });

    test('all Dart enum values have a corresponding SQL enum value', () {
      // SQL enum uses snake_case, Dart uses camelCase
      final dartToSql = <TransactionStatus, String>{
        TransactionStatus.created: 'created',
        TransactionStatus.paymentPending: 'payment_pending',
        TransactionStatus.paid: 'paid',
        TransactionStatus.shipped: 'shipped',
        TransactionStatus.delivered: 'delivered',
        TransactionStatus.confirmed: 'confirmed',
        TransactionStatus.released: 'released',
        TransactionStatus.expired: 'expired',
        TransactionStatus.failed: 'failed',
        TransactionStatus.disputed: 'disputed',
        TransactionStatus.resolved: 'resolved',
        TransactionStatus.refunded: 'refunded',
        TransactionStatus.cancelled: 'cancelled',
      };

      expect(
        dartToSql.length,
        equals(TransactionStatus.values.length),
        reason: 'Every Dart enum value must have a SQL mapping',
      );

      for (final entry in dartToSql.entries) {
        expect(
          sqlContent.contains(entry.value),
          isTrue,
          reason:
              '${entry.key.name} (SQL: ${entry.value}) not found in migration',
        );
      }
    });

    test('Dart validTransitions match SQL state machine exactly', () {
      // Parse SQL transition rules from the migration.
      // Format: (OLD.status = 'x' AND NEW.status IN ('a', 'b'))
      final sqlTransitions = _parseSqlTransitions(sqlContent);

      // Build Dart transition map
      final dartTransitions = <String, Set<String>>{};
      final dartToSql = _dartToSqlNames();

      for (final status in TransactionStatus.values) {
        final targets = status.validTransitions;
        if (targets.isNotEmpty) {
          dartTransitions[dartToSql[status]!] =
              targets.map((t) => dartToSql[t]!).toSet();
        }
      }

      // Compare: every Dart transition must be in SQL
      for (final entry in dartTransitions.entries) {
        expect(
          sqlTransitions.containsKey(entry.key),
          isTrue,
          reason: 'Dart has transitions from "${entry.key}" but SQL does not',
        );
        expect(
          sqlTransitions[entry.key],
          equals(entry.value),
          reason:
              'Transition mismatch for "${entry.key}": '
              'Dart=${entry.value}, SQL=${sqlTransitions[entry.key]}',
        );
      }

      // Compare: every SQL transition must be in Dart
      for (final entry in sqlTransitions.entries) {
        expect(
          dartTransitions.containsKey(entry.key),
          isTrue,
          reason: 'SQL has transitions from "${entry.key}" but Dart does not',
        );
        expect(
          dartTransitions[entry.key],
          equals(entry.value),
          reason:
              'Transition mismatch for "${entry.key}": '
              'SQL=${entry.value}, Dart=${dartTransitions[entry.key]}',
        );
      }

      // Same number of source states
      expect(
        sqlTransitions.length,
        equals(dartTransitions.length),
        reason: 'Different number of non-terminal states',
      );
    });

    test('terminal states have no transitions in both Dart and SQL', () {
      final terminalDart =
          TransactionStatus.values.where((s) => s.isTerminal).toList();
      final dartToSql = _dartToSqlNames();

      for (final status in terminalDart) {
        // Dart: no valid transitions
        expect(
          status.validTransitions,
          isEmpty,
          reason: '${status.name} is terminal but has Dart transitions',
        );

        // SQL: not listed as OLD.status source
        final sqlName = dartToSql[status]!;
        final hasSourceRule = RegExp(
          "OLD\\.status\\s*=\\s*'$sqlName'",
        ).hasMatch(sqlContent);
        expect(
          hasSourceRule,
          isFalse,
          reason:
              '$sqlName is terminal but appears as OLD.status in SQL trigger',
        );
      }
    });
  });
}

/// Parse SQL transition rules from the migration content.
///
/// Extracts patterns like:
///   (OLD.status = 'created' AND NEW.status IN ('payment_pending', 'cancelled'))
Map<String, Set<String>> _parseSqlTransitions(String sql) {
  final transitions = <String, Set<String>>{};

  // Match: OLD.status = 'xxx' AND NEW.status IN ('yyy', 'zzz')
  final pattern = RegExp(
    r"OLD\.status\s*=\s*'(\w+)'\s+AND\s+NEW\.status\s+IN\s*\(([^)]+)\)",
    multiLine: true,
  );

  for (final match in pattern.allMatches(sql)) {
    final fromStatus = match.group(1)!;
    final toStatusesRaw = match.group(2)!;
    final toStatuses =
        RegExp(
          r"'(\w+)'",
        ).allMatches(toStatusesRaw).map((m) => m.group(1)!).toSet();
    transitions[fromStatus] = toStatuses;
  }

  return transitions;
}

/// Map Dart enum values to their SQL snake_case equivalents.
Map<TransactionStatus, String> _dartToSqlNames() => {
  TransactionStatus.created: 'created',
  TransactionStatus.paymentPending: 'payment_pending',
  TransactionStatus.paid: 'paid',
  TransactionStatus.shipped: 'shipped',
  TransactionStatus.delivered: 'delivered',
  TransactionStatus.confirmed: 'confirmed',
  TransactionStatus.released: 'released',
  TransactionStatus.expired: 'expired',
  TransactionStatus.failed: 'failed',
  TransactionStatus.disputed: 'disputed',
  TransactionStatus.resolved: 'resolved',
  TransactionStatus.refunded: 'refunded',
  TransactionStatus.cancelled: 'cancelled',
};
