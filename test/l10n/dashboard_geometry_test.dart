// The dashboard lays out without complaint at the geometries this project
// supports, in both shipped languages.
//
// This is the absolute assertion that `dashboard_polling_mode_help_test.dart`
// could not make. That file is not on `main` — it is on the branch behind
// #123 — and there it renders each geometry twice, polling-mode pill hidden
// and pill shown, asserting the two lists of render-time errors are
// *identical*. It had to: the dashboard overflowed at 640x320 before the pill
// existed, and an absolute check would have failed on a defect that change
// did not introduce. The overflow is fixed, so the comparison can become what
// it was standing in for: nothing complains at all.
//
// What overflowed, and where: the toolbar's side-by-side branch
// (`_WorkspaceToolbar`, `lib/ui/screens/dashboard/dashboard_screen.dart`) put
// the recordings column into a `Row` with no flex factor. A `Row` lays a
// non-flexible child out with unbounded width, so the sentence explaining why
// recordings are unavailable took its full single-line width — 722 px against
// a 608 px row — and the switcher beside it was squeezed to nothing before the
// row overflowed by the remainder.
//
// The groups are deliberately not blind in the same place.
//
//   * the contract from the issue — every supported geometry at both text
//     sizes in both languages, asserting only that nothing complains. It says
//     nothing about which layout branch produced that silence, and every case
//     at 200% text legitimately stacks;
//   * the same geometries with PIDs selected. Without them the gauge area is
//     an empty state and the derived strip refuses to compute, so the dials,
//     tile footnotes and derived cells below the toolbar are laid out by
//     nothing at all and the group above is a claim about a screen missing
//     most of itself;
//   * the band where the toolbar puts two things side by side, pinned by
//     geometry, so that widening the stacking threshold cannot turn the others
//     green by never laying out a `Row` again.
//
// A caveat this file cannot assert and must therefore say: it renders in the
// default test font, where every glyph is one em wide, and the app ships
// SpaceGrotesk. English is close to twice as wide here as on a phone, which is
// why the reported overflow is 126 px at 640x320 in this font and zero there
// with the shipped one. The defect is not an artefact — with the real metrics
// the same `Row` overflows between roughly 460 and 520 logical pixels of
// width — but the number and the geometry are.
// `dashboard_geometry_shipped_font_test.dart` is the same check with the
// shipped font loaded, and it covers that band.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/ui/widgets/gauges/dial_gauge.dart';

import '../support/dashboard_geometry.dart';

void main() {
  const locales = <String, Locale>{
    'en': englishLocale,
    'zh_Hant': chineseLocale,
  };

  group('nothing complains at the supported geometries', () {
    // 320dp is the narrowest width this project supports, 640x320 is the
    // windscreen-mount case, and 200% is the largest step Android's display
    // size and font size controls reach together.
    const geometries = <String, (Size, double)>{
      '320dp portrait': (Size(320, 640), 1),
      'landscape': (Size(640, 320), 1),
      '320dp at 200% text': (Size(320, 640), 2),
      'landscape at 200% text': (Size(640, 320), 2),
    };

    for (final geometry in geometries.entries) {
      for (final locale in locales.entries) {
        testWidgets('${geometry.key}, ${locale.key}', (tester) async {
          final (size, textScale) = geometry.value;
          final at = '${geometry.key}, ${locale.key}';

          final errors = await renderDashboardErrors(
            tester,
            size: size,
            textScale: textScale,
            locale: locale.value,
          );

          expectOverflowShapeRendered(tester, at: at);
          expect(errors, isEmpty, reason: 'the dashboard complained at $at');
        });
      }
    }
  });

  group('nothing complains with a gauge on the wall', () {
    // The group above renders the dashboard with no PIDs selected, where the
    // gauge area is an empty state and the derived strip refuses to compute.
    // Everything below the toolbar — dials, tile footnotes, derived cells,
    // the measured fuel figures — is therefore laid out by nothing there, and
    // "the dashboard lays out at these geometries" would be a claim about a
    // screen with most of itself missing.
    const geometries = <String, (Size, double)>{
      '320dp portrait': (Size(320, 640), 1),
      'landscape': (Size(640, 320), 1),
      '320dp at 200% text': (Size(320, 640), 2),
      'landscape at 200% text': (Size(640, 320), 2),
    };

    for (final geometry in geometries.entries) {
      for (final locale in locales.entries) {
        testWidgets('${geometry.key}, ${locale.key}', (tester) async {
          final (size, textScale) = geometry.value;
          final at = '${geometry.key}, ${locale.key}, with gauges';

          final errors = await renderDashboardErrors(
            tester,
            size: size,
            textScale: textScale,
            locale: locale.value,
            activePids: gaugePids,
            snapshot: gaugeSnapshot(),
          );

          expectOverflowShapeRendered(tester, at: at);
          // Otherwise this group is the one above with slower providers.
          expect(
            find.byType(DialGauge, skipOffstage: false),
            findsWidgets,
            reason: 'no dial was laid out at $at',
          );
          expect(errors, isEmpty, reason: 'the dashboard complained at $at');
        });
      }
    }
  });

  group('nothing complains where the toolbar puts two things side by side', () {
    // The band the side-by-side branch actually covers. Its lower edge is the
    // first width above the toolbar's stacking threshold; above that the
    // branch stays selected however wide the screen gets, and the overflow it
    // produced was not confined to one width — in this font it ran from the
    // threshold to beyond a thousand logical pixels. Text is enlarged but kept
    // under the threshold that stacks, because that is the corner where the
    // sentence is longest and the row is still a row.
    const widths = <double>[462, 640, 1000];
    const textScale = 1.3;

    for (final width in widths) {
      for (final locale in locales.entries) {
        testWidgets('${width.toInt()}dp wide, ${locale.key}', (tester) async {
          final at = '${width.toInt()}x320 at ${textScale}x, ${locale.key}';

          final errors = await renderDashboardErrors(
            tester,
            size: Size(width, 320),
            textScale: textScale,
            locale: locale.value,
          );

          expectOverflowShapeRendered(tester, at: at);
          expectSideBySide(tester, at: at);
          expect(errors, isEmpty, reason: 'the dashboard complained at $at');
        });
      }
    }
  });
}
