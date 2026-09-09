// What the share-sheet refusals actually say, in both shipped languages.
//
// The tables are typed by hand. `expect(shareErrorText(en, e), en.shareHandoffFailed)`
// would read the same ARB the mapper reads and agree with itself.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/ui/widgets/share_copy.dart';

import '../support/cjk.dart';

const _english = <ShareError, String>{
  ShareError.shareBusy: 'Another file operation has not finished.',
  ShareError.artifactBusy: 'Another file operation has not finished.',
  ShareError.policyDenied:
      'The current connection or driving state does not allow export.',
  ShareError.shareSafetyChangedRecorder:
      'The state changed while preparing the export, so sharing was not opened.',
  ShareError.shareSafetyChangedConnection:
      'The state changed while preparing the export, so sharing was not opened.',
  ShareError.shareSafetyChangedMoving:
      'The state changed while preparing the export, so sharing was not opened.',
  ShareError.shareSafetyChangedSpeedUnknown:
      'The state changed while preparing the export, so sharing was not opened.',
  ShareError.shareSafetyChangedForeground:
      'The state changed while preparing the export, so sharing was not opened.',
  ShareError.shareSizeLimit: 'The export exceeds the 32 MiB limit.',
  ShareError.shareStagingBusy:
      'A previous share file is still in its retention period. Try again later.',
  ShareError.shareCleanupRequired:
      'The share staging area needs to be checked after a restart.',
  ShareError.shareSpaceUnknown:
      'Could not confirm the free space the share file needs.',
  ShareError.shareNoSpace:
      'There is not enough storage to prepare the share file.',
  ShareError.shareHandoffFailed:
      'The file is ready, but the system share sheet could not be opened.',
  ShareError.storageFailure:
      'A storage error occurred while preparing or recording the share.',
};

const _chinese = <ShareError, String>{
  ShareError.shareBusy: '另一個檔案作業尚未完成。',
  ShareError.artifactBusy: '另一個檔案作業尚未完成。',
  ShareError.policyDenied: '目前的連線或行車狀態不允許匯出。',
  ShareError.shareSafetyChangedRecorder: '準備匯出期間狀態已改變，未開啟分享。',
  ShareError.shareSafetyChangedConnection: '準備匯出期間狀態已改變，未開啟分享。',
  ShareError.shareSafetyChangedMoving: '準備匯出期間狀態已改變，未開啟分享。',
  ShareError.shareSafetyChangedSpeedUnknown: '準備匯出期間狀態已改變，未開啟分享。',
  ShareError.shareSafetyChangedForeground: '準備匯出期間狀態已改變，未開啟分享。',
  ShareError.shareSizeLimit: '匯出檔超過 32 MiB 上限。',
  ShareError.shareStagingBusy: '先前的分享檔仍在保留期內，請稍後再試。',
  ShareError.shareCleanupRequired: '分享暫存區需要在重新啟動後檢查。',
  ShareError.shareSpaceUnknown: '無法確認分享檔所需的可用空間。',
  ShareError.shareNoSpace: '儲存空間不足，無法準備分享檔。',
  ShareError.shareHandoffFailed: '檔案已準備完成，但系統分享介面無法開啟。',
  ShareError.storageFailure: '準備或記錄分享結果時發生儲存錯誤。',
};

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  test('share copy says what it is supposed to say in English', () {
    expect(_english.keys.toSet(), ShareError.values.toSet());
    for (final error in ShareError.values) {
      expect(shareErrorText(en, error), _english[error], reason: '$error');
    }
  });

  test('share copy says what it is supposed to say in Traditional Chinese', () {
    expect(_chinese.keys.toSet(), ShareError.values.toSet());
    for (final error in ShareError.values) {
      expect(shareErrorText(zh, error), _chinese[error], reason: '$error');
    }
  });

  test('English share copy has no Chinese', () {
    for (final error in ShareError.values) {
      final text = shareErrorText(en, error);
      expect(containsChinese(text), isFalse, reason: '$error: ${chineseIn(text)}');
    }
  });

  test('share-sheet subjects are bilingual and English has no Chinese', () {
    const sessionId = '0123456789abcdef0123456789abcdef';
    const stamp = '20260830-010203';
    expect(
      shareTelemetrySubjectText(en, sessionId),
      'Local OBD record $sessionId',
    );
    expect(
      shareRawTranscriptSubjectText(en, stamp),
      'Telltale transport log $stamp',
    );
    expect(
      shareRecoveredTranscriptSubjectText(en),
      'Telltale transport log (last connection)',
    );
    expect(sharePidCsvSubjectText(en), 'Telltale custom PID definitions');
    expect(
      shareTelemetrySubjectText(zh, sessionId),
      '本機 OBD 紀錄 $sessionId',
    );
    expect(
      shareRawTranscriptSubjectText(zh, stamp),
      'Telltale 傳輸紀錄 $stamp',
    );
    expect(
      shareRecoveredTranscriptSubjectText(zh),
      'Telltale 傳輸紀錄（上一次連線）',
    );
    expect(sharePidCsvSubjectText(zh), 'Telltale 自訂 PID 定義');
    for (final text in [
      shareTelemetrySubjectText(en, sessionId),
      shareRawTranscriptSubjectText(en, stamp),
      shareRecoveredTranscriptSubjectText(en),
      sharePidCsvSubjectText(en),
    ]) {
      expect(containsChinese(text), isFalse, reason: chineseIn(text));
    }
  });
}
