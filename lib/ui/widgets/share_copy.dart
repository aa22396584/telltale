/// Screen copy for share-sheet refusals.
///
/// [ShareError] lives in the coordinator as a stable identifier. The sentences
/// used to live there too, in Traditional Chinese, so an English reader who
/// tapped Export still saw 「檔案已準備完成，但系統分享介面無法開啟。」
/// (ImL1s/telltale#45). The words are here, one ARB entry per identifier.
///
/// Takes [AppLocalizations] rather than a [BuildContext] so a pure-Dart test
/// can walk every arm in both locales with no widget pump.
library;

import '../../l10n/generated/app_localizations.dart';
import '../../state/app_share_coordinator.dart';

/// Why a share did not open, in the reader's language.
String shareErrorText(AppLocalizations l10n, ShareError error) {
  return switch (error) {
    ShareError.shareBusy || ShareError.artifactBusy => l10n.transcriptDeleteBusy,
    ShareError.policyDenied => l10n.sharePolicyDenied,
    ShareError.shareSafetyChangedRecorder ||
    ShareError.shareSafetyChangedConnection ||
    ShareError.shareSafetyChangedMoving ||
    ShareError.shareSafetyChangedSpeedUnknown ||
    ShareError.shareSafetyChangedForeground => l10n.shareSafetyChanged,
    ShareError.shareSizeLimit => l10n.shareSizeLimit,
    ShareError.shareStagingBusy => l10n.shareStagingBusy,
    ShareError.shareCleanupRequired => l10n.shareCleanupRequired,
    ShareError.shareSpaceUnknown => l10n.shareSpaceUnknown,
    ShareError.shareNoSpace => l10n.shareNoSpace,
    ShareError.shareHandoffFailed => l10n.shareHandoffFailed,
    ShareError.storageFailure => l10n.shareStorageFailure,
  };
}
