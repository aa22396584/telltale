/// Getting the bytes off the phone, from wherever the failure happened.
///
/// Lives in its own widget because the place somebody needs it most is the
/// connect screen, which is not inside the shell that holds Settings. A failed
/// connection is precisely the session whose traffic explains something, and it
/// was the one session whose export button could not be reached: Settings sits
/// behind a successful connect, and the export read the transcript off a client
/// the teardown had already discarded.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../obd/transcript_store.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'panel.dart';
import '../../state/obd_session.dart';
import '../../state/app_share_entry_controller.dart';
import '../../state/app_share_coordinator.dart';
import '../../state/transcript_store_runtime.dart';

/// How big a stored recording is, in a unit that does not read as "empty".
///
/// `bytes / 1024` rounded to zero decimals renders anything under 512 bytes as
/// `0 KB`, and a failed handshake — the reset, the timeout, the step it died on
/// — is a few hundred bytes. That is the most diagnostic recording this app
/// produces, and it was the one being offered as nothing. Nobody exports a file
/// the app has just called empty.
///
/// Takes an [AppLocalizations] rather than a [BuildContext]: it is called from
/// a top-level function with no widget above it, and a plain parameter lets a
/// pure-Dart test assert both languages. KB stays a unit in both — units do not
/// change with language.
String formatTranscriptSize(AppLocalizations l10n, int bytes) => bytes < 1024
    ? l10n.transcriptSizeBytes(bytes)
    : '${(bytes / 1024).round()} KB';

/// Writes the transcript to a file and hands it to the share sheet.
///
/// A file rather than a text share: these run to hundreds of kilobytes and
/// every messaging app truncates a long string. The name carries the timestamp
/// so two exports from one afternoon do not overwrite each other.
Future<String?> exportTranscript(
  WidgetRef ref, {
  required AppLocalizations l10n,
  required bool withHex,
  Rect? sharePositionOrigin,
}) async {
  final session = ref.read(obdSessionProvider.notifier);
  // One read, so the heading and the bytes are from the same session.
  //
  // Reading them separately put an await between them — the temporary
  // directory — and a connection begun in that gap relabelled the old
  // session's bytes with the new session's adapter and protocol.
  final record = session.exportableRecord;
  if (record == null) return l10n.transcriptNothingToExport;
  try {
    final outcome = await ref
        .read(appShareEntryControllerProvider)
        .shareRawTranscript(
          transcript: record.transcript,
          header: record.header,
          withHex: withHex,
          subjectAt: DateTime.now(),
          sharePositionOrigin: sharePositionOrigin,
        );
    return outcome.userFacingError;
  } on Object catch (e) {
    return l10n.transcriptExportFailed('$e');
  }
}

