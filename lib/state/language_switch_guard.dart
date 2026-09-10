/// Whether an in-app language change may proceed.
///
/// A LocaleManager write can recreate the activity. Dirty PID edits, an
/// in-flight artifact, and an active recording must be finished or discarded
/// first. This is not an OS Settings restart.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../telemetry/session/telemetry_recorder.dart';
import 'artifact_operation_gate.dart';
import 'pid_mutation_lock.dart';
import 'telemetry_recorder.dart';

enum LanguageSwitchBlock {
  none,
  recording,
  artifactBusy,
  pidMutationLocked,
  pidEditorDirty,
}

LanguageSwitchBlock languageSwitchBlock({
  required bool recording,
  required bool artifactBusy,
  required bool pidMutationLocked,
  required bool pidEditorDirty,
}) {
  if (recording) return LanguageSwitchBlock.recording;
  if (artifactBusy) return LanguageSwitchBlock.artifactBusy;
  if (pidMutationLocked) return LanguageSwitchBlock.pidMutationLocked;
  if (pidEditorDirty) return LanguageSwitchBlock.pidEditorDirty;
  return LanguageSwitchBlock.none;
}

String languageSwitchBlockText(
  AppLocalizations l10n,
  LanguageSwitchBlock block,
) => switch (block) {
  LanguageSwitchBlock.none => '',
  LanguageSwitchBlock.recording ||
  LanguageSwitchBlock.artifactBusy ||
  LanguageSwitchBlock.pidMutationLocked => l10n.telemetryBlockedByRecorder,
  LanguageSwitchBlock.pidEditorDirty => l10n.pidEditorDiscardBody,
};

final pidEditorDirtyProvider = NotifierProvider<PidEditorDirty, bool>(
  PidEditorDirty.new,
);

class PidEditorDirty extends Notifier<bool> {
  @override
  bool build() => false;

  void setDirty(bool value) {
    if (state != value) state = value;
  }
}

final languageSwitchBlockProvider = Provider<LanguageSwitchBlock>((ref) {
  final phase = ref.watch(telemetryRecorderProgressProvider).state.phase;
  final recording =
      phase == TelemetryRecorderPhase.preparing ||
      phase == TelemetryRecorderPhase.recording ||
      phase == TelemetryRecorderPhase.finalizing;
  final artifactBusy = !ref.watch(artifactOperationGateProvider).snapshot.isIdle;
  final pidLocked = ref.watch(pidMutationLockProvider).isLocked;
  final editorDirty = ref.watch(pidEditorDirtyProvider);
  return languageSwitchBlock(
    recording: recording,
    artifactBusy: artifactBusy,
    pidMutationLocked: pidLocked,
    pidEditorDirty: editorDirty,
  );
});
