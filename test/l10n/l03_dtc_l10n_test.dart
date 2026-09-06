/// The fault-code screen in both languages.
///
/// This is the highest-stakes copy in the app: three classes of code that must
/// stay three distinguishable things, a permanent class that must never read as
/// clearable, an all-clear that is only ever a claim about the controllers that
/// answered, and a clear button that destroys the freeze frame for good.
///
/// What these check is deliberately NOT "does the widget show the ARB entry" —
/// a finder that reads the same ARB the widget rendered agrees with itself no
/// matter how wrong the translation is. They check the properties a wrong
/// translation breaks: that English renders no Chinese, that the Chinese hedges
/// survived the move into the ARBs, that the three code classes never collapse
/// into one another, and that the load-bearing qualifiers are still in the
/// English sentence.
///
/// `_engineOwnedStrings` is the one deliberate hole, and it is the report's
/// `stringsRemaining` in executable form: everything on this screen that comes
/// from `lib/obd/`, which a later wave owns. Anything Chinese that is NOT in
/// that list is copy this screen still hard-codes, and the assertion fails.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/dtc/dtc.dart';
import 'package:torque_obd/obd/freeze_frame.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/readiness.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/dtc_scan.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/ui/screens/dtc/dtc_screen.dart';

import '../support/localized_app.dart';
import '../support/cjk.dart';

/// Han AND CJK punctuation, from the shared detector in test/support/cjk.dart.
///
/// This file used to define a Han-only regex of its own. Eight of the nine wave
/// test files did, and that gap shipped a defect: an English list joined with
/// `、` passed every one of them, because every word was translated and only
/// the separator was not.
final _cjk = chinese;

final _en = lookupAppLocalizations(englishLocale);
final _zh = lookupAppLocalizations(traditionalChineseLocale);

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

class _FixedScan extends DtcScanNotifier {
  _FixedScan(this.initial);
  final DtcScanState initial;
  @override
  DtcScanState build() => initial;
}

class _FixedSession extends ObdSession {
  _FixedSession({this.connected = true});
  final bool connected;
  @override
  ObdConnectionState build() => connected
      ? const ObdConnectionState(
          phase: ConnectionPhase.connected,
          kind: TransportKind.demo,
          deviceName: 'Demo ECU',
        )
      : const ObdConnectionState();
}

/// Failure text written by `lib/state/dtc_scan.dart` and the engine, quoted
/// here so the no-Chinese assertion can subtract it rather than pretend the
/// screen never shows it.
const _engineFailureMessage = '有 1 個控制器沒有回應';
const _engineScanError = '掃描逾時，沒有讀到完整結果';
const _engineClearMessage = '已有控制器回報清除完成，但其餘控制器無法確認。';
const _engineDecodeError = '收到的資料不正確';

const _misfire = Dtc(
  code: 'P0301',
  category: DtcCategory.powertrain,
  kind: DtcKind.stored,
  sourceId: '7E8',
  isManufacturerSpecific: false,
);

/// No generic description and no manufacturer-specific flag, so the screen
/// falls back to the subsystem its own third digit names.
const _subsystemOnly = Dtc(
  code: 'P0492',
  category: DtcCategory.powertrain,
  kind: DtcKind.pending,
  sourceId: '7E9',
  isManufacturerSpecific: false,
);

/// Manufacturer-specific: the app has no description and must say so rather
/// than invent one.
const _manufacturer = Dtc(
  code: 'P1234',
  category: DtcCategory.powertrain,
  kind: DtcKind.permanent,
  isManufacturerSpecific: true,
);

DtcCategoryResult _silent({Set<String> answeredBy = const {}}) =>
    DtcCategoryResult.failed(DtcReadException(
      _engineFailureMessage,
      kind: DtcReadFailure.noAnswer,
      terminalSources: answeredBy,
    ));

FreezeFrame _frame({int undecodable = 0, int unread = 0}) => FreezeFrame(
      source: '7E8',
      frameNumber: 0,
      cause: _misfire,
      readings: const [
        FreezeReading(pid: PidLibrary.engineRpm, value: 2856, raw: [0x2C, 0xA0]),
        FreezeReading(pid: PidLibrary.coolantTemp, value: 91, raw: [131]),
      ],
      undecodable: undecodable,
      unread: unread,
    );

