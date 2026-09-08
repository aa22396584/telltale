// Hand-typed sentences for the #45 identifiers this slice added.
//
// Not read back from AppLocalizations: swapping two switch arms must turn
// this file red.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/dtc/dtc.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/powertrain_battery/profile_pid_installer.dart';
import 'package:torque_obd/obd/transport/ble_transport.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/dtc_scan.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/ui/screens/connect/handshake_copy.dart';
import 'package:torque_obd/ui/screens/dtc/dtc_copy.dart';
import 'package:torque_obd/ui/screens/pids/pid_formula_copy.dart';
import 'package:torque_obd/ui/screens/pids/powertrain_battery_copy.dart';
import 'package:torque_obd/obd/pid/formula_engine.dart';

import '../support/cjk.dart';

final _en = lookupAppLocalizations(englishLocale);
final _zh = lookupAppLocalizations(traditionalChineseLocale);

const _installEnglish = {
  PowertrainProfileInstallIssue.catalogShaMissing: 'Cannot install: this catalog snapshot has no verified SHA-256, so nothing in it can be trusted.',
  PowertrainProfileInstallIssue.profileNotInCatalog:
      'Cannot install: that profile is not in the verified catalog.',
  PowertrainProfileInstallIssue.yearOutOfRange: 'Cannot install: that model year is outside this profile\'s documented year range.',
  PowertrainProfileInstallIssue.profileNotInstallable: 'Cannot install: this profile is not in a state that can become live PIDs.',
  PowertrainProfileInstallIssue.persistFailed: 'Cannot install: the list of installed profiles could not be saved. Try again; nothing was added to PID management.',
};

const _installChinese = {
  PowertrainProfileInstallIssue.catalogShaMissing:
      '無法安裝：這份目錄快照沒有已驗證的 SHA-256，因此其中任何內容都不能信任。',
  PowertrainProfileInstallIssue.profileNotInCatalog: '無法安裝：這個設定檔不在已驗證的目錄中。',
  PowertrainProfileInstallIssue.yearOutOfRange: '無法安裝：該年式不在這個設定檔記載的年份範圍內。',
  PowertrainProfileInstallIssue.profileNotInstallable:
      '無法安裝：這個設定檔目前不能變成實際的 PID。',
  PowertrainProfileInstallIssue.persistFailed:
      '無法安裝：已安裝設定檔清單無法寫入。請再試一次；PID 管理沒有新增任何項目。',
};

const _clearEnglish = {
  DtcClearNoticeKind.confirmed: 'The clear command was sent.',
  DtcClearNoticeKind.partiallyConfirmed: 'At least one controller reported the clear finished, and the rest could not be confirmed. Do not send another clear — repeating it resets emissions readiness on controllers that already finished. Rescan to see the result.',
  DtcClearNoticeKind.sentUnconfirmed: 'The clear command was sent, but the reply was damaged in transit, so it is not known whether the vehicle cleared. Rescan to check; do not send another clear — if it already succeeded, repeating it resets emissions readiness.',
  DtcClearNoticeKind.notAccepted: 'The clear failed; no controller accepted the command. You can try again.',
  DtcClearNoticeKind.timeout: 'Nothing answered after the clear was sent, so it is not known whether the vehicle cleared. Rescan to check. Do not send another clear blindly.',
  DtcClearNoticeKind.cancelledBeforeSend: 'The clear was cancelled before any command left the app. Rescan, then try again if you still want to clear.',
  DtcClearNoticeKind.unexpected: 'The clear failed, so it is not known whether the vehicle cleared. Rescan to check. Do not send another clear blindly.',
  DtcClearNoticeKind.previousConnectionUnconfirmed: 'A previous connection sent a clear whose result was not confirmed. Rescan first, see which codes remain, then decide whether to clear.',
  DtcClearNoticeKind.rescanSettled: 'The previous clear could not be fully confirmed. What follows is the actual state after this rescan.',
};

const _bannerEnglish = {
  DtcScanBanner.interrupted: 'The scan was interrupted (the app may have been backgrounded, or the connection changed) and did not get a complete result. Scan again.',
  DtcScanBanner.disconnectedMidScan:
      'The connection dropped during the scan, so this scan did not finish.',
};

