/// PID manager: pick what the dashboard shows, and author custom definitions.
library;

import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/pid/pid.dart';
import '../../../obd/pid/pid_csv.dart';
import '../../../obd/polling_engine.dart';
import '../../../obd/telemetry.dart';
import '../../../state/obd_session.dart';
import '../../../state/pid_mutation_lock.dart';
import '../../../state/pid_registry.dart';
import '../../../state/app_share_entry_controller.dart';
import '../../widgets/panel.dart';
import '../../widgets/share_copy.dart';
import 'pid_editor_screen.dart';
import 'pid_import_copy.dart';
import 'pid_mutation_copy.dart';
import 'powertrain_battery_catalog_screen.dart';

class PidManagerScreen extends ConsumerStatefulWidget {
  const PidManagerScreen({super.key});

  static const String path = '/pids';

  @override
  ConsumerState<PidManagerScreen> createState() => _PidManagerScreenState();
}

enum _PidMenuAction { arrange, importCsv, exportCsv }

enum SupportedPidBulkUiState {
  pending,
  incomplete,
  zero,
  ready,
  allActive,
  locked,
}

final class SupportedPidBulkPresentation {
  const SupportedPidBulkPresentation({
    required this.state,
    required this.confirmedCount,
    required this.addCount,
  });

  final SupportedPidBulkUiState state;
  final int confirmedCount;
  final int addCount;

  bool get canAdd =>
      (state == SupportedPidBulkUiState.ready ||
          state == SupportedPidBulkUiState.incomplete) &&
      addCount > 0;
}

/// Takes an [AppLocalizations] rather than a [BuildContext] for the reason
/// `telemetry_status_copy.dart` gives: the sentence is assembled outside any
/// widget, and a plain parameter keeps it assertable in both languages from a
/// pure-Dart test.
///
/// The two halves are joined here rather than written as one ARB entry so the
/// unconfirmed-blocks warning can be present or absent without a translator
/// having to keep two near-identical paragraphs in step.
String supportedPidConfirmationMessage({
  required AppLocalizations l10n,
  required ObdCapabilitySummary summary,
  required int addCount,
}) => [
  if (summary.unknownOrUnverifiedBlockCount > 0)
    l10n.pidBulkUnconfirmedBlocks(summary.unknownOrUnverifiedBlockCount),
  l10n.pidBulkWillAdd(addCount),
].join('\n\n');

/// Where the support scan stands. Unknown is never rendered as unsupported:
/// [ObdCapabilityDiscoveryPhase.interrupted] means the app stopped asking, not
/// that the vehicle answered.
String obdCapabilityPhaseLabel(
  AppLocalizations l10n,
  ObdCapabilityDiscoveryPhase phase,
) => switch (phase) {
  ObdCapabilityDiscoveryPhase.notStarted => l10n.pidCapabilityPhaseNotStarted,
  ObdCapabilityDiscoveryPhase.running => l10n.pidCapabilityPhaseRunning,
  ObdCapabilityDiscoveryPhase.attemptFinished =>
    l10n.pidCapabilityPhaseAttemptFinished,
  ObdCapabilityDiscoveryPhase.interrupted =>
    l10n.pidCapabilityPhaseInterrupted,
};

/// The bulk-add button's label, which doubles as its semantics label.
String supportedPidBulkActionLabel(
  AppLocalizations l10n,
  SupportedPidBulkPresentation presentation,
) => switch (presentation.state) {
  SupportedPidBulkUiState.pending => l10n.pidBulkActionPending,
  SupportedPidBulkUiState.incomplete =>
    presentation.addCount > 0
        ? l10n.pidBulkActionAddConfirmed(presentation.addCount)
        : l10n.pidBulkActionIncomplete,
  SupportedPidBulkUiState.zero => l10n.pidBulkActionZero,
  SupportedPidBulkUiState.ready => l10n.pidBulkAddCount(presentation.addCount),
  SupportedPidBulkUiState.allActive => l10n.pidBulkActionAllActive,
  SupportedPidBulkUiState.locked => l10n.pidBulkActionLocked,
};

