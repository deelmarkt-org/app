// Staling check for `docs/SCREENS-INVENTORY.md`.
//
// Reads the `Last updated:` header and:
//   - prints OK and exits 0 if file is fresh (≤ 60 days)
//   - prints a warning and exits 0 if file is stale (61–119 days)
//   - prints an error and exits 1 if file is rotten (≥ 120 days)
//
// Reference: `docs/PLAN-P57-screens-inventory-refresh.md`
//
// Usage: `dart run scripts/check_screens_inventory.dart [path]`
//
// The optional `path` argument allows the test suite to point the script
// at a fixture file. Defaults to `docs/SCREENS-INVENTORY.md` relative to
// the current working directory.
import 'dart:io';

const int warnDays = 60;
const int failDays = 120;

const String _headerPattern =
    r'\*\*Last updated:\*\*\s+(\d{4})-(\d{2})-(\d{2})';

/// Result of a staling check, exposed for unit tests.
class StalingResult {
  StalingResult({
    required this.exitCode,
    required this.message,
    required this.daysSinceUpdate,
  });

  final int exitCode;
  final String message;
  final int? daysSinceUpdate;
}

/// Compute the staling result for [contents], measured against [now].
StalingResult evaluate(String contents, {DateTime? now}) {
  final stamp = DateTime.now();
  final today = now ?? stamp;
  final match = RegExp(_headerPattern).firstMatch(contents);
  if (match == null) {
    return StalingResult(
      exitCode: 1,
      message:
          'ERROR: SCREENS-INVENTORY.md is missing the "**Last updated:** YYYY-MM-DD" header.',
      daysSinceUpdate: null,
    );
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  // Use UTC for both anchors so DST transitions in the interval do not
  // produce off-by-one results (e.g. crossing late-March in Europe shortens
  // local-time spans by 1 hour and floors `inDays` from 120 to 119).
  final lastUpdated = DateTime.utc(year, month, day);
  final ref = DateTime.utc(today.year, today.month, today.day);
  final ageDays = ref.difference(lastUpdated).inDays;

  if (ageDays >= failDays) {
    return StalingResult(
      exitCode: 1,
      message:
          'ERROR: SCREENS-INVENTORY.md is $ageDays days old (≥ $failDays). '
          'Run a refresh per docs/PLAN-P57-screens-inventory-refresh.md.',
      daysSinceUpdate: ageDays,
    );
  }
  if (ageDays >= warnDays) {
    return StalingResult(
      exitCode: 0,
      message:
          'WARN: SCREENS-INVENTORY.md is $ageDays days old (≥ $warnDays). '
          'Schedule a refresh; will fail at $failDays days.',
      daysSinceUpdate: ageDays,
    );
  }
  return StalingResult(
    exitCode: 0,
    message: 'OK: SCREENS-INVENTORY.md is $ageDays days old.',
    daysSinceUpdate: ageDays,
  );
}

Future<void> main(List<String> args) async {
  final path = args.isNotEmpty ? args.first : 'docs/SCREENS-INVENTORY.md';
  final file = File(path);
  // ignore: avoid_slow_async_io — synchronous existsSync would be faster but
  // this is a CLI script run once per pre-push, not a hot path; readability wins.
  if (!file.existsSync()) {
    stderr.writeln('ERROR: $path does not exist.');
    exit(1);
  }
  final contents = await file.readAsString();
  final result = evaluate(contents);
  if (result.exitCode == 0 && result.message.startsWith('WARN')) {
    stderr.writeln(result.message);
  } else if (result.exitCode != 0) {
    stderr.writeln(result.message);
  } else {
    stdout.writeln(result.message);
  }
  exit(result.exitCode);
}
