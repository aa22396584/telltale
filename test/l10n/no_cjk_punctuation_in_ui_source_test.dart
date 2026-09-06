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
  "          '# ATDPN：\${_evidenceHeaderValue(c.protocolNumber, whenEmpty: '—')}',",
  // Attempt transcript and evidence header, both written to a file.
  "    _attemptTranscript?.recordNote('\$prefix：\${detail ?? why}');",
  // The exported assumptions sentence: 「車重 1500 kg（通用預設）；Cd 0.30…」
  "            '\${_fieldNote('Cd', profile.dragCoefficient.toStringAsFixed(2), profile.dragCoefficientField.origin)}；'",
  "            'AFR \${profile.stoichAfr.toStringAsFixed(1)}；'",
  "  ) => '\$label \$value（\${_originLabel(origin)}）';",
};

/// The directories this reads, in a fixed order so failures list consistently.
Iterable<File> get _scanned sync* {
  for (final dir in ['lib/ui', 'lib/state', 'lib/diagnostics']) {
    for (final entity in Directory(dir).listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) yield entity;
    }
  }
}

/// The line with any trailing `//` comment removed.
///
/// Naive, and deliberately so: a `//` inside a string literal would truncate
/// the line early, which can only ever make this scan miss something rather
/// than invent an offence, and no line in these directories does that today.
/// Matching Dart's real lexer here would be a parser, and a parser is a second
/// thing to get wrong.
String _code(String line) {
  final at = line.indexOf('//');
  return at < 0 ? line : line.substring(0, at);
}

void main() {
  test('no CJK punctuation is hardcoded in a lib/ui string literal', () {
    final offenders = <String>[];
    for (final entity in _scanned) {
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
        if (_allowed.contains(line)) continue;
        // A trailing Chinese comment is not Chinese copy, and leaving it in
        // masked the whole check: this codebase writes `// 以頓號分隔清單` at
        // the end of lines constantly, and a reviewer proved that adding
        // `xs.join('、'); // 以頓號分隔清單` to panel.dart passed the scan.
        final code = _code(line);
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
      final code = _code(line);
      if (!cjkPunctuation.hasMatch(code) || han.hasMatch(code)) {
        problems.add('excuses nothing — the scan skips it anyway: $line');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
