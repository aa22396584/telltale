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
// It reads lib/ui only. lib/obd, lib/state and lib/diagnostics still carry
// Chinese by design until #45 and #46 move it, and punctuation inside a Chinese
// sentence is correct.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/cjk.dart';

/// Deliberate CJK that is data or a self-name, not copy. Matched by exact line
/// content so a new one has to be added here on purpose.
const _allowed = <String>{
  // The language picker names each language in its own script, so a reader who
  // cannot read the current one still recognises theirs.
  "    LocalePreference.traditionalChinese => '繁體中文',",
  "    LocalePreference.system => 'System default / 跟隨系統',",
  // A match against catalogue data, not rendered.
  "  '蝦皮' => l10n.recommendedPurchaseStoreShopee,",
  // A comparison against an engine-layer value, not rendered.
  "    deniedLabel == '位置'",
};

void main() {
  test('no CJK punctuation is hardcoded in a lib/ui string literal', () {
    final offenders = <String>[];
    for (final entity in Directory('lib/ui').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
        if (_allowed.contains(line)) continue;
        if (!cjkPunctuation.hasMatch(line)) continue;
        // A line of Chinese copy carries Chinese punctuation, and that is
        // correct. What this catches is punctuation with no Chinese word
        // anywhere on the line — a separator or a bracket left behind while
        // the words around it were translated.
        //
        // Whole lines, not string literals: `'\${xs.join('、')}'` nests quotes
        // inside an interpolation, and a literal matcher stops at the inner
        // quote and never sees the comma. That is not hypothetical — it is how
        // the first version of this test passed against the real defect.
        if (han.hasMatch(line)) continue;
        offenders.add(
          '${entity.path}:${i + 1}  ${chineseIn(line)}  in  ${line.trim()}',
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

  test('the deliberate exceptions are all still present', () {
    // An allowlist nobody prunes is how a check rots into a rubber stamp.
    final source = <String>[];
    for (final entity in Directory('lib/ui').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      source.addAll(entity.readAsLinesSync());
    }
    final stale = _allowed.where((line) => !source.contains(line)).toList();
    expect(
      stale,
      isEmpty,
      reason: 'these exceptions no longer exist and should be deleted:\n'
          '${stale.join('\n')}',
    );
  });
}
