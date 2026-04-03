#!/usr/bin/env dart
// ignore_for_file: avoid_print

// Single-file quality check for Claude Code PostToolUse hook.
// Non-blocking (always exits 0) — prints warnings only.
//
// Usage: dart run scripts/check_single_file.dart <file_path>
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) exit(0);

  final filePath = args.first;
  if (!filePath.endsWith('.dart') || !filePath.startsWith('lib/')) exit(0);
  if (filePath.endsWith('.g.dart') || filePath.endsWith('.freezed.dart')) {
    exit(0);
  }

  final file = File(filePath);
  if (!file.existsSync()) exit(0);

  final content = file.readAsStringSync();
  final lines = content.split('\n');
  final warnings = <String>[];

  // File length (simplified — no config parsing for speed)
  final limit = _fileLimit(filePath);
  if (lines.length > limit) {
    warnings.add('$filePath: ${lines.length} lines (limit $limit)');
  }

  // Cross-feature imports
  final featureMatch = RegExp(r'lib/features/([^/]+)/').firstMatch(filePath);
  if (featureMatch != null) {
    final own = featureMatch.group(1)!;
    for (final line in lines) {
      final importMatch = RegExp(r'features/([^/]+)/').firstMatch(line);
      if (line.trimLeft().startsWith('import ') &&
          importMatch != null &&
          importMatch.group(1) != own) {
        warnings.add(
          '$filePath: cross-feature import from ${importMatch.group(1)}',
        );
      }
    }
  }

  // Presentation-layer checks
  if (filePath.contains('/presentation/') ||
      filePath.startsWith('lib/widgets/')) {
    // FutureBuilder/StreamBuilder
    if (content.contains('FutureBuilder') ||
        content.contains('StreamBuilder')) {
      warnings.add(
        '$filePath: uses FutureBuilder/StreamBuilder — prefer Riverpod',
      );
    }

    // Missing Semantics
    final hasInteractive = [
      'InkWell',
      'GestureDetector',
      'IconButton',
    ].any((w) => content.contains(w));
    if (hasInteractive && !content.contains('Semantics(')) {
      warnings.add('$filePath: interactive widgets without Semantics labels');
    }
  }

  if (warnings.isEmpty) exit(0);

  stderr.writeln('[quality] ${warnings.length} warning(s):');
  for (final w in warnings) {
    stderr.writeln('  $w');
  }
}

int _fileLimit(String path) {
  if (path.contains('_screen.dart') || path.contains('_page.dart')) return 200;
  if (path.contains('/viewmodels/') || path.contains('_notifier.dart')) {
    return 150;
  }
  if (path.contains('/data/') && !path.contains('/entities/')) return 200;
  if (path.contains('/usecases/')) return 50;
  if (path.contains('/entities/') || path.contains('/dto/')) return 100;
  if (path.contains('/utils/')) return 100;
  return 200;
}