void main() {
  test('every install issue has a typed-out English sentence', () {
    expect(
      _installEnglish.keys.toSet(),
      PowertrainProfileInstallIssue.values.toSet(),
    );
    for (final issue in PowertrainProfileInstallIssue.values) {
      expect(powertrainInstallIssueText(_en, issue), _installEnglish[issue]);
    }
  });

  test('every install issue has a typed-out Traditional Chinese sentence', () {
    expect(
      _installChinese.keys.toSet(),
      PowertrainProfileInstallIssue.values.toSet(),
    );
    for (final issue in PowertrainProfileInstallIssue.values) {
      expect(powertrainInstallIssueText(_zh, issue), _installChinese[issue]);
    }
  });

  test('English install copy carries no Chinese', () {
    for (final text in _installEnglish.values) {
      expect(chinese.hasMatch(text), isFalse, reason: text);
    }
  });

  test(
    'clear-notice kinds the screen owns have typed-out English sentences',
    () {
      for (final kind in DtcClearNoticeKind.values) {
        if (kind == DtcClearNoticeKind.engineFailure) continue;
        expect(
          dtcClearNoticeText(_en, DtcClearNotice(kind)),
          _clearEnglish[kind],
          reason: '$kind',
        );
      }
    },
  );

  test('scan banners have typed-out English sentences', () {
    expect(_bannerEnglish.keys.toSet(), DtcScanBanner.values.toSet());
    for (final banner in DtcScanBanner.values) {
      expect(dtcScanBannerText(_en, banner), _bannerEnglish[banner]);
    }
  });

  test(
    'a DtcReadException on the clear path does not render its Chinese message',
    () {
      const failure = DtcReadException(
        '有 2 個控制器沒有回應清除指令（7E9、7EA）',
        repeatWouldHarm: true,
      );
      final text = dtcClearNoticeText(
        _en,
        const DtcClearNotice(
          DtcClearNoticeKind.engineFailure,
          failure: failure,
        ),
      )!;
      expect(text, isNot(contains('控制器')));
      expect(chinese.hasMatch(text), isFalse);
      expect(
        text,
        'A clear may already have reached the vehicle. Do not send another — a second global clear can reset emissions readiness on a controller that may already have cleared. Rescan to see what is left.',
      );
    },
  );

  test('a Mode 04 NRC 0x22 is ignition advice, not the engine sentence', () {
    const failure = DtcReadException(
      '7E8拒絕清除，因為目前的車輛狀態不允許。',
      negativeResponseCode: 0x22,
      issueDetail: '7E8',
    );
    final text = dtcClearNoticeText(
      _en,
      const DtcClearNotice(DtcClearNoticeKind.engineFailure, failure: failure),
    )!;
    expect(chinese.hasMatch(text), isFalse);
    expect(text, contains('7E8'));
    expect(text, contains('ignition ON'));
    expect(text, contains('try again'));
    expect(text.toLowerCase(), isNot(contains('do not send another')));
    expect(text, isNot(contains('拒絕')));
  });

  test('a mixed Mode 04 NRC keeps the do-not-repeat warning', () {
    const failure = DtcReadException(
      '控制器 7E8 拒絕清除，因為目前的車輛狀態不允許。',
      negativeResponseCode: 0x22,
      issueDetail: '7E8',
      repeatWouldHarm: true,
    );
    final text = dtcClearNoticeText(
      _en,
      const DtcClearNotice(DtcClearNoticeKind.engineFailure, failure: failure),
    )!;
    expect(chinese.hasMatch(text), isFalse);
    expect(text, contains('7E8'));
    expect(text, contains('ignition ON'));
    expect(text.toLowerCase(), contains('do not send another'));
    expect(text, contains('may already have cleared'));
    expect(text, isNot(contains('already finished')));
    expect(text, isNot(contains('控制器')));
  });

  test('unsupported Mode 04 without harm does not forbid a retry', () {
    const failure = DtcReadException(
      '控制器 7E9 不支援清除服務（Mode 04）。',
      negativeResponseCode: 0x11,
      issueDetail: '7E9',
    );
    final text = dtcClearNoticeText(
      _en,
      const DtcClearNotice(DtcClearNoticeKind.engineFailure, failure: failure),
    )!;
    expect(chinese.hasMatch(text), isFalse);
    expect(text, contains('7E9'));
    expect(text.toLowerCase(), contains('does not support'));
    expect(text.toLowerCase(), isNot(contains('do not send another')));
  });

  test('unsupported Mode 04 with harm forbids another global clear', () {
    const failure = DtcReadException(
      '控制器 7E9 不支援清除服務（Mode 04）。',
      negativeResponseCode: 0x11,
      issueDetail: '7E9',
      repeatWouldHarm: true,
    );
    final text = dtcClearNoticeText(
      _en,
      const DtcClearNotice(DtcClearNoticeKind.engineFailure, failure: failure),
    )!;
    expect(chinese.hasMatch(text), isFalse);
    expect(text.toLowerCase(), contains('do not send another'));
    expect(text, contains('may already have cleared'));
    expect(text, isNot(contains('already finished')));
    expect(text, isNot(contains('控制器')));
  });

  test('silent clear controllers are named without the Chinese sentence', () {
    const failure = DtcReadException(
      '有 2 個控制器沒有回應清除指令（7E9、7EA）',
      kind: DtcReadFailure.noAnswer,
      silentSources: {'7E9', '7EA'},
      repeatWouldHarm: true,
    );
    final text = dtcClearNoticeText(
      _en,
      const DtcClearNotice(DtcClearNoticeKind.engineFailure, failure: failure),
    )!;
    expect(chinese.hasMatch(text), isFalse);
    expect(text, contains('7E9'));
    expect(text, contains('7EA'));
    expect(text, isNot(contains('沒有回應')));
  });

  test(
    'a clear failure with a transport identifier uses that table, not Chinese',
    () {
      const failure = DtcReadException(
        '轉接器拒絕切換為功能定址 7DF',
        transportIssue: TransportIssue.wholeVehicleHeaderRefused,
        issueDetail: '7DF',
      );
      final text = dtcClearNoticeText(
        _en,
        const DtcClearNotice(
          DtcClearNoticeKind.engineFailure,
          failure: failure,
        ),
      )!;
      expect(chinese.hasMatch(text), isFalse);
      expect(text, contains('7DF'));
      expect(text, isNot(contains('功能定址')));
    },
  );

  test('an unexpected scan failure does not render English scan failed', () {
    const failure = DtcReadException('scan failed', kind: DtcReadFailure.error);
    expect(dtcCategoryFailureText(_en, failure), _en.dtcCategoryError);
    expect(
      dtcCategoryFailureText(_en, failure),
      isNot(contains('scan failed')),
    );
    expect(chinese.hasMatch(dtcCategoryFailureText(_en, failure)), isFalse);
  });

  test('every DtcReadFailure kind has typed-out English category copy', () {
    for (final kind in DtcReadFailure.values) {
      final text = dtcCategoryFailureText(
        _en,
        DtcReadException('控制器沒有回應', kind: kind),
      );
      expect(chinese.hasMatch(text), isFalse, reason: '$kind $text');
      expect(text, isNot(contains('控制器')));
    }
  });

  test('a category failure with a transport identifier uses that table', () {
    const failure = DtcReadException(
      '轉接器拒絕切換為功能定址 7DF',
      transportIssue: TransportIssue.wholeVehicleHeaderRefused,
      issueDetail: '7DF',
    );
    final text = dtcCategoryFailureText(_en, failure);
    expect(chinese.hasMatch(text), isFalse);
    expect(text, contains('7DF'));
    expect(text, isNot(contains('功能定址')));
  });

  test(
    'silent category controllers are named without the Chinese sentence',
    () {
      const failure = DtcReadException(
        '有 2 個控制器完全沒有回應這次查詢（7E9、7EA）。',
        kind: DtcReadFailure.noAnswer,
        silentSources: {'7E9', '7EA'},
      );
      final text = dtcCategoryFailureText(_en, failure);
      expect(chinese.hasMatch(text), isFalse);
      expect(text, isNot(contains('控制器')));
      expect(
        text,
        '2 controller(s) did not answer this query (7E9, 7EA). Answers that did come back are valid, but this cannot stand as a whole-vehicle result.',
      );
    },
  );

  test(
    'unresolved category identities are named without the Chinese sentence',
    () {
      const failure = DtcReadException(
        '有 1 筆回應無法判斷是哪個控制器送出的（未能辨識的位址：BE）。',
        kind: DtcReadFailure.noAnswer,
        unresolvedSources: {'BE'},
      );
      final text = dtcCategoryFailureText(_en, failure);
      expect(chinese.hasMatch(text), isFalse);
      expect(text, isNot(contains('控制器')));
      expect(
        text,
        '1 response(s) could not be attributed to a controller (BE). Codes that were read are still valid, but this cannot stand as a whole-vehicle result. Scan again.',
      );
    },
  );

  test('refused and answered counts are mapped, not the Chinese sentence', () {
    const failure = DtcReadException(
      '有 1 個控制器拒絕回答（1 個已回應）。',
      kind: DtcReadFailure.error,
      refusedCount: 1,
      answeredCount: 1,
    );
    final text = dtcCategoryFailureText(_en, failure);
    expect(chinese.hasMatch(text), isFalse);
    expect(text, isNot(contains('拒絕')));
    expect(
      text,
      '1 controller(s) refused (1 answered). This scan cannot cover the whole vehicle.',
    );
  });

  test('pending controller counts are mapped, not the Chinese sentence', () {
    const failure = DtcReadException(
      '有 1 個控制器還在處理這次查詢（response pending），1 個已回應。',
      kind: DtcReadFailure.pending,
      pendingSources: {'7E9'},
      answeredCount: 1,
    );
    final text = dtcCategoryFailureText(_en, failure);
    expect(chinese.hasMatch(text), isFalse);
    expect(text, isNot(contains('控制器')));
    expect(
      text,
      '1 controller(s) are still working on this request (1 already answered). The result is incomplete. Wait, then scan again.',
    );
  });

  test(
    'unrecognised response counts are mapped without the decoder sentence',
    () {
      const failure = DtcReadException(
        '有 2 筆回應無法解讀（解碼器拒絕這筆回應）。',
        kind: DtcReadFailure.error,
        unrecognisedCount: 2,
        answeredCount: 1,
      );
      final text = dtcCategoryFailureText(_en, failure);
      expect(chinese.hasMatch(text), isFalse);
      expect(text, isNot(contains('解碼器')));
      expect(
        text,
        '2 response(s) could not be read (1 answered). The rest is still valid, but this scan is incomplete.',
      );
    },
  );

  test('a clear with unresolved identities names them without Chinese', () {
    const failure = DtcReadException(
      '掃描時有回應無法判斷是哪個控制器送出的（未能辨識的位址：BE）。',
      kind: DtcReadFailure.noAnswer,
      unresolvedSources: {'BE'},
    );
    final text = dtcClearNoticeText(
      _en,
      const DtcClearNotice(DtcClearNoticeKind.engineFailure, failure: failure),
    )!;
    expect(chinese.hasMatch(text), isFalse);
    expect(text, contains('BE'));
    expect(text, isNot(contains('控制器')));
    expect(text.toLowerCase(), isNot(contains('do not send another')));
  });

  test(
    'a mixed clear with unresolved identities forbids another global clear',
    () {
      const failure = DtcReadException(
        '清除指令的回應中有無法判斷來源的資料（未能辨識的位址：BE）。',
        kind: DtcReadFailure.noAnswer,
        unresolvedSources: {'BE'},
        repeatWouldHarm: true,
      );
      final text = dtcClearNoticeText(
        _en,
        const DtcClearNotice(
          DtcClearNoticeKind.engineFailure,
          failure: failure,
        ),
      )!;
      expect(chinese.hasMatch(text), isFalse);
      expect(text, contains('BE'));
      expect(text.toLowerCase(), contains('do not send another'));
      expect(text, isNot(contains('控制器')));
    },
  );

  test(
    'BLE scan issues have typed-out English sentences without native text',
    () {
      expect(
        bleScanIssueText(_en, BleScanIssue.bluezUnavailable),
        _en.connectBleScanBluez,
      );
      expect(
        bleScanIssueText(_en, BleScanIssue.unclassified),
        isNot(contains('Exception')),
      );
      expect(_en.connectPairedListFailed.toLowerCase(), isNot(contains('log')));
      expect(
        _en.connectBleScanUnclassified.toLowerCase(),
        isNot(contains('log')),
      );
      for (final issue in BleScanIssue.values) {
        expect(
          chinese.hasMatch(bleScanIssueText(_en, issue)),
          isFalse,
          reason: '$issue',
        );
      }
    },
  );

  test(
    'a FormulaException with no identifier does not render the engine sentence',
    () {
      const exception = FormulaException('運算結果不是有效數值', 'A', issue: null);
      expect(formulaIssueText(_en, exception), isNull);
      expect(_en.pidFormulaUnidentified, isNot(contains('運算')));
      expect(chinese.hasMatch(_en.pidFormulaUnidentified), isFalse);
    },
  );

  test(
    'a handshake TransportException is mapped, not interpolated as Chinese',
    () {
      final progress = InitProgress(
        step: Elm327Client.initSequence.first,
        index: 0,
        total: Elm327Client.initSequence.length,
        status: InitStatus.failed,
        detail: '連線已中斷。',
        transportIssue: TransportIssue.bleLinkFailed,
      );
      final state = ObdConnectionState(
        phase: ConnectionPhase.failed,
        error: '初始化在 ATZ 失敗（連線已中斷。）',
        issue: ObdConnectionIssue.handshakeStepFailed,
        issueStep: progress,
      );
      final banner = connectionIssueText(_en, state)!;
      expect(chinese.hasMatch(banner), isFalse);
      expect(banner, isNot(contains('連線')));
      expect(banner, isNot(contains('TransportException')));
      expect(
        initProgressLine(_en, progress),
        _en.connectTransportBleLinkFailed,
      );
      expect(chinese.hasMatch(initProgressLine(_en, progress)), isFalse);
    },
  );

  test('an unexpected handshake exception uses the ARB, not \$e', () {
    final progress = InitProgress(
      step: Elm327Client.initSequence.first,
      index: 0,
      total: Elm327Client.initSequence.length,
      status: InitStatus.failed,
      detail: 'StateError: 連線已中斷。',
      note: InitNote.unexpected,
    );
    expect(initProgressLine(_en, progress), _en.handshakeNoteUnexpected);
    expect(chinese.hasMatch(initProgressLine(_en, progress)), isFalse);
    expect(initProgressLine(_en, progress), isNot(contains('StateError')));
  });
}
