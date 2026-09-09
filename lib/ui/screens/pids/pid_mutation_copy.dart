/// Screen words for a refused PID mutation.
///
/// `pid_mutation_lock.dart` shipped `const kPidMutationLockedMessage =
/// '請先停止並儲存'` and the powertrain-battery catalog screen snacked it on
/// both the install and the uninstall path. An English driver who tried to
/// install a profile while a recording held the lock got a Traditional Chinese
/// sentence — on the very screen whose refusal copy this slice was localizing,
/// four lines above the install-failure path.
///
/// The words already existed: every other screen that refuses the same
/// [PidMutationOutcome] renders `telemetryBlockedByRecorder`, which holds that
/// exact Chinese sentence and its English. So this is not a new ARB entry, it
/// is the existing one reached from the last screen that was bypassing it — a
/// second key with the same copy would be its own defect.
///
/// A switch rather than a bare getter because [PidMutationFailure] is an enum:
/// a second failure kind must fail to compile here until somebody writes its
/// sentence, rather than silently rendering the recorder's.
///
/// Takes an [AppLocalizations] rather than a [BuildContext], like every other
/// `*_copy.dart` in this tree, so a test can walk it in both languages without
/// pumping a frame.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../state/pid_mutation_lock.dart';

/// One whole sentence per way a PID mutation can be refused.
String pidMutationFailureText(
  AppLocalizations l10n,
  PidMutationFailure failure,
) => switch (failure) {
  PidMutationFailure.locked => l10n.telemetryBlockedByRecorder,
  PidMutationFailure.persistFailed => l10n.pidMutationPersistFailed,
};
