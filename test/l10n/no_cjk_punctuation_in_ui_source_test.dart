// The guard that would have caught the defect nine widget tests missed.
//
// `powertrain_battery_catalog_screen.dart` joined signal names with `、`
// (U+3001, an ideographic comma). Every word around it was translated, so the
// English build rendered "Battery temperature 1、Battery temperature 2" for 18
// of the 51 catalogue commands — and eight of the nine per-screen tests matched
// Han characters only, so not one of them saw it.
//
// A widget test cannot reliably reach this class of bug: it only appears when a
// list has two or more elements, and a fixture with one element per command
// never renders a separator at all. That is exactly what happened. So this
// checks the source instead, where the literal either exists or does not.
//
// It reads lib/ui, lib/state and lib/diagnostics. lib/obd is excluded because
// it carries whole Chinese sentences by design until #45 and #46 move them, and
// punctuation inside a Chinese sentence is correct. The other two were added
// after a reviewer pointed out that `lib/state/dtc_scan.dart` and
// `lib/state/pid_registry.dart` also `join('、')`: correct today, because the
// sentences around them are still Chinese, and invisible on the day those move.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/cjk.dart';
import '../support/dart_source_reader.dart';

/// Deliberate CJK punctuation that is data or a self-name, not copy. Matched by
/// exact line content so a new one has to be added here on purpose.
///
/// Empty, and that is the finding. It used to hold four lines — the language
/// picker's two, the Shopee match, the location-permission comparison — and a
/// reviewer showed that none of them was being excused by anything: every one
/// contains Han characters and no CJK *punctuation*, so the scan skipped them
/// two conditions earlier regardless. An allowlist whose entries protect
/// nothing is worse than none, because it implies the scan was tuned against
/// real exceptions and invites the next person to add a fifth.
///
/// The test below now proves each entry would actually be flagged, so an
/// allowance that stops mattering fails instead of accumulating.
///
/// What it holds instead is the six lines the widened scan found in lib/state
/// and lib/diagnostics. Every one composes a sentence for a **telemetry export
/// or an attempt transcript**, where the language is frozen in Traditional
/// Chinese on purpose — an evidence file whose wording follows a phone setting
/// is one that two readers cannot compare. The Chinese words are in the
/// interpolated variables, so the line itself has no Han character and the scan
/// cannot tell it apart from a separator left behind mid-translation. Nothing
/// here reaches a screen; `export_labels_stay_off_screen_test.dart` (on the
/// #45 branch) is what keeps it that way.
const _allowed = <String>{
  // The exported disagreement list on a multi-controller DTC scan.
  "            '\${disagreements.join('；')}。'",
  // Attempt transcript and evidence header, both written to a file.
  "          '# ATDPN：\${_evidenceHeaderValue(c.protocolNumber, whenEmpty: '—')}',",
  "    _attemptTranscript?.recordNote('\$prefix：\${detail ?? why}');",
  // The exported assumptions sentence, composed by _exportNote.
  "  ) => assumptionsFor(profile, kind).map(_exportNote).join('；');",
  "        : '\$name \$value（\${_originLabel(origin)}）';",
};

/// The directories this reads, in a fixed order so failures list consistently.
Iterable<File> get _scanned sync* {
  for (final dir in ['lib/ui', 'lib/state', 'lib/diagnostics']) {
    for (final entity in Directory(dir).listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) yield entity;
    }
  }
}

/// [src] with its comments blanked, line for line.
///
/// This used to be `line.indexOf('//')` and a substring, which was defended in
/// a long comment as the right trade: it truncated at the `//` of a URL, so it
/// could miss, and in one arrangement — CJK punctuation before the URL and
/// every Han character after it, `const note = '「https://example.com/x」的說明'`
/// — it could also accuse a line that was fine.
///
/// Neither cost was worth paying, because the parser the comment did not want
/// to write already exists: `test/support/dart_source_reader.dart`, shared
/// with the transport guard and the identifier guard, with fixtures pinning
/// the two bugs it has actually had. String literals are kept deliberately —
/// see the scan below on why this is a whole-line check and not a literal one.
List<String> _codeLines(String source) => withoutComments(source).split('\n');