Future<void> _pump(
  WidgetTester tester,
  DtcScanState scan, {
  required Locale locale,
  bool connected = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dtcScanProvider.overrideWith(() => _FixedScan(scan)),
        obdSessionProvider
            .overrideWith(() => _FixedSession(connected: connected)),
      ],
      child: localizedMaterialApp(
        theme: AppTheme.dark(),
        locale: locale,
        home: const DtcScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}

// ---------------------------------------------------------------------------
// The screen states worth rendering
// ---------------------------------------------------------------------------

const _notScanned = DtcScanState();

const _readFailed = DtcScanState(error: _engineScanError);

/// Every class answered, by everybody, and nothing was found.
final _completeClean = DtcScanState(
  scannedAt: DateTime(2026, 8, 17),
  results: {
    for (final kind in DtcKind.values) kind: const DtcCategoryResult.codes([]),
  },
);

/// Every class answered, but one controller was never reached by the optional
/// ones — a compliant, healthy car, and still not an all-clear.
final _optionalGaps = DtcScanState(
  scannedAt: DateTime(2026, 8, 17),
  results: {
    for (final kind in DtcKind.values) kind: const DtcCategoryResult.codes([]),
  },
  optionalNotCovered: const {
    DtcKind.pending: {'7E9'},
    DtcKind.permanent: {'7E9'},
  },
);

/// Mode 0A never answered: ordinary silence, because Mode 03 did.
final _permanentSilent = DtcScanState(
  scannedAt: DateTime(2026, 8, 17),
  results: {
    DtcKind.stored: const DtcCategoryResult.codes([]),
    DtcKind.pending: const DtcCategoryResult.codes([]),
    DtcKind.permanent: _silent(),
  },
);

/// The mandatory class went unanswered, so there is no scan at all.
final _storedSilent = DtcScanState(
  scannedAt: DateTime(2026, 8, 17),
  results: {
    DtcKind.stored: _silent(),
    DtcKind.permanent: _silent(),
  },
);

final _faultsFound = DtcScanState(
  scannedAt: DateTime(2026, 8, 17),
  results: {
    DtcKind.stored: const DtcCategoryResult.codes([_misfire]),
    DtcKind.pending: const DtcCategoryResult.codes([_subsystemOnly]),
    DtcKind.permanent: const DtcCategoryResult.codes([_manufacturer]),
  },
  clearMessage: _engineClearMessage,
);

final _withFrames = DtcScanState(
  scannedAt: DateTime(2026, 8, 17),
  results: {
    DtcKind.stored: const DtcCategoryResult.codes([_misfire]),
  },
  freezeFrames: [_frame(undecodable: 2, unread: 3)],
  freezeFrameUnread: true,
);

final _withReadiness = DtcScanState(
  scannedAt: DateTime(2026, 8, 17),
  results: {
    for (final kind in DtcKind.values) kind: const DtcCategoryResult.codes([]),
  },
  mil: MilStatus({
    '7E8': MilSummary(
      milOn: true,
      confirmedCount: 3,
      // Compression ignition, so bytes C and D carry unnamed monitors as well
      // as named ones — both chip kinds render.
      readiness: Readiness.decode(0x08, 0x05, 0x05),
    ),
    '7E9': const MilSummary(milOn: false, confirmedCount: 0),
  }),
);

Map<String, DtcScanState> get _states => {
      'not scanned': _notScanned,
      'read failed': _readFailed,
      'complete clean': _completeClean,
      'optional gaps': _optionalGaps,
      'permanent silent': _permanentSilent,
      'stored silent': _storedSilent,
      'faults found': _faultsFound,
      'freeze frames': _withFrames,
      'readiness': _withReadiness,
    };

// ---------------------------------------------------------------------------
// Reading the screen back
// ---------------------------------------------------------------------------

Iterable<String> _renderedStrings(WidgetTester tester) sync* {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final data = text.data;
    if (data != null) yield data;
    final span = text.textSpan;
    if (span != null) yield span.toPlainText();
  }
  for (final text
      in tester.widgetList<SelectableText>(find.byType(SelectableText))) {
    final data = text.data;
    if (data != null) yield data;
  }
  for (final tooltip in tester.widgetList<Tooltip>(find.byType(Tooltip))) {
    final message = tooltip.message;
    if (message != null) yield message;
  }
  for (final semantics in tester.widgetList<Semantics>(find.byType(Semantics))) {
    final label = semantics.properties.label;
    if (label != null) yield label;
  }
}