SupportedPidBulkPresentation supportedPidBulkPresentation({
  required ObdCapabilitySummary summary,
  required Iterable<Pid> active,
  required bool mutationLocked,
}) {
  final confirmed = summary.positivelyConfirmedShippedDirectPids;
  final activeIds = active.map((pid) => Pid.canonicalId(pid.id)).toSet();
  final addCount = confirmed
      .where((pid) => !activeIds.contains(Pid.canonicalId(pid.id)))
      .length;
  if (mutationLocked) {
    return SupportedPidBulkPresentation(
      state: SupportedPidBulkUiState.locked,
      confirmedCount: confirmed.length,
      addCount: addCount,
    );
  }
  if (summary.phase == ObdCapabilityDiscoveryPhase.notStarted ||
      summary.phase == ObdCapabilityDiscoveryPhase.running) {
    return SupportedPidBulkPresentation(
      state: SupportedPidBulkUiState.pending,
      confirmedCount: confirmed.length,
      addCount: addCount,
    );
  }
  if (confirmed.isEmpty && summary.unknownOrUnverifiedBlockCount == 0) {
    return const SupportedPidBulkPresentation(
      state: SupportedPidBulkUiState.zero,
      confirmedCount: 0,
      addCount: 0,
    );
  }
  if (addCount == 0 && confirmed.isNotEmpty) {
    return SupportedPidBulkPresentation(
      state: SupportedPidBulkUiState.allActive,
      confirmedCount: confirmed.length,
      addCount: 0,
    );
  }
  final incomplete =
      summary.phase == ObdCapabilityDiscoveryPhase.interrupted ||
      summary.unknownOrUnverifiedBlockCount > 0;
  return SupportedPidBulkPresentation(
    state: incomplete
        ? SupportedPidBulkUiState.incomplete
        : SupportedPidBulkUiState.ready,
    confirmedCount: confirmed.length,
    addCount: addCount,
  );
}

class _PidManagerScreenState extends ConsumerState<PidManagerScreen> {
  String _query = '';
  bool _activeOnly = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _togglePid(Pid pid) async {
    // Read before the await: the message belongs to the language that was on
    // screen when the user tapped, and `context` may not survive the gap.
    final l10n = AppLocalizations.of(context);
    final outcome = await ref.read(activePidsProvider.notifier).toggle(pid);
    final failure = outcome.failure;
    if (failure != null) _snack(pidMutationFailureText(l10n, failure));
  }