/// The two export buttons, with the explanation above them.
///
/// [compact] drops the explanation — used on the connect screen, where the
/// failure banner has already said what went wrong and the only thing left to
/// add is a way to carry the evidence away.
class TranscriptExportButtons extends ConsumerWidget {
  const TranscriptExportButtons({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched, not read: the buttons have to come alive the moment a failed
    // attempt leaves something behind.
    ref.watch(obdSessionProvider);
    final l10n = AppLocalizations.of(context);
    final available = ref.read(obdSessionProvider.notifier).hasTranscript;

    Future<void> run(bool withHex) async {
      // Read outside the await, above: the message describes the export the
      // user asked for, in the language that was on screen when they asked.
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      final error = await exportTranscript(
        ref,
        l10n: l10n,
        withHex: withHex,
        sharePositionOrigin: origin,
      );
      if (error == null || !context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text(
            l10n.transcriptExportExplanation,
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: Spacing.md),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: available ? () => run(false) : null,
                icon: const Icon(Icons.ios_share, size: 18),
                label: Text(l10n.transcriptExportButton),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: available ? () => run(true) : null,
                icon: const Icon(Icons.data_object, size: 18),
                label: Text(l10n.transcriptExportWithHex),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The recording left behind by a previous run of the app.
///
/// Loaded once, because the answer only changes when a session ends and this
/// is read on a screen the user reaches between sessions.
final recoveredTranscriptProvider = FutureProvider<StoredTranscript?>((ref) {
  return ref.watch(managedTranscriptStoreProvider).load();
});

/// Hands a recovered recording to the share sheet.
///
/// Separate from [exportTranscript] because there is no session to read: the
/// bytes came off disk, written by an app that is no longer running. That is
/// the case this exists for — Android killed it, or the phone died, and the
/// only copy is the one that was saved on the way out.
///
/// [displayed] is the snapshot currently shown in the panel. Export refuses
/// when `last-session.log` no longer matches it, so a later periodic snapshot
/// cannot be shared under the previous-connection label.
Future<String?> exportRecoveredTranscript(
  WidgetRef ref,
  StoredTranscript displayed, {
  required AppLocalizations l10n,
  Rect? sharePositionOrigin,
}) async {
  try {
    final store = ref.read(managedTranscriptStoreProvider);
    final outcome = await ref
        .read(appShareEntryControllerProvider)
        .shareRecoveredTranscript(
          store: store,
          expected: displayed,
          sharePositionOrigin: sharePositionOrigin,
        );
    if (outcome.error == ShareError.storageFailure) {
      // openStreaming returned null because the file changed or vanished.
      ref.invalidate(recoveredTranscriptProvider);
      return l10n.transcriptRecoveredChanged;
    }
    return outcome.userFacingError;
  } on Object catch (e) {
    return l10n.transcriptExportFailed('$e');
  }
}

/// The panel offering a recording that outlived its app.
///
/// Shown only when there is one, and worded so it is obvious this is *not*
/// this session: somebody who has just reconnected and is looking at a working
/// car should not mistake it for the log they are about to make.
class RecoveredTranscriptPanel extends ConsumerWidget {
  const RecoveredTranscriptPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recovered = ref.watch(recoveredTranscriptProvider);
    final stored = recovered.asData?.value;
    if (stored == null) return const SizedBox.shrink();

    final at = stored.savedAt;
    String two(int v) => v.toString().padLeft(2, '0');
    final savedAtLabel =
        '${at.year}/${two(at.month)}/${two(at.day)} '
        '${two(at.hour)}:${two(at.minute)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.transcriptRecoveredTitle,
              style: context.texts.titleSmall,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              l10n.transcriptRecoveredBody(
                savedAtLabel,
                formatTranscriptSize(l10n, stored.bytes),
              ),
              style: context.texts.bodySmall,
            ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final box = context.findRenderObject() as RenderBox?;
                    final origin = box == null
                        ? null
                        : box.localToGlobal(Offset.zero) & box.size;
                    final error = await exportRecoveredTranscript(
                      ref,
                      stored,
                      l10n: l10n,
                      sharePositionOrigin: origin,
                    );
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: Text(l10n.transcriptExport),
                ),
                const SizedBox(width: Spacing.sm),
                TextButton(
                  onPressed: () async {
                    final outcome = await ref
                        .read(managedTranscriptStoreProvider)
                        .clear(expected: stored);
                    if (outcome.succeeded) {
                      ref.invalidate(recoveredTranscriptProvider);
                    } else if (context.mounted) {
                      if (outcome.error ==
                          TranscriptMutationError.identityChanged) {
                        ref.invalidate(recoveredTranscriptProvider);
                      }
                      final message = switch (outcome.error) {
                        TranscriptMutationError.artifactBusy =>
                          l10n.transcriptDeleteBusy,
                        TranscriptMutationError.policyDenied ||
                        TranscriptMutationError.safetyChanged =>
                          l10n.transcriptDeleteRefusedBySafety,
                        TranscriptMutationError.identityChanged =>
                          l10n.transcriptRecoveredChanged,
                        TranscriptMutationError.storageFailure =>
                          l10n.transcriptDeleteFailed,
                        null => '',
                      };
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(message)));
                    }
                  },
                  child: Text(l10n.transcriptDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