/// Everything this screen renders that it does not own.
///
/// `lib/obd/dtc/dtc.dart` and `lib/obd/readiness.dart` are the diagnostic
/// engine and belong to a later localization wave; `lib/state/dtc_scan.dart`
/// writes the scan error and the clear outcome. This branch cannot translate
/// any of it, so the assertion below subtracts it and then insists that
/// nothing Chinese is left.
///
/// Keeping the list computed from the enums rather than typed out means a new
/// engine label cannot quietly widen the hole.
List<String> _engineOwnedStrings() => [
      for (final kind in DtcKind.values) ...[kind.label, kind.description],
      for (final category in DtcCategory.values) category.label,
      for (final monitor in ReadinessMonitor.values) monitor.label,
      ...DtcDecoder.powertrainSubsystems.values,
      ...DtcDecoder.genericDescriptions.values,
      PidLibrary.engineRpm.name,
      PidLibrary.coolantTemp.name,
      _engineFailureMessage,
      _engineScanError,
      _engineClearMessage,
      _engineDecodeError,
    ]..sort((a, b) => b.length.compareTo(a.length));

String _withoutEngineCopy(String value) {
  var stripped = value;
  for (final engine in _engineOwnedStrings()) {
    stripped = stripped.replaceAll(engine, '');
  }
  return stripped;
}

List<String> _chineseLeftInEnglish(WidgetTester tester) => [
      for (final rendered in _renderedStrings(tester))
        if (_cjk.hasMatch(_withoutEngineCopy(rendered))) rendered,
    ];

