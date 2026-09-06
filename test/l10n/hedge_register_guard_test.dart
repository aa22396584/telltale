// The hedge register, made executable.
//
// `docs/i18n/hedge-register.md` lists the sentences whose job is to stop a
// reader believing something the evidence does not support, and says for each
// one what a translator may not do to it. It was a document. A reviewer showed
// what that is worth: 31 meaning-inverting edits to shipped English left the
// whole suite green, and three of the register's own entries were among them.
//
// Writing a separate assertion per sentence would have closed those and left
// the next hedge open. This closes the class: an entry that names an ARB key
// is checked against that key's shipped value, so adding a hedge to the
// register *is* adding a guard, and softening one breaks a test rather than
// merely disagreeing with a Markdown file nobody runs.
//
// It cannot check the Chinese the same way — the register's zh text is quoted
// from source files all over the tree, not only from the ARBs, and
// `glossary_evidence_test.dart` already holds those citations to their line
// numbers. What this adds is the half that ships to an English reader.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _entry = RegExp(r'^### (\d+)\. (.*)$');
final _english = RegExp(r'^\*\*English\*\* — (.*)$');
final _shipped = RegExp(r'^\*\*Shipped as\*\* (.*)$');
final _key = RegExp(r'`([A-Za-z][A-Za-z0-9_]*)`');

/// Markdown emphasis and the register's own em-dash conventions are formatting,
/// not copy. A shipped string never contains `**`.
String _plain(String value) => value
    .replaceAll('**', '')
    .replaceAll(' ', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class _Hedge {
  _Hedge(this.number, this.title, this.english, this.keys);
  final int number;
  final String title;
  final String english;
  final List<String> keys;
}

List<_Hedge> _readRegister() {
  final lines = File(
    'docs/i18n/hedge-register.md',
  ).readAsLinesSync();
  final hedges = <_Hedge>[];
  int? number;
  var title = '';
  String? english;
  var keys = <String>[];

  void flush() {
    final n = number;
    final e = english;
    if (n != null && e != null && keys.isNotEmpty) {
      hedges.add(_Hedge(n, title, e, keys));
    }
  }

  for (final line in lines) {
    final entry = _entry.firstMatch(line);
    if (entry != null) {
      flush();
      number = int.parse(entry.group(1)!);
      title = entry.group(2)!;
      english = null;
      keys = <String>[];
      continue;
    }
    final en = _english.firstMatch(line);
    if (en != null) {
      english = _plain(en.group(1)!);
      continue;
    }
    final shipped = _shipped.firstMatch(line);
    if (shipped != null) {
      // Only the backticked identifiers before the closing paren are keys; the
      // prose after it may name files and screens.
      final head = shipped.group(1)!.split(')').first;
      keys = _key.allMatches(head).map((m) => m.group(1)!).toList();
    }
  }
  flush();
  return hedges;
}

Map<String, String> _arb() {
  final raw = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync());
  return <String, String>{
    for (final e in (raw as Map<String, dynamic>).entries)
      if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
  };
}

void main() {
  final hedges = _readRegister();
  final arb = _arb();

  test('the register names keys that exist', () {
    final missing = <String>[];
    for (final hedge in hedges) {
      for (final key in hedge.keys) {
        if (!arb.containsKey(key)) missing.add('#${hedge.number} $key');
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          'A hedge that points at a key which no longer exists guards nothing '
          'and reads as though it does:\n${missing.join('\n')}',
    );
  });

  test('every shipped hedge still says what the register says it says', () {
    // Substring, not equality: several entries record the load-bearing clause
    // rather than the whole shipped sentence, and the ARB entry may add a
    // second sentence around it. What may not happen is the clause going away.
    final broken = <String>[];
    for (final hedge in hedges) {
      for (final key in hedge.keys) {
        final shipped = arb[key];
        if (shipped == null) continue;
        if (!_plain(shipped).contains(hedge.english)) {
          broken.add(
            '#${hedge.number} $key\n'
            '  register: ${hedge.english}\n'
            '  shipped:  ${_plain(shipped)}',
          );
        }
      }
    }
    expect(
      broken,
      isEmpty,
      reason:
          'Shipped copy no longer contains the hedge the register holds it to. '
          'Either the translation was softened — which is the defect this file '
          'exists to catch — or the register is stale and should be updated in '
          'the same change that moved the copy.\n\n${broken.join('\n\n')}',
    );
  });

  test('the register is not quietly empty', () {
    // A parser that silently matched nothing would make both tests above pass
    // for ever. This is the control: it fails if the register's format changes
    // under the regexes rather than letting them go blind.
    expect(
      hedges,
      isNotEmpty,
      reason: 'no register entry parsed — the file format changed',
    );
    final keyed = hedges.where((h) => h.keys.isNotEmpty).length;
    expect(
      keyed,
      greaterThanOrEqualTo(20),
      reason:
          'only $keyed register entries name a shipped key. The register has '
          'more than that; the parser has probably stopped seeing them.',
    );
  });
}
