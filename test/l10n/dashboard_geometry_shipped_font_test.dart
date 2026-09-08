// The same geometry check as `dashboard_geometry_test.dart`, in the font the
// app actually ships.
//
// It exists because the font decides where the defect is. Widget tests render
// in a fixed-width test font whose every glyph is one em wide; the app renders
// SpaceGrotesk, and English is close to half as wide in it. The toolbar
// overflow this pair of files guards therefore lands at different widths in
// the two worlds: 640x320 in the test font, and nothing at all there with the
// shipped one, which instead breaks between roughly 460 and 520 logical pixels
// of width.
//
// That makes the two files complements rather than duplicates. The other one
// asserts the geometries the issue named, and cannot fail for a defect that
// only shows at real text widths. This one renders the band a phone in
// landscape can actually be, with the metrics it will actually have.
//
// Loading a font is process-wide and cannot be undone, which is why this is a
// separate file rather than a second group. A group that loaded the font would
// silently change what the groups declared before it measured, depending on
// the order the runner happened to choose — and it would change them in the
// direction that passes.
//
// Traditional Chinese is here for symmetry, not because it is at risk: no
// glyph in it comes from SpaceGrotesk, so it falls back exactly as it does in
// the other file. It is the control. If a case ever goes red in Chinese and
// stays green in English, the cause is not text width.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/dashboard_geometry.dart';

Future<void> _loadShippedFont() async {
  final loader = FontLoader('SpaceGrotesk')
    ..addFont(
      File('assets/fonts/SpaceGrotesk[wght].ttf').readAsBytes().then(
        (bytes) => ByteData.view(Uint8List.fromList(bytes).buffer),
      ),
    );
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadShippedFont);

  const locales = <String, Locale>{
    'en': englishLocale,
    'zh_Hant': chineseLocale,
  };

  // The band where the shipped metrics put the toolbar's side-by-side branch
  // under pressure: wide enough that it does not stack, narrow enough that the
  // recordings column and the switcher are competing for the row. Both text
  // sizes are below the threshold that stacks, so every case here lays out a
  // `Row`.
  const widths = <double>[462, 470, 500];
  const textScales = <double>[1, 1.3];

  for (final width in widths) {
    for (final textScale in textScales) {
      for (final locale in locales.entries) {
        testWidgets(
          '${width.toInt()}dp wide at ${textScale}x text, ${locale.key}',
          (tester) async {
            final at =
                '${width.toInt()}x320 at ${textScale}x, ${locale.key}, '
                'shipped font';

            final errors = await renderDashboardErrors(
              tester,
              size: Size(width, 320),
              textScale: textScale,
              locale: locale.value,
            );

            expectOverflowShapeRendered(tester, at: at);
            expectSideBySide(tester, at: at);
            expect(errors, isEmpty, reason: 'the dashboard complained at $at');
          },
        );
      }
    }
  }
}