void main() {
  // -------------------------------------------------------------------------
  group('English renders no Chinese', () {
    for (final entry in _states.entries) {
      testWidgets(entry.key, (tester) async {
        await _pump(tester, entry.value, locale: englishLocale);
        expect(
          _chineseLeftInEnglish(tester),
          isEmpty,
          reason: 'these reach an English-speaking driver in Chinese, and are '
              'not among the engine strings a later wave owns',
        );
      });
    }

    testWidgets('not connected', (tester) async {
      await _pump(
        tester,
        _notScanned,
        locale: englishLocale,
        connected: false,
      );
      expect(_chineseLeftInEnglish(tester), isEmpty);
      expect(find.text(_en.dtcNotConnectedTitle), findsOneWidget);
    });

    testWidgets('the clear confirmation, with all three warnings', (tester) async {
      // Frames to destroy, a frame that may exist and was not read, and a
      // category that never answered — the dialog says all three or it is not
      // saying what the decision rests on.
      await _pump(
        tester,
        DtcScanState(
          scannedAt: DateTime(2026, 8, 17),
          results: {
            DtcKind.stored: const DtcCategoryResult.codes([_misfire]),
            DtcKind.permanent: _silent(),
          },
          freezeFrames: [_frame()],
          freezeFrameUnread: true,
        ),
        locale: englishLocale,
      );
      await tester.tap(find.text(_en.dtcClear));
      await tester.pumpAndSettle();

      expect(find.text(_en.dtcClearDialogTitle), findsOneWidget);
      expect(_chineseLeftInEnglish(tester), isEmpty);

      final dialog = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .firstWhere((t) => t.startsWith(_en.dtcClearDialogBody));
      expect(dialog, contains('P0301'),
          reason: 'the frame this clear destroys is named at the point of no '
              'return');
      expect(dialog, contains(_en.dtcClearDialogFrameUnread));

      await tester.tap(find.text(_en.dtcClearCancel));
      await tester.pumpAndSettle();
    });
  });

  // -------------------------------------------------------------------------
  group('the Traditional Chinese hedges survived the move into the ARBs', () {
    testWidgets('an all-clear is only ever about the controllers that answered',
        (tester) async {
      await _pump(tester, _completeClean, locale: traditionalChineseLocale);
      expect(find.textContaining('已回應的控制器都沒有故障碼'), findsOneWidget);
      expect(find.textContaining('不代表車上每個模組都已被問到'), findsOneWidget,
          reason: 'the qualifier is the whole panel; without it this is a '
              'claim about the vehicle');
    });

    testWidgets('a missing freeze frame is not an absent one', (tester) async {
      await _pump(tester, _withFrames, locale: traditionalChineseLocale);
      expect(find.textContaining('不代表車上沒有'), findsOneWidget);
      expect(find.textContaining('清除故障碼會一併銷毀'), findsOneWidget);
    });

    testWidgets('an unanswered optional class is not a clean one',
        (tester) async {
      await _pump(tester, _permanentSilent, locale: traditionalChineseLocale);
      expect(find.textContaining('無法分辨'), findsOneWidget,
          reason: 'silence cannot tell an unimplemented service from a reply '
              'that was lost');
    });

    testWidgets('the clear says permanent codes are not clearable',
        (tester) async {
      await _pump(tester, _faultsFound, locale: traditionalChineseLocale);
      await tester.tap(find.text(_zh.dtcClear));
      await tester.pumpAndSettle();
      expect(find.textContaining('永久故障碼（Mode 0A）無法清除'), findsOneWidget);
      await tester.tap(find.text(_zh.dtcClearCancel));
      await tester.pumpAndSettle();
    });
  });

  // -------------------------------------------------------------------------
  group('unansweredCategoryWording answers every class in both languages', () {
    // The context-free function this branch converted. Walking it directly is
    // the point of the `AppLocalizations` parameter: no widget tree, both
    // locales, every arm.
    final shapes = <String, DtcCategoryResult Function()>{
      'nobody answered': () => _silent(),
      'somebody answered': () => _silent(answeredBy: const {'7E8'}),
      'a decode error': () => const DtcCategoryResult.failed(
            DtcReadException(_engineDecodeError),
          ),
    };

    test('every kind and every failure shape produces copy', () {
      for (final l10n in [_en, _zh]) {
        for (final kind in DtcKind.values) {
          for (final shape in shapes.entries) {
            for (final storedAnswered in [true, false]) {
              final wording = unansweredCategoryWording(
                l10n: l10n,
                kind: kind,
                result: shape.value(),
                storedAnswered: storedAnswered,
              );
              expect(wording.headline.trim(), isNotEmpty,
                  reason: '$kind / ${shape.key} / stored=$storedAnswered');
              // The one empty arm is unreachable: `ordinarySilence` requires
              // an optional class, so Mode 03 never takes it.
              if (!(kind == DtcKind.stored && wording.ordinarySilence)) {
                expect(wording.detail.trim(), isNotEmpty,
                    reason: '$kind / ${shape.key} / stored=$storedAnswered');
              }
            }
          }
        }
      }
    });

    test('the English copy carries no Chinese of its own', () {
      final offenders = <String>[];
      for (final kind in DtcKind.values) {
        for (final shape in shapes.entries) {
          for (final storedAnswered in [true, false]) {
            final wording = unansweredCategoryWording(
              l10n: _en,
              kind: kind,
              result: shape.value(),
              storedAnswered: storedAnswered,
            );
            for (final line in [wording.headline, wording.detail]) {
              if (_cjk.hasMatch(_withoutEngineCopy(line))) {
                offenders.add('$kind/${shape.key}/$storedAnswered → "$line"');
              }
            }
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('Mode 07 and Mode 0A never share a sentence', () {
      // Pending codes have existed since 1996; permanent codes arrived around
      // 2010. Telling a 2004 owner their car is too old for pending codes is
      // simply wrong, and one shared sentence did exactly that.
      for (final l10n in [_en, _zh]) {
        final pending = unansweredCategoryWording(
          l10n: l10n,
          kind: DtcKind.pending,
          result: _silent(),
          storedAnswered: true,
        );
        final permanent = unansweredCategoryWording(
          l10n: l10n,
          kind: DtcKind.permanent,
          result: _silent(),
          storedAnswered: true,
        );
        expect(pending.ordinarySilence, isTrue);
        expect(permanent.ordinarySilence, isTrue);
        expect(pending.detail, isNot(permanent.detail));
        expect(pending.detail, contains('Mode 07'));
        expect(permanent.detail, contains('Mode 0A'));
      }
    });

    test('a silent mandatory class is never ordinary silence', () {
      for (final l10n in [_en, _zh]) {
        final wording = unansweredCategoryWording(
          l10n: l10n,
          kind: DtcKind.stored,
          result: _silent(),
          storedAnswered: false,
        );
        expect(wording.ordinarySilence, isFalse);
        expect(wording.headline, l10n.dtcUnconfirmed);
        expect(wording.detail, contains('Mode 03'));
      }
    });
  });

  // -------------------------------------------------------------------------
  group('the distinctions this screen refuses to blur', () {
    // Hedge register #11. Added after a review proved the English side was
    // unguarded: rewriting dtcClearDialogFrameUnread to "The vehicle has no
    // freeze frame stored. Go ahead and clear." left all 1905 tests green.
    // The Chinese had a literal guard; English had only en != zh parity and an
    // assertion that read back the same ARB entry the widget had rendered,
    // which passes on any translation including a wrong one.
    //
    // What it would cost: a driver told the vehicle has no freeze frame presses
    // Clear, and the record of the moment the fault occurred — the only data in
    // this app taken while the fault was happening — is destroyed for good,
    // when in fact the app had simply failed to read it and a rescan would have
    // worked.
    test('a freeze frame that was not read is not one that does not exist', () {
      for (final copy in [
        _en.dtcFreezeFrameUnreadPanel,
        _en.dtcClearDialogFrameUnread,
      ]) {
        expect(
          copy.toLowerCase(),
          contains('did not read'),
          reason: 'it must say the read failed, not that nothing exists',
        );
        expect(
          copy.toLowerCase(),
          contains('does not mean the vehicle has none'),
          reason: 'the absence of a reading is not the absence of a frame',
        );
      }
      expect(
        _en.dtcFreezeFrameUnreadPanel.toLowerCase(),
        contains('permanently'),
        reason: 'clearing destroys the frame for good, and must say so',
      );
    });

    test('the destroyed-by-clearing warning survives in English', () {
      // Also register #11, and unguarded for the same reason: parity only.
      expect(_en.dtcFreezeFrameBody('P0301').toLowerCase(), contains('destroys'));
      expect(_en.dtcClearDialogBody.toLowerCase(), contains('cannot be cleared'));
    });

    test('the three code classes stay three things', () {
      for (final l10n in [_en, _zh]) {
        for (final mode in ['Mode 03', 'Mode 07', 'Mode 0A']) {
          expect(l10n.dtcScanBody, contains(mode),
              reason: 'the scan describes what it reads by class');
        }
        final headers = {
          for (final kind in DtcKind.values)
            l10n.dtcGroupHeader(kind.label, kind.mode, 1),
        };
        expect(headers, hasLength(DtcKind.values.length));
      }
    });

    test('a permanent code never reads as something clearing removes', () {
      expect(_zh.dtcClearDialogBody, contains('Mode 0A'));
      expect(_zh.dtcClearDialogBody, contains('無法清除'));
      expect(_en.dtcClearDialogBody, contains('Mode 0A'));
      expect(_en.dtcClearDialogBody.toLowerCase(),
          contains('cannot be cleared'));
    });

    test('the clear says the freeze frame does not come back', () {
      expect(_en.dtcClearDialogFrames('P0301').toLowerCase(),
          contains('cannot be read back'));
      expect(_zh.dtcClearDialogFrames('P0301'), contains('讀不回來'));
    });

    test('"the controllers that answered" is never dropped', () {
      expect(_en.dtcCompleteCleanTitle.toLowerCase(), contains('that answered'));
      expect(_en.dtcCompleteCleanBody.toLowerCase(), contains('does not mean'));
      expect(_en.dtcVerdictCompleteClean.toLowerCase(),
          contains('that answered'),
          reason: 'the header is the line a glance lands on');
      expect(_zh.dtcCompleteCleanTitle, contains('已回應'));
      expect(_zh.dtcVerdictCompleteClean, contains('已回應'));
    });

    test('a read failure is not an unsupported service', () {
      // NO DATA cannot tell an unimplemented service from a lost, filtered or
      // late reply, and this headline used to assert the first.
      expect(_en.dtcSilentCategoryHeadline.toLowerCase(),
          isNot(contains('not support')));
      expect(_en.dtcSilentCategoryHeadline.toLowerCase(),
          isNot(contains('unsupported')));
      expect(_zh.dtcSilentCategoryHeadline, isNot(contains('不支援')));
    });

    test('"no formula here" and "did not come back" ask for different things',
        () {
      // The first is an app limitation a rescan will not change; the second is
      // a read failure a rescan usually fixes. Merging them destroys the
      // user's next action.
      for (final l10n in [_en, _zh]) {
        expect(l10n.dtcFreezeFrameUndecodable(2),
            isNot(l10n.dtcFreezeFrameUnreadItems(2)));
      }
      expect(_en.dtcFreezeFrameUnreadItems(2).toLowerCase(),
          contains('rescan'));
      expect(_en.dtcFreezeFrameUndecodable(2).toLowerCase(),
          isNot(contains('rescan')));
      expect(_zh.dtcFreezeFrameUnreadItems(2), contains('重新掃描'));
      expect(_zh.dtcFreezeFrameUndecodable(2), isNot(contains('重新掃描')));
    });

    test('a missing description says so instead of inventing one', () {
      for (final l10n in [_en, _zh]) {
        expect(l10n.dtcManufacturerSpecific.trim(), isNotEmpty);
        expect(l10n.dtcNoDescriptionForSubsystem('X'), contains('X'));
      }
      expect(_en.dtcNoDescriptionForSubsystem('X').toLowerCase(),
          contains('no detailed description'));
      expect(_zh.dtcNoDescriptionForSubsystem('X'), contains('沒有這一碼的詳細說明'));
    });

    test('an unnamed monitor is still a monitor, not an "other"', () {
      // It is counted into "N still unfinished"; a label that reads as N/A
      // invites the reader to discount it.
      expect(_en.dtcUnknownMonitor.toLowerCase(), contains('unknown'));
      expect(_en.dtcUnknownMonitor.toLowerCase(), isNot(contains('n/a')));
      expect(_en.dtcUnknownMonitor.toLowerCase(), isNot(contains('other')));
      expect(_zh.dtcUnknownMonitor, '未知監控項目');
    });

    test('readiness silence is not readiness', () {
      expect(_en.dtcReadinessSaysNothing.toLowerCase(),
          contains('does not mean'));
      expect(_en.dtcReadinessSaysNothing,
          isNot(_en.dtcReadinessAllComplete));
      expect(_zh.dtcReadinessSaysNothing, contains('不代表已經就緒'));
    });

    test('the disabled clear stays an imperative, not a dead control', () {
      expect(_en.dtcRescanFirst.trim(), isNotEmpty);
      expect(_en.dtcRescanFirst, isNot(_en.dtcClear));
      expect(_zh.dtcRescanFirst, '請先重新掃描');
    });
  });

  // -------------------------------------------------------------------------
  test('every dtc message is actually translated, not an English fallback', () {
    // gen-l10n falls back to the template when a Chinese entry is missing, so
    // the screen looks translated and is not. Nothing on this screen may share
    // a string between the two languages.
    final same = <String>[];
    for (final pair in <(String, String, String)>[
      ('dtcHeadline', _en.dtcHeadline, _zh.dtcHeadline),
      ('dtcNotScanned', _en.dtcNotScanned, _zh.dtcNotScanned),
      ('dtcTotalCodes', _en.dtcTotalCodes(2), _zh.dtcTotalCodes(2)),
      ('dtcVerdictCompleteClean', _en.dtcVerdictCompleteClean,
          _zh.dtcVerdictCompleteClean),
      ('dtcVerdictPartialClean', _en.dtcVerdictPartialClean,
          _zh.dtcVerdictPartialClean),
      ('dtcUnconfirmed', _en.dtcUnconfirmed, _zh.dtcUnconfirmed),
      ('dtcClear', _en.dtcClear, _zh.dtcClear),
      ('dtcClearing', _en.dtcClearing, _zh.dtcClearing),
      ('dtcRescanFirst', _en.dtcRescanFirst, _zh.dtcRescanFirst),
      ('dtcDismiss', _en.dtcDismiss, _zh.dtcDismiss),
      ('dtcClearDialogTitle', _en.dtcClearDialogTitle, _zh.dtcClearDialogTitle),
      ('dtcClearDialogBody', _en.dtcClearDialogBody, _zh.dtcClearDialogBody),
      ('dtcClearDialogFrames', _en.dtcClearDialogFrames('P0301'),
          _zh.dtcClearDialogFrames('P0301')),
      ('dtcClearDialogFrameUnread', _en.dtcClearDialogFrameUnread,
          _zh.dtcClearDialogFrameUnread),
      ('dtcClearDialogUnanswered', _en.dtcClearDialogUnanswered(1, 'x'),
          _zh.dtcClearDialogUnanswered(1, 'x')),
      ('dtcClearCancel', _en.dtcClearCancel, _zh.dtcClearCancel),
      ('dtcClearConfirm', _en.dtcClearConfirm, _zh.dtcClearConfirm),
      ('dtcNotConnectedTitle', _en.dtcNotConnectedTitle,
          _zh.dtcNotConnectedTitle),
      ('dtcNotConnectedBody', _en.dtcNotConnectedBody, _zh.dtcNotConnectedBody),
      ('dtcScanTitle', _en.dtcScanTitle, _zh.dtcScanTitle),
      ('dtcScanBody', _en.dtcScanBody, _zh.dtcScanBody),
      ('dtcReadFailed', _en.dtcReadFailed, _zh.dtcReadFailed),
      ('dtcScanning', _en.dtcScanning, _zh.dtcScanning),
      ('dtcStartScan', _en.dtcStartScan, _zh.dtcStartScan),
      ('dtcRetry', _en.dtcRetry, _zh.dtcRetry),
      ('dtcFreezeFrameUnreadPanel', _en.dtcFreezeFrameUnreadPanel,
          _zh.dtcFreezeFrameUnreadPanel),
      ('dtcCompleteCleanTitle', _en.dtcCompleteCleanTitle,
          _zh.dtcCompleteCleanTitle),
      ('dtcCompleteCleanBody', _en.dtcCompleteCleanBody,
          _zh.dtcCompleteCleanBody),
      ('dtcPartialCleanTitle', _en.dtcPartialCleanTitle,
          _zh.dtcPartialCleanTitle),
      ('dtcPartialCleanOptionalGaps', _en.dtcPartialCleanOptionalGaps(1, '7E9'),
          _zh.dtcPartialCleanOptionalGaps(1, '7E9')),
      ('dtcPartialCleanUnanswered', _en.dtcPartialCleanUnanswered('x'),
          _zh.dtcPartialCleanUnanswered('x')),
      ('dtcGroupHeader', _en.dtcGroupHeader('x', '03', 1),
          _zh.dtcGroupHeader('x', '03', 1)),
      ('dtcManufacturerSpecific', _en.dtcManufacturerSpecific,
          _zh.dtcManufacturerSpecific),
      ('dtcNoDescriptionForSubsystem', _en.dtcNoDescriptionForSubsystem('x'),
          _zh.dtcNoDescriptionForSubsystem('x')),
      ('dtcCategoryFault', _en.dtcCategoryFault('x'), _zh.dtcCategoryFault('x')),
      ('dtcControllerLabel', _en.dtcControllerLabel('7E8'),
          _zh.dtcControllerLabel('7E8')),
      ('dtcPartialCodesRead', _en.dtcPartialCodesRead(2),
          _zh.dtcPartialCodesRead(2)),
      ('dtcSilentCategoryHeadline', _en.dtcSilentCategoryHeadline,
          _zh.dtcSilentCategoryHeadline),
      ('dtcSilentPermanentDetail', _en.dtcSilentPermanentDetail,
          _zh.dtcSilentPermanentDetail),
      ('dtcSilentPendingDetail', _en.dtcSilentPendingDetail,
          _zh.dtcSilentPendingDetail),
      ('dtcStoredSilentDetail', _en.dtcStoredSilentDetail('03'),
          _zh.dtcStoredSilentDetail('03')),
      ('dtcPartiallyAnsweredDetail', _en.dtcPartiallyAnsweredDetail(''),
          _zh.dtcPartiallyAnsweredDetail('')),
      ('dtcBothSilentDetail', _en.dtcBothSilentDetail('0A'),
          _zh.dtcBothSilentDetail('0A')),
      ('dtcReadFailureDetail', _en.dtcReadFailureDetail('x', '03', 'y'),
          _zh.dtcReadFailureDetail('x', '03', 'y')),
      ('dtcUnknownError', _en.dtcUnknownError, _zh.dtcUnknownError),
      ('dtcFreezeFrameTitle', _en.dtcFreezeFrameTitle, _zh.dtcFreezeFrameTitle),
      ('dtcFreezeFrameBody', _en.dtcFreezeFrameBody('P0301'),
          _zh.dtcFreezeFrameBody('P0301')),
      ('dtcFreezeFrameContentsUnknown', _en.dtcFreezeFrameContentsUnknown,
          _zh.dtcFreezeFrameContentsUnknown),
      ('dtcFreezeFrameNothingDecodable', _en.dtcFreezeFrameNothingDecodable,
          _zh.dtcFreezeFrameNothingDecodable),
      ('dtcFreezeFrameUndecodable', _en.dtcFreezeFrameUndecodable(2),
          _zh.dtcFreezeFrameUndecodable(2)),
      ('dtcFreezeFrameUnreadItems', _en.dtcFreezeFrameUnreadItems(2),
          _zh.dtcFreezeFrameUnreadItems(2)),
      ('dtcMilOn', _en.dtcMilOn, _zh.dtcMilOn),
      ('dtcMilOff', _en.dtcMilOff, _zh.dtcMilOff),
      ('dtcSelfReportedCodes', _en.dtcSelfReportedCodes(3),
          _zh.dtcSelfReportedCodes(3)),
      ('dtcSelfReportedNoCodes', _en.dtcSelfReportedNoCodes,
          _zh.dtcSelfReportedNoCodes),
      ('dtcReadinessTitle', _en.dtcReadinessTitle, _zh.dtcReadinessTitle),
      ('dtcReadinessSaysNothing', _en.dtcReadinessSaysNothing,
          _zh.dtcReadinessSaysNothing),
      ('dtcReadinessAllComplete', _en.dtcReadinessAllComplete,
          _zh.dtcReadinessAllComplete),
      ('dtcReadinessIncomplete', _en.dtcReadinessIncomplete(2),
          _zh.dtcReadinessIncomplete(2)),
      ('dtcUnknownMonitor', _en.dtcUnknownMonitor, _zh.dtcUnknownMonitor),
      ('dtcListSeparator', _en.dtcListSeparator, _zh.dtcListSeparator),
    ]) {
      final (key, en, zh) = pair;
      if (en == zh) same.add(key);
      if (_cjk.hasMatch(en)) same.add('$key (Chinese in the English bundle)');
    }
    expect(same, isEmpty,
        reason: 'untranslated or falling back to English: ${same.join(", ")}');
  });

  // -------------------------------------------------------------------------
  test('counts come from the data, not from the prose', () {
    for (final l10n in [_en, _zh]) {
      expect(l10n.dtcTotalCodes(7), contains('7'));
      expect(l10n.dtcReadinessIncomplete(4), contains('4'));
      expect(l10n.dtcSelfReportedCodes(3), contains('3'));
      expect(l10n.dtcFreezeFrameUndecodable(5), contains('5'));
      expect(l10n.dtcFreezeFrameUnreadItems(6), contains('6'));
      expect(l10n.dtcPartialCodesRead(2), contains('2'));
      expect(l10n.dtcClearDialogUnanswered(2, '7E9'), contains('2'));
      expect(l10n.dtcPartialCleanOptionalGaps(2, '7E9'), contains('7E9'));
    }
    // English needs the singular to read as English; Chinese has one form.
    expect(_en.dtcTotalCodes(1), isNot(contains('codes')));
    expect(_en.dtcReadinessIncomplete(1).toLowerCase(), contains('monitor is'));
  });
}
