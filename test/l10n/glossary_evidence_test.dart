// Keeps docs/i18n/glossary.md honest.
//
// A glossary is only worth reviewing against if its claims are still true. Every row cites
// the file where this project already established the pairing; this test opens those files
// and checks the term is still there. Rename a label without touching the glossary and this
// fails — which is the point. Otherwise the glossary decays into folklore within one
// refactor, and reviewers start enforcing a vocabulary the code stopped using.
//
// It deliberately does NOT judge translation quality. It answers one question a machine can
// answer honestly: does the evidence still exist?
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

class _Term {
  _Term(this.zh, this.en, this.status, this.evidence, this.line);
  final String zh;
  final String en;

  /// `evidenced` when both languages already appear in the tree, `proposed` when the
  /// English is a reviewer's invention awaiting maintainer sign-off. Written by hand.
  final String status;
  final String evidence;
  final int line;

  bool get isProposed => status.toLowerCase().startsWith('proposed');
  @override
  String toString() => 'glossary.md:$line  $zh / $en';
}

/// Whitespace removed, so a term wrapped across a source line still matches.
String _collapse(String s) => s.replaceAll(RegExp(r'\s+'), '');

final _citedPath = RegExp(r'(?<![\w/.])((?:lib|test|tool|docs|android|ios|integration_test|store)/[\w./-]+\.\w+|README(?:\.zh-TW)?\.md|CONTRIBUTING\.md|PRIVACY\.md|SECURITY\.md|CHANGELOG\.md|CODE_OF_CONDUCT\.md|pubspec\.yaml|l10n\.yaml)');

List<_Term> _parseGlossary(File file) {
  final terms = <_Term>[];
  final lines = file.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (!line.startsWith('| ')) continue;
    if (line.startsWith('|---')) continue;
    if (line.startsWith('| 繁體中文')) continue;
    // Split on unescaped pipes only; cells may contain "\|".
    final cells = line
        .split(RegExp(r'(?<!\\)\|'))
        .map((c) => c.replaceAll(r'\|', '|').trim())
        .toList();
    // Leading and trailing empties from the outer pipes.
    if (cells.length < 6) continue;
    // Column order in the file is zh | en | evidence | status | note.
    terms.add(_Term(cells[1], cells[2], cells[4], cells[3], i + 1));
  }
  return terms;
}

void main() {
  final glossary = File('docs/i18n/glossary.md');
  final terms = _parseGlossary(glossary);

  test('the glossary parses and is not silently empty', () {
    expect(glossary.existsSync(), isTrue);
    expect(
      terms.length,
      greaterThanOrEqualTo(100),
      reason:
          'only ${terms.length} rows parsed — the table format changed and every check '
          'below would have quietly passed over an empty list',
    );
  });

  test('every row cites at least one file that exists', () {
    final broken = <String>[];
    for (final term in terms) {
      final cited = _citedPath
          .allMatches(term.evidence)
          .map((m) => m.group(1)!)
          .toSet();
      if (cited.isEmpty) {
        broken.add('$term — evidence names no file: "${term.evidence}"');
        continue;
      }
      if (!cited.any((p) => File(p).existsSync())) {
        broken.add('$term — none of $cited exist any more');
      }
    }
    expect(broken, isEmpty, reason: broken.join('\n'));
  });

  test('every cited file still contains the Traditional Chinese term', () {
    final stale = <String>[];
    for (final term in terms) {
      final cited = _citedPath
          .allMatches(term.evidence)
          .map((m) => m.group(1)!)
          .where((p) => File(p).existsSync())
          .toSet();
      if (cited.isEmpty) continue; // reported by the test above
      // Markdown hard-wraps prose, so a Chinese term legitimately present can be split
      // across a line break — 連線世代 is written 連線\n世代 in README.zh-TW.md. Chinese has
      // no word spaces, so collapsing whitespace on both sides is a faithful comparison,
      // not a loosened one.
      final needle = _collapse(term.zh);
      final found = cited.any(
        (p) => _collapse(File(p).readAsStringSync()).contains(needle),
      );
      if (!found) {
        stale.add(
          '$term — "${term.zh}" is in none of $cited. Either the label was renamed '
          'without updating the glossary, or the glossary cited the wrong file.',
        );
      }
    }
    expect(stale, isEmpty, reason: stale.join('\n'));
  });

  test('every cited file still contains the English term', () {
    final stale = <String>[];
    for (final term in terms) {
      if (term.isProposed) continue;
      final cited = _citedPath
          .allMatches(term.evidence)
          .map((m) => m.group(1)!)
          .where((p) => File(p).existsSync())
          .toSet();
      if (cited.isEmpty) continue;
      final needle = term.en.toLowerCase();
      // T3 evidence is a Dart identifier beside a Chinese label, so "oxygen sensor" is
      // evidenced by `oxygenSensor`. Compare both the phrase and its identifier form.
      final identifier = needle.replaceAll(RegExp(r'[^a-z0-9]'), '');
      final found = cited.any((p) {
        final body = File(p).readAsStringSync().toLowerCase();
        if (body.contains(needle)) return true;
        if (_collapse(body).contains(_collapse(needle))) return true;
        return identifier.length >= 4 &&
            body.replaceAll(RegExp(r'[^a-z0-9]'), '').contains(identifier);
      });
      if (!found) {
        stale.add('$term — "${term.en}" is in none of $cited');
      }
    }
    expect(stale, isEmpty, reason: stale.join('\n'));
  });

  test('no term is listed twice with two different English forms', () {
    final byZh = <String, Set<String>>{};
    for (final term in terms) {
      byZh.putIfAbsent(term.zh, () => <String>{}).add(term.en);
    }
    final conflicts = byZh.entries
        .where((e) => e.value.length > 1)
        .map((e) => '${e.key} → ${e.value.join(" / ")}')
        .toList();
    expect(
      conflicts,
      isEmpty,
      reason:
          'one Chinese term with two English forms is how a screen ends up saying two '
          'things for one concept:\n${conflicts.join("\n")}',
    );
  });

  test('the do-not-translate list and the glossary do not contradict each other', () {
    final dnt = File('docs/i18n/do-not-translate.md').readAsLinesSync()
        .where((l) => l.startsWith('- `'))
        .map((l) => l.substring(3, l.lastIndexOf('`')))
        .toSet();
    final contradictions = <String>[];
    for (final term in terms) {
      if (dnt.contains(term.zh) && term.zh != term.en) {
        contradictions.add(
          '"${term.zh}" is on the do-not-translate list but the glossary '
          'translates it to "${term.en}"',
        );
      }
    }
    expect(contradictions, isEmpty, reason: contradictions.join('\n'));
  });
}