void main() {
  test('no CJK punctuation is hardcoded in a lib/ui string literal', () {
    final offenders = <String>[];
    for (final entity in _scanned) {
      final source = entity.readAsStringSync();
      final lines = source.split('\n');
      // A trailing Chinese comment is not Chinese copy, and leaving it in
      // masked the whole check: this codebase writes `// 以頓號分隔清單` at
      // the end of lines constantly, and a reviewer proved that adding
      // `xs.join('、'); // 以頓號分隔清單` to panel.dart passed the scan.
      // A whole comment line goes blank the same way, so there is no prefix
      // test here any more.
      final stripped = _codeLines(source);
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (_allowed.contains(line)) continue;
        final code = stripped[i];
        if (!cjkPunctuation.hasMatch(code)) continue;
        // A line of Chinese copy carries Chinese punctuation, and that is
        // correct. What this catches is punctuation with no Chinese word
        // anywhere on the line — a separator or a bracket left behind while
        // the words around it were translated.
        //
        // Whole lines, not string literals: `'\${xs.join('、')}'` nests quotes
        // inside an interpolation, and a literal matcher stops at the inner
        // quote and never sees the comma. That is not hypothetical — it is how
        // the first version of this test passed against the real defect.
        if (han.hasMatch(code)) continue;
        offenders.add(
          '${entity.path}:${i + 1}  ${chineseIn(code)}  in  ${line.trim()}',
        );
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'CJK punctuation with no Chinese around it is a separator or bracket '
          'that was missed while the words were translated:\n'
          '${offenders.join('\n')}',
    );
  });

  test('the reader: a `//` inside a string does not truncate the line', () {
    // This replaced a test that asserted no line in these directories put a
    // `//` inside a string literal. That was not a property of the code — it
    // was a precondition of the naive `indexOf('//')` stripper, and its own
    // comment said so: "if this ever fails, `_code` needs to become
    // quote-aware." It is quote-aware now, so the precondition is gone and
    // asserting it would forbid a URL for no reason.
    //
    // What has to hold instead is that the reader itself survives the shapes
    // the old stripper did not. Fixtures, not the real sources: the real
    // sources are supposed to be clean, so a green run over them proves the
    // scan found nothing rather than that it could have.
    List<String> codeOf(String src) => _codeLines(src);

    expect(
      codeOf("final u = 'https://a/、b';").single,
      contains('、'),
      reason: 'the `//` of a URL is inside a literal and starts no comment — '
          'truncating there is how a real separator stayed invisible',
    );
    expect(
      codeOf("final x = 1; // 以頓號分隔清單、二").single,
      isNot(contains('、')),
      reason: 'a trailing comment is still a comment',
    );
    final wholeLine = codeOf("// 、\nfinal y = 2;");
    expect(wholeLine, hasLength(2));
    expect(
      wholeLine.first,
      isNot(contains('、')),
      reason: 'a whole comment line blanks',
    );
    expect(
      wholeLine.last,
      'final y = 2;',
      reason: 'and it does not eat the line after it',
    );
    expect(
      codeOf("/* 、\n、 */\nfinal z = 3;").last,
      'final z = 3;',
      reason: 'a block comment spans lines and stops at its close',
    );
    expect(
      codeOf("final q = 'it\\'s、';").single,
      contains('、'),
      reason: 'an escaped quote does not close the literal early',
    );
  });

  test('every exception is still present AND would still be flagged', () {
    // An allowlist nobody prunes is how a check rots into a rubber stamp — and
    // the previous version only checked half of that. It asserted each line
    // still existed in the source, not that the line still needed excusing, so
    // four entries that the scan already skipped for other reasons were kept
    // alive by a passing test.
    final source = <String>[];
    for (final entity in _scanned) {
      source.addAll(entity.readAsLinesSync());
    }
    final problems = <String>[];
    for (final line in _allowed) {
      if (!source.contains(line)) {
        problems.add('gone from the source, delete it: $line');
        continue;
      }
      final code = _codeLines(line).single;
      if (!cjkPunctuation.hasMatch(code) || han.hasMatch(code)) {
        problems.add('excuses nothing — the scan skips it anyway: $line');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
