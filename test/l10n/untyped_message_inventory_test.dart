/// Holds [docs/i18n/untyped-message-inventory.md] to the code it names.
///
/// Inventory sites are written relative to `lib/` (`obd/...`, `ui/...`).
/// A remaining (not struck-through) row that names a Dart path must still
/// contain the claimed interpolation in code, not only in a comment. Grouping
/// a cleaned file with a live one is the same defect as leaving a struck
/// interpolation on a screen row.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/dart_source_reader.dart';
import '../support/posix_path.dart';

const _tokens = <String>['failure.message', 'error.message', 'e.message'];

String _code(String path) => codeOnly(File(path).readAsStringSync());

class _Row {
  _Row({required this.site, required this.kind, required this.struck});

  final String site;
  final String kind;
  final bool struck;
}

List<_Row> _inventoryRows() {
  final lines = File('docs/i18n/untyped-message-inventory.md').readAsLinesSync();
  final rows = <_Row>[];
  var inKindTable = false;
  for (final line in lines) {
    if (!line.startsWith('|')) {
      inKindTable = false;
      continue;
    }
    if (line.contains('Site') && line.contains('Kind')) {
      inKindTable = true;
      continue;
    }
    if (!inKindTable) continue;
    if (line.contains('---')) continue;
    final cells = line
        .split('|')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (cells.length < 2) continue;
    final site = cells[0];
    final kind = cells[1];
    rows.add(
      _Row(
        site: site,
        kind: kind,
        struck: site.contains('~~'),
      ),
    );
  }
  return rows;
}

/// Backtick paths in the Site cell, resolved to the committed `lib/` tree.
Iterable<String> _libPaths(String site) sync* {
  final matches = RegExp(r'`([^`]+)`').allMatches(site);
  for (final match in matches) {
    final raw = posixPath(match.group(1)!);
    if (!raw.endsWith('.dart')) continue;
    if (raw.startsWith('lib/')) {
      yield raw;
      continue;
    }
    yield 'lib/$raw';
  }
}

Iterable<String> _namedTokens(String site, String kind) {
  final haystack = '$site $kind';
  return _tokens.where(haystack.contains);
}

void main() {
  test('lib/ui code does not interpolate failure.message', () {
    final files = Directory('lib/ui')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      expect(
        _code(file.path).contains('failure.message'),
        isFalse,
        reason: posixPath(file.path),
      );
    }
  });

  test('remaining inventory rows still have the interpolation they name', () {
    final remaining = _inventoryRows().where((row) => !row.struck).toList();
    expect(remaining, isNotEmpty);
    for (final row in remaining) {
      final paths = _libPaths(row.site).toList();
      expect(paths, isNotEmpty, reason: row.site);
      final named = _namedTokens(row.site, row.kind).toList();
      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: path);
        final code = _code(path);
        expect(
          _tokens.any(code.contains),
          isTrue,
          reason: 'remaining row $path has no error.message / e.message / '
              'failure.message in code',
        );
        for (final token in named) {
          expect(
            code.contains(token),
            isTrue,
            reason: 'remaining row still claims $path interpolates $token',
          );
        }
      }
    }
  });

  test('the remaining pid_csv row names the snack that interpolates e.message', () {
    final remaining = _inventoryRows().where((row) => !row.struck);
    final pidCsv = remaining.where(
      (row) => _libPaths(row.site).contains('lib/obd/pid/pid_csv.dart'),
    );
    expect(pidCsv, isNotEmpty);
    for (final row in pidCsv) {
      expect(
        row.kind.contains('not a locale screen'),
        isFalse,
        reason: 'malformed-CSV e.message reaches pidImportMalformedCsv',
      );
      expect(row.kind.contains('pidImportMalformedCsv'), isTrue);
    }
  });
}