  Future<void> _addConfirmedSupported(
    ObdCapabilitySummary summary,
    List<Pid> active,
  ) async {
    final l10n = AppLocalizations.of(context);
    final presentation = supportedPidBulkPresentation(
      summary: summary,
      active: active,
      mutationLocked: ref.read(pidMutationLockProvider).isLocked,
    );
    if (!presentation.canAdd) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pidBulkAddDialogTitle(presentation.addCount)),
        content: Text(
          supportedPidConfirmationMessage(
            l10n: l10n,
            summary: summary,
            addCount: presentation.addCount,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.pidActionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.pidBulkAddCount(presentation.addCount)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final outcome = await ref
        .read(activePidsProvider.notifier)
        .appendPositivelyConfirmed(summary);
    if (outcome.isLocked) {
      // `SupportedPidSelectionOutcome`, not `PidMutationOutcome`: it carries
      // its own result enum and no `PidMutationFailure`, so it names the
      // sentence directly rather than going through the copy switch.
      _snack(l10n.telemetryBlockedByRecorder);
    } else if (outcome.addedCount > 0) {
      _snack(l10n.pidBulkAdded(outcome.addedCount));
    }
  }

  Future<void> _handleMenu(_PidMenuAction action) async {
    switch (action) {
      case _PidMenuAction.arrange:
        await _showArrangeSheet();
      case _PidMenuAction.importCsv:
        await _importCsv();
      case _PidMenuAction.exportCsv:
        await _exportCsv();
    }
  }

  Future<void> _showArrangeSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ArrangeSheet(),
    );
  }

  Future<void> _importCsv() async {
    final l10n = AppLocalizations.of(context);
    final PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        dialogTitle: l10n.pidPickCsvDialogTitle,
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt'],
      );
    } on Exception catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'pid_manager_screen',
          context: ErrorDescription('PID CSV picker'),
        ),
      );
      _snack(l10n.pidImportPickerFailed);
      return;
    }
    if (picked == null) return;

    String contents;
    try {
      // Decoded as UTF-8 rather than raw code units: unit labels in these
      // files are routinely °C, g/s, N·m, and a byte-wise read would mangle
      // every one of them.
      contents = utf8.decode(await picked.readAsBytes(), allowMalformed: true);
    } on Exception catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'pid_manager_screen',
          context: ErrorDescription('PID CSV read'),
        ),
      );
      _snack(l10n.pidImportReadFailed);
      return;
    }

    final result = PidCsv.parse(contents);
    PidImportOutcome? outcome;
    if (result.pids.isNotEmpty) {
      outcome = await ref
          .read(pidRegistryProvider.notifier)
          .upsertAllCustom(result.pids);
    }

    if (result.pids.isEmpty) {
      // `result.errors` carries identifiers; the words are this screen's, in
      // pid_import_copy.dart.
      _snack(
        result.errors.isEmpty
            ? l10n.pidImportNothingToImport
            : pidCsvDiagnosticText(l10n, result.errors.first),
      );
      return;
    }
    // Warnings are reported too, and separately from errors. A row that was
    // *changed* on the way in is not a row that was rejected — and a scale the
    // importer chose is the change most worth mentioning, because a needle
    // reads as authoritative against whatever bounds it is drawn on.
    // Counted as they landed, not as they were parsed — and phrased by
    // `pidImportOutcomeText`, which is where the sentences are tested.
    _snack(
      pidImportOutcomeText(
        l10n,
        outcome ??
            const PidImportOutcome(
              inserted: 0,
              replaced: 0,
              duplicatesInFile: [],
            ),
        skippedRows: result.hasErrors ? result.errors.length : 0,
        defaultedRanges: result.hasWarnings ? result.warnings.length : 0,
      ),
    );
  }

  Future<void> _exportCsv() async {
    final l10n = AppLocalizations.of(context);
    final custom = ref.read(pidRegistryProvider.notifier).customPids;
    if (custom.isEmpty) {
      _snack(l10n.pidExportNoCustomPids);
      return;
    }

    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      final outcome = await ref
          .read(appShareEntryControllerProvider)
          .sharePidCsv(pids: custom, sharePositionOrigin: origin);
      if (outcome.error != null) {
        _snack(shareErrorText(l10n, outcome.error!));
      }
    } on Exception {
      _snack(l10n.transcriptExportUnidentified);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final registry = ref.watch(pidRegistryProvider);
    final active = ref.watch(activePidsProvider);
    final snapshot =
        ref.watch(telemetryProvider).value ?? const TelemetrySnapshot();
    final summary =
        ref.watch(obdCapabilitySummaryProvider).value ??
        ObdCapabilitySummary.notStarted();
    final mutationLocked = ref.watch(pidMutationLockProvider).isLocked;
    final bulkPresentation = supportedPidBulkPresentation(
      summary: summary,
      active: active,
      mutationLocked: mutationLocked,
    );

    final activeIds = active.map((p) => p.id).toSet();
    final query = _query.trim().toLowerCase();
    final visible = registry.where((pid) {
      if (_activeOnly && !activeIds.contains(pid.id)) return false;
      if (query.isEmpty) return true;
      return pid.name.toLowerCase().contains(query) ||
          pid.shortName.toLowerCase().contains(query) ||
          pid.modeAndPid.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                  Spacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Spacing.md,
                      runSpacing: Spacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 180),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.pidManagerHeadline,
                                style: context.texts.headlineMedium,
                              ),
                              Text(
                                l10n.pidManagerCounts(
                                  active.length,
                                  registry.length,
                                ),
                                style: context.texts.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => context.push(PidEditorScreen.path),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(l10n.pidManagerAdd),
                        ),
                        PopupMenuButton<_PidMenuAction>(
                          onSelected: _handleMenu,
                          tooltip: l10n.pidManagerMoreActions,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: _PidMenuAction.arrange,
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.reorder, size: 20),
                                title: Text(l10n.pidManagerArrangeDashboard),
                              ),
                            ),
                            PopupMenuItem(
                              value: _PidMenuAction.importCsv,
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.file_download_outlined,
                                  size: 20,
                                ),
                                title: Text(l10n.pidManagerImportCsv),
                              ),
                            ),
                            PopupMenuItem(
                              value: _PidMenuAction.exportCsv,
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.file_upload_outlined,
                                  size: 20,
                                ),
                                title: Text(l10n.pidManagerExportCsv),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    PidCapabilityPanel(
                      summary: summary,
                      presentation: bulkPresentation,
                      onAdd: () => _addConfirmedSupported(summary, active),
                    ),
                    const SizedBox(height: Spacing.lg),
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: l10n.pidManagerSearchHint,
                        prefixIcon: const Icon(Icons.search, size: 20),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    Row(
                      children: [
                        FilterChip(
                          selected: _activeOnly,
                          onSelected: (v) => setState(() => _activeOnly = v),
                          label: Text(l10n.pidManagerActiveOnly),
                          showCheckmark: false,
                          selectedColor: palette.accent.withValues(alpha: 0.16),
                          labelStyle: context.texts.labelMedium?.copyWith(
                            color: _activeOnly
                                ? palette.accent
                                : palette.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          key: const Key('open_powertrain_battery_catalog'),
                          onPressed: () =>
                              context.push(PowertrainBatteryCatalogScreen.path),
                          icon: const Icon(Icons.electric_car_outlined, size: 18),
                          label: Text(l10n.pidManagerPowertrainBatteryCatalog),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (visible.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.search_off,
                  title: l10n.pidManagerNoMatchTitle,
                  message: l10n.pidManagerNoMatchMessage,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  0,
                  Spacing.lg,
                  Spacing.xxl,
                ),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: Spacing.sm),
                  itemBuilder: (context, index) {
                    final pid = visible[index];
                    return _PidRow(
                      pid: pid,
                      isActive: activeIds.contains(pid.id),
                      reading: snapshot[pid.id],
                      isStale: snapshot.isStale(pid),
                      // Only what the vehicle positively disclaimed. This
                      // used to be "absent from the supported set", which
                      // marks every PID in a block that failed to read —
                      // and every custom PID the masks describe at all —
                      // as one this car does not have.
                      isUnsupported:
                          summary.statusFor(pid) ==
                          PidCapabilityStatus.unsupported,
                      onToggle: () => _togglePid(pid),
                      // Encoded, not interpolated. `Pid.id` ends in
                      // `#<variant>` for an imported definition, and a
                      // raw `#` in a location string is a URI *fragment*:
                      // the editor received a truncated id, found nothing,
                      // opened blank as 新增自訂 PID, and saving created an
                      // unvarianted sibling instead of editing the PID the
                      // user had tapped.
                      onEdit: pid.isCustom
                          ? () => context.push(
                              Uri(
                                path: PidEditorScreen.path,
                                queryParameters: {'id': pid.id},
                              ).toString(),
                            )
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class PidCapabilityPanel extends StatelessWidget {
  const PidCapabilityPanel({
    super.key,
    required this.summary,
    required this.presentation,
    required this.onAdd,
  });

  final ObdCapabilitySummary summary;
  final SupportedPidBulkPresentation presentation;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phaseLabel = obdCapabilityPhaseLabel(l10n, summary.phase);
    final actionLabel = supportedPidBulkActionLabel(l10n, presentation);
    final through = summary.contiguousCoverageThroughPid;
    return Semantics(
      container: true,
      label: l10n.pidCapabilitySemantics(
        phaseLabel,
        presentation.confirmedCount,
        summary.unknownOrUnverifiedBlockCount,
      ),
      child: Panel(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.pidCapabilityTitle, style: context.texts.titleMedium),
            const SizedBox(height: Spacing.xs),
            Text(phaseLabel, style: context.texts.bodySmall),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.md,
              runSpacing: Spacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.pidCapabilityConfirmedCount(presentation.confirmedCount),
                ),
                Text(
                  l10n.pidCapabilityUnknownBlocks(
                    summary.unknownOrUnverifiedBlockCount,
                  ),
                ),
                if (through != null)
                  Text(
                    // The hex PID is a machine token in both languages; only
                    // the sentence around it changes.
                    summary.contiguousCoverageReachedVerifiedTerminal
                        ? l10n.pidCapabilityCoverageThroughEnd(
                            _hexPid(through),
                          )
                        : l10n.pidCapabilityCoverageThroughUnknown(
                            _hexPid(through),
                          ),
                  )
                else
                  Text(l10n.pidCapabilityCoverageNone),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Semantics(
              button: true,
              label: actionLabel,
              child: FilledButton.icon(
                onPressed: presentation.canAdd ? onAdd : null,
                icon: const Icon(Icons.playlist_add_check),
                label: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _hexPid(int value) =>
      value.toRadixString(16).toUpperCase().padLeft(2, '0');
}

class _PidRow extends StatelessWidget {
  const _PidRow({
    required this.pid,
    required this.isActive,
    required this.reading,
    required this.isStale,
    required this.isUnsupported,
    required this.onToggle,
    required this.onEdit,
  });

  final Pid pid;
  final bool isActive;
  final Reading? reading;

  /// Whether [reading] is too old to present as live.
  ///
  /// This screen read `snapshot[pid.id]` straight out of the map, so a sensor
  /// that had stopped answering minutes ago still showed its last number in
  /// exactly the same styling as a live one. The dashboard, the derived strip
  /// and the performance screen all honoured the staleness contract; this was
  /// the one place nobody had looked.
  final bool isStale;

  final bool isUnsupported;
  final Future<void> Function() onToggle;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final accent = context.gaugeColors(GaugeHue.forKey(pid.id)).bright;

    return Panel(
      accent: accent,
      isActive: isActive,
      onTap: () => unawaited(onToggle()),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: isActive ? accent : palette.hairline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        pid.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.titleSmall,
                      ),
                    ),
                    if (pid.isCustom) ...[
                      const SizedBox(width: Spacing.sm),
                      StatusPill(
                        label: l10n.pidPillCustom,
                        tone: StatusTone.accent,
                        dense: true,
                      ),
                    ],
                    if (isUnsupported) ...[
                      const SizedBox(width: Spacing.sm),
                      StatusPill(
                        label: l10n.pidPillUnsupported,
                        tone: StatusTone.warn,
                        dense: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      pid.modeAndPid,
                      style: AppTypography.code(palette, size: 11.5),
                    ),
                    Text('  ·  ', style: context.texts.bodySmall),
                    Flexible(
                      child: Text(
                        pid.equation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.code(
                          palette,
                          size: 11.5,
                          color: palette.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (reading != null) ...[
            const SizedBox(width: Spacing.sm),
            Opacity(
              // The same treatment the gauges use: a value that is no longer
              // arriving is dimmed rather than shown as though it were.
              opacity: isStale ? kStaleOpacity : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    reading!.formatted,
                    style: AppTypography.readout(palette, 17),
                  ),
                  Text(
                    isStale ? l10n.pidRowStaleUnits(pid.units) : pid.units,
                    style: context.texts.labelSmall,
                  ),
                ],
              ),
            ),
          ],
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: l10n.pidRowEdit,
            ),
          // A bare switch announces only "on"/"off" with no subject. In a
          // list of twenty-three rows that is not enough to act on.
          //
          // `pid.name` is the author's own text and goes through verbatim in
          // either language; it is data, never a key.
          Semantics(
            label: l10n.pidRowShowOnDashboard(pid.name),
            child: Switch(
              value: isActive,
              onChanged: (_) => unawaited(onToggle()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Drag-to-reorder sheet for the dashboard layout.
///
/// Order matters here: the grid fills row by row, so the first few entries are
/// the ones a driver sees without scrolling.
class _ArrangeSheet extends ConsumerWidget {
  const _ArrangeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Captured once, before the reorder callback awaits: the refusal must be
    // in the language that was on screen when the drag happened.
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final active = ref.watch(activePidsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.sm,
                Spacing.lg,
                Spacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.pidManagerArrangeDashboard,
                    style: context.texts.headlineSmall,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(l10n.pidArrangeBody, style: context.texts.bodySmall),
                ],
              ),
            ),
            Expanded(
              child: active.isEmpty
                  ? EmptyState(
                      icon: Icons.tune,
                      title: l10n.pidArrangeEmptyTitle,
                      message: l10n.pidArrangeEmptyMessage,
                    )
                  : ReorderableListView.builder(
                      scrollController: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        Spacing.lg,
                        0,
                        Spacing.lg,
                        Spacing.xxl,
                      ),
                      itemCount: active.length,
                      // onReorderItem rather than the deprecated onReorder:
                      // it hands back a newIndex already adjusted for the
                      // dragged item having left the list.
                      onReorderItem: (oldIndex, newIndex) {
                        unawaited(() async {
                          final outcome = await ref
                              .read(activePidsProvider.notifier)
                              .reorder(oldIndex, newIndex);
                          final failure = outcome.failure;
                          if (failure != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  pidMutationFailureText(l10n, failure),
                                ),
                              ),
                            );
                          }
                        }());
                      },
                      itemBuilder: (context, index) {
                        final pid = active[index];
                        final accent = context
                            .gaugeColors(GaugeHue.forKey(pid.id))
                            .bright;
                        return Padding(
                          key: ValueKey(pid.id),
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: Panel(
                            accent: accent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.md,
                              vertical: Spacing.sm,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(
                                      Radii.sm - 2,
                                    ),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: context.texts.labelMedium?.copyWith(
                                      color: accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: Spacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pid.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.texts.titleSmall,
                                      ),
                                      Text(
                                        pid.modeAndPid,
                                        style: AppTypography.code(
                                          palette,
                                          size: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Icon(
                                    Icons.drag_handle,
                                    color: palette.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
