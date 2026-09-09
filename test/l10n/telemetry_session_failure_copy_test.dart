// Session-library refusals, in both shipped languages.
//
// `telemetrySessionActionFailureLabel` used to return Traditional Chinese
// for every arm that was not already an ARB key, so an English export or
// delete still read 「請回到 App 後再操作」. The tables are typed by hand.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/telemetry_sessions.dart';

import '../support/cjk.dart';

const _english = <TelemetrySessionActionFailure, String>{
  TelemetrySessionActionFailure.confirmationRequired:
      'Confirm this delete first',
  TelemetrySessionActionFailure.recorderActive:
      'Stop and save the recording first',
  TelemetrySessionActionFailure.moving: 'Park the vehicle first',
  TelemetrySessionActionFailure.speedUnknown:
      'Cannot confirm the vehicle is stopped — disconnect first',
  TelemetrySessionActionFailure.background:
      'Return to Telltale before continuing.',
  TelemetrySessionActionFailure.artifactBusy:
      'Another file operation has not finished.',
  TelemetrySessionActionFailure.policyChanged:
      'Driving or connection state changed during this operation.',
  TelemetrySessionActionFailure.invalidId: 'This recording id is not valid.',
  TelemetrySessionActionFailure.notFound:
      'This local recording was not found.',
  TelemetrySessionActionFailure.storage: 'A local storage operation failed.',
  TelemetrySessionActionFailure.share: 'Could not prepare or open sharing.',
};

const _chinese = <TelemetrySessionActionFailure, String>{
  TelemetrySessionActionFailure.confirmationRequired: '請先確認這個刪除操作',
  TelemetrySessionActionFailure.recorderActive: '請先停止並儲存',
  TelemetrySessionActionFailure.moving: '請停車後操作',
  TelemetrySessionActionFailure.speedUnknown: '無法確認車輛已停止；請先中斷連線',
  TelemetrySessionActionFailure.background: '請回到 App 後再操作',
  TelemetrySessionActionFailure.artifactBusy: '另一個檔案作業尚未完成。',
  TelemetrySessionActionFailure.policyChanged: '操作期間行車或連線狀態已改變',
  TelemetrySessionActionFailure.invalidId: '紀錄識別碼無效',
  TelemetrySessionActionFailure.notFound: '找不到這筆本機紀錄',
  TelemetrySessionActionFailure.storage: '本機儲存作業失敗',
  TelemetrySessionActionFailure.share: '無法準備或開啟分享',
};

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  test('every localizable session failure has a handwritten English sentence', () {
    expect(
      _english.keys.toSet(),
      TelemetrySessionActionFailure.values.toSet()
        ..remove(TelemetrySessionActionFailure.restartRequired),
    );
    for (final failure in _english.keys) {
      expect(
        telemetrySessionActionFailureLabel(en, failure),
        _english[failure],
        reason: '$failure',
      );
    }
  });

  test('every localizable session failure has a handwritten Chinese sentence', () {
    expect(_chinese.keys.toSet(), _english.keys.toSet());
    for (final failure in _chinese.keys) {
      expect(
        telemetrySessionActionFailureLabel(zh, failure),
        _chinese[failure],
        reason: '$failure',
      );
    }
  });

  test('English session failures have no Chinese', () {
    for (final failure in _english.keys) {
      final text = telemetrySessionActionFailureLabel(en, failure);
      expect(
        containsChinese(text),
        isFalse,
        reason: '$failure: ${chineseIn(text)}',
      );
    }
  });

  test('history background access uses the same sentence as the action failure', () {
    expect(
      TelemetryHistoryAccess.background.message(en),
      en.telemetryHistoryNeedsForeground,
    );
    expect(
      TelemetryHistoryAccess.background.message(zh),
      zh.telemetryHistoryNeedsForeground,
    );
  });

  test('restart-required copy is still the deferred const', () {
    expect(
      telemetrySessionActionFailureLabel(
        en,
        TelemetrySessionActionFailure.restartRequired,
      ),
      telemetryArtifactRestartRequiredCopy,
    );
  });
}
