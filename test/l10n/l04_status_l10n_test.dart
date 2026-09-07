// The data-status vocabulary, in both shipped languages.
//
// This is the most safety-loaded copy in the app: it is what stands between a
// number and a reader's belief about where the number came from. So what is
// checked here is never "does the function return its own ARB entry" — a
// finder that reads the same entry the code read agrees with itself however
// wrong the translation is. It checks the properties a wrong translation
// breaks, and every one of them is a line the app exists to draw:
//
//   * estimated is not measured;
//   * unverified is neither invalid nor verified, and "unverified on this
//     vehicle" keeps its scope;
//   * partial is not all clear;
//   * stale is not live;
//   * out of range says a check ran and failed, not that a number looked odd;
//   * simulated data is unmistakable;
//   * no response is not "unsupported" — silence is not a controller saying
//     it lacks a PID;
//   * the exported sentence does not move when the phone's language does.
//
// No widget pumps. Every mapper takes an `AppLocalizations` parameter rather
// than a `BuildContext`, which is what lets this file walk both locales.
//
// "Still Chinese" comes from `test/support/cjk.dart`, not from a `RegExp`
// written here. This file used to hold its own — `[㐀-鿿豈-﫿]`, Han
// ideographs and nothing else — which is the ninth copy of a detector eight
// of whose versions had that same blind spot, and the blind spot has shipped:
// the powertrain catalogue joined signal names with `、` and eighteen commands
// rendered "Battery temperature 1、Battery temperature 2" to an English reader
// past every green test. `chinese` covers the punctuation too, so it is
// strictly stronger than what it replaced here rather than a rename: put a `、`
// in an English ARB entry these mappers read and this file now fails on it,
// where the Han-only version passed.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/availability.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/physics/vehicle_profile.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/vehicle_identity.dart';
import 'package:torque_obd/ui/screens/connect/handshake_copy.dart';
import 'package:torque_obd/ui/widgets/status/datum_status_copy.dart';

import '../support/cjk.dart';
import '../support/dart_source_reader.dart';

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);
  final locales = {'en': en, 'zh': zh};

  group('every identifier is answered in both languages', () {
    void bothLocales<T>(
      Iterable<T> values,
      String Function(AppLocalizations, T) label,
    ) {
      for (final value in values) {
        for (final entry in locales.entries) {
          expect(
            label(entry.value, value).trim(),
            isNotEmpty,
            reason: '$value has no ${entry.key} copy',
          );
        }
        // gen-l10n does not fail on a missing translation, it falls back to
        // the template. Identical copy in both languages is what that looks
        // like from here.
        expect(
          label(en, value),
          isNot(label(zh, value)),
          reason: '$value fell back to the English template',
        );
        expect(
          chinese.hasMatch(label(en, value)),
          isFalse,
          reason: '$value carries Chinese in the English build',
        );
      }
    }

    test('DatumBadge', () => bothLocales(DatumBadge.values, datumBadgeLabel));
    test('DatumGap', () => bothLocales(DatumGap.values, datumGapLabel));
    test('DatumReason', () => bothLocales(DatumReason.values, datumReasonLabel));
    test(
      'DatumNextStep',
      () => bothLocales(DatumNextStep.values, datumNextStepLabel),
    );

    test('no two badges share a word in either language', () {
      for (final entry in locales.entries) {
        final rendered = <String, DatumBadge>{};
        for (final badge in DatumBadge.values) {
          final label = datumBadgeLabel(entry.value, badge);
          expect(
            rendered.containsKey(label),
            isFalse,
            reason:
                '$badge and ${rendered[label]} both render "$label" in '
                '${entry.key}; two distinctions collapsed into one word',
          );
          rendered[label] = badge;
        }
      }
    });
  });

  group('the distinctions survive translation', () {
    test('estimated never claims to be measured', () {
      expect(en.datumBadgeEstimated.toLowerCase(), isNot(contains('measure')));
      expect(zh.datumBadgeEstimated, isNot(contains('實測')));
      for (final entry in locales.entries) {
        expect(
          datumBadgeLabel(entry.value, DatumBadge.estimated),
          isNot(datumBadgeLabel(entry.value, DatumBadge.fieldVerified)),
          reason: entry.key,
        );
      }
    });

    test('unverified is neither invalid nor verified', () {
      for (final entry in locales.entries) {
        final unverified = datumBadgeLabel(entry.value, DatumBadge.unverified);
        final invalid = datumBadgeLabel(entry.value, DatumBadge.invalid);
        final verified = datumBadgeLabel(entry.value, DatumBadge.fieldVerified);
        expect(unverified, isNot(invalid), reason: entry.key);
        expect(unverified, isNot(verified), reason: entry.key);
        // Neither may be read out of the other: an "unverified" that contains
        // "invalid" as a whole rendering would be a badge whose meaning
        // depends on the reader noticing a prefix.
        expect(unverified.contains(invalid), isFalse, reason: entry.key);
      }
    });

    test('the on-this-vehicle scope is not dropped', () {
      for (final entry in locales.entries) {
        final scoped = datumBadgeLabel(
          entry.value,
          DatumBadge.unverifiedOnThisVehicle,
        );
        final bare = datumBadgeLabel(entry.value, DatumBadge.unverified);
        expect(scoped, isNot(bare), reason: entry.key);
        // The scope is the whole point of the second badge; a rendering no
        // longer than the bare one has lost it.
        expect(scoped.length, greaterThan(bare.length), reason: entry.key);
      }
      expect(
        en.datumBadgeUnverifiedOnThisVehicle.toLowerCase(),
        contains('this vehicle'),
      );
      expect(zh.datumBadgeUnverifiedOnThisVehicle, contains('本車'));
    });

    test('partial is not all clear', () {
      final partial = en.datumBadgePartial.toLowerCase();
      for (final wrong in ['clear', 'complete', 'none', 'no fault', 'ok']) {
        expect(partial, isNot(contains(wrong)));
      }
      for (final entry in locales.entries) {
        expect(
          datumBadgeLabel(entry.value, DatumBadge.partial),
          isNot(datumBadgeLabel(entry.value, DatumBadge.invalid)),
          reason: entry.key,
        );
      }
    });

    test('stale is not live', () {
      final stale = en.datumBadgeStale.toLowerCase();
      for (final wrong in ['live', 'current', 'fresh', 'now', 'updated']) {
        expect(stale, isNot(contains(wrong)));
      }
      for (final entry in locales.entries) {
        expect(
          datumBadgeLabel(entry.value, DatumBadge.stale),
          isNot(datumBadgeLabel(entry.value, DatumBadge.justUpdated)),
          reason: entry.key,
        );
      }
    });

    test('out of range says a check failed, not that a number looked odd', () {
      final label = en.datumBadgeOutOfReferenceRange.toLowerCase();
      for (final vague in ['odd', 'unusual', 'strange', 'suspicious']) {
        expect(label, isNot(contains(vague)));
      }
      // And the reason keeps both halves: a check failed, AND the reading was
      // not discarded or clamped.
      expect(
        en.datumReasonOutOfReferenceRangeKept.toLowerCase(),
        contains('range'),
      );
      expect(
        en.datumReasonOutOfReferenceRangeKept.toLowerCase(),
        contains('kept'),
      );
      expect(zh.datumReasonOutOfReferenceRangeKept, contains('已保留'));
    });

    test('simulated data cannot be mistaken for a vehicle reading', () {
      for (final entry in locales.entries) {
        final demo = datumBadgeLabel(entry.value, DatumBadge.demo);
        for (final other in DatumBadge.values.where(
          (badge) => badge != DatumBadge.demo,
        )) {
          expect(
            demo,
            isNot(datumBadgeLabel(entry.value, other)),
            reason: '$other reads the same as demo in ${entry.key}',
          );
        }
      }
      // A demo reading earns the badge no matter what else is true of it: the
      // engine adds it from the origin alone.
      for (final evidence in EvidenceKind.values) {
        for (final quality in DatumQuality.values) {
          expect(
            DatumStatus(
              availability: FeatureAvailability.usable,
              origin: DatumOrigin.demo,
              evidence: evidence,
              compatibility: Compatibility.unknown,
              quality: quality,
              operationRisk: OperationRisk.display,
              reasonCode: null,
            ).badges,
            contains(DatumBadge.demo),
            reason: '$evidence/$quality',
          );
        }
      }
    });

    test('no response is not unsupported', () {
      // docs/i18n/hedge-register.md entry 16. Silence is the adapter reporting
      // that nothing arrived; it is not a controller saying it lacks a PID,
      // and the two must not be readable as each other in either language.
      for (final entry in locales.entries) {
        final silence = datumReasonLabel(entry.value, DatumReason.noAnswer);
        final unsupported = datumReasonLabel(
          entry.value,
          DatumReason.pidUnsupported,
        );
        expect(silence, isNot(unsupported), reason: entry.key);
        expect(silence.contains(unsupported), isFalse, reason: entry.key);
        expect(unsupported.contains(silence), isFalse, reason: entry.key);
      }
      expect(en.datumReasonNoAnswer.toLowerCase(), isNot(contains('support')));
      expect(zh.datumReasonNoAnswer, isNot(contains('不支援')));
    });

    test('a definition problem is not a claim about the car', () {
      // headerNotOnThisBus is a statement about the PID; unsupported is a
      // statement about the vehicle. Merging them sends somebody looking at
      // their car for a problem that is in a field they can edit.
      for (final entry in locales.entries) {
        expect(
          datumReasonLabel(entry.value, DatumReason.headerNotOnThisBus),
          isNot(datumReasonLabel(entry.value, DatumReason.pidUnsupported)),
          reason: entry.key,
        );
      }
    });

    test('no reading yet is words, never a zero or a dash', () {
      // hedge-register entry 25: rendering the absence of a value as "0" or
      // "--" reintroduces exactly the failure the tagline forbids.
      for (final entry in locales.entries) {
        final label = datumReasonLabel(entry.value, DatumReason.noReadingYet);
        expect(
          label.replaceAll(RegExp(r'[\s0.-]'), ''),
          isNotEmpty,
          reason: entry.key,
        );
        expect(label, isNot(contains('0')), reason: entry.key);
      }
    });

    test('the unconfirmed-assumption hedge keeps both halves', () {
      // hedge-register entry 18: "unconfirmed" alone reads as an error and
      // "an estimate is shown" alone reads as a validated number.
      final english = en.datumReasonAssumptionsUnconfirmed.toLowerCase();
      expect(english, contains('unconfirmed'));
      expect(english, contains('estimate'));
      expect(zh.datumReasonAssumptionsUnconfirmed, contains('尚未確認'));
      expect(zh.datumReasonAssumptionsUnconfirmed, contains('仍可估算'));
    });

    test('a refused service says nothing was sent', () {
      expect(
        en.datumReasonUnsafeServiceStopped.toLowerCase(),
        contains('not sent'),
      );
      expect(zh.datumReasonUnsafeServiceStopped, contains('已停止發送'));
    });

    test('a missing estimate never reads as a measured zero', () {
      for (final entry in locales.entries) {
        for (final reason in [
          DatumReason.horsepowerEstimateMissingInputs,
          DatumReason.fuelEstimateMissingInputs,
        ]) {
          final label = datumReasonLabel(entry.value, reason);
          expect(label, isNot(contains('0')), reason: '$reason ${entry.key}');
        }
        expect(
          datumReasonLabel(
            entry.value,
            DatumReason.horsepowerEstimateMissingInputs,
          ),
          isNot(
            datumReasonLabel(
              entry.value,
              DatumReason.fuelEstimateMissingInputs,
            ),
          ),
          reason: entry.key,
        );
      }
    });

    test('one failed item never reads as the session failing', () {
      for (final entry in locales.entries) {
        expect(
          datumNextStepLabel(
            entry.value,
            DatumNextStep.otherReadingsUnaffected,
          ),
          isNot(
            datumNextStepLabel(
              entry.value,
              DatumNextStep.estimateOnlyOtherReadingsUnaffected,
            ),
          ),
          reason: entry.key,
        );
      }
      expect(en.datumNextStepOtherReadings.toLowerCase(), contains('only'));
      expect(en.datumNextStepGenericObd, contains('OBD'));
    });
  });

  group('what the engine hands the screen', () {
    test('every reason a live PID can carry is translated', () {
      // datumReasonText has no last fallback any more: it resolves gaps, then
      // reasonCode, then statusReason, and returns null. So a live PID whose
      // reason has no identifier is not Chinese on an English screen — it is
      // no line at all, and the reader is told nothing about why the number is
      // missing. Walking the whole PidFault enum is what says every one of
      // them has an identifier and every identifier is translated.
      for (final fault in [...PidFault.values, null]) {
        final status = AvailabilityPolicy.forPid(
          pid: PidLibrary.engineRpm,
          fault: fault,
        );
        final text = datumReasonText(en, status);
        expect(text, isNotNull, reason: '$fault');
        expect(chinese.hasMatch(text!), isFalse, reason: '$fault -> $text');
      }
    });

    test('the session chip renders gaps, not the exported sentence', () {
      final status = AvailabilityPolicy.genericObdSession(
        identity: const VehicleIdentity.unavailable(),
        catalogMatched: false,
      );
      expect(status.gaps, contains(DatumGap.vinNotRead));
      expect(status.gaps, contains(DatumGap.noCatalogMatch));
      final text = datumReasonText(en, status)!;
      expect(chinese.hasMatch(text), isFalse);
      // VIN is on docs/i18n/do-not-translate.md and survives in both.
      expect(text, contains('VIN'));
      expect(datumReasonText(zh, status), contains('VIN'));
      // A gap is a read outcome, never a claim that the car has no VIN.
      expect(en.datumGapVinNotRead.toLowerCase(), contains('not read'));
    });

    test('an out-of-range estimate keeps its badge in both languages', () {
      final status = AvailabilityPolicy.forEstimate(
        profile: const VehicleProfile(massKg: 1280, isConfirmed: false),
        value: 5000,
        formula: AvailabilityPolicy.horsepowerFormula,
        kind: EstimateKind.horsepower,
      );
      expect(status.badges, contains(DatumBadge.estimated));
      expect(status.badges, contains(DatumBadge.outOfReferenceRange));
      for (final entry in locales.entries) {
        expect(
          datumBadgeText(entry.value, status),
          contains(datumBadgeLabel(entry.value, DatumBadge.estimated)),
          reason: entry.key,
        );
      }
      expect(chinese.hasMatch(datumBadgeText(en, status)), isFalse);
    });
  });

  group('the export does not follow the phone', () {
    test('exportFields carry no localized copy', () {
      final status = AvailabilityPolicy.forEstimate(
        profile: const VehicleProfile(massKg: 1280, isConfirmed: false),
        value: 145,
        formula: AvailabilityPolicy.horsepowerFormula,
        kind: EstimateKind.horsepower,
      );
      final fields = status.exportFields;
      // Issue #46 owns these three; this wave must not have moved them.
      expect(fields['reason'], '假設尚未確認，仍可估算');
      expect(fields['formula'], AvailabilityPolicy.horsepowerFormula);
      expect(fields['assumptions'], contains('通用預設'));
      expect(fields.keys, isNot(contains('badges')));
      expect(fields.keys, isNot(contains('next_step')));
      for (final badge in DatumBadge.values) {
        expect(
          fields.values.join(' '),
          isNot(contains(datumBadgeLabel(en, badge))),
          reason: '$badge leaked into the export',
        );
      }
    });

    test('the same status exports one string whatever the reader reads', () {
      // The exported sentence is a property of the datum, and the mappers
      // above cannot reach it: nothing here takes an AppLocalizations.
      final status = AvailabilityPolicy.forPid(
        pid: PidLibrary.engineRpm,
        fault: PidFault.unsupported,
      );
      expect(status.reason, '此車輛不支援這個 PID');
      expect(status.reasonCode, DatumReason.pidUnsupported);
      expect(datumReasonText(en, status), en.datumReasonPidUnsupported);
      expect(datumReasonText(zh, status), zh.datumReasonPidUnsupported);
    });
  });

  group('the handshake speaks to whoever is standing at the car', () {
    test('every step in the shipped sequence is explained twice', () {
      for (final step in Elm327Client.initSequence) {
        for (final entry in locales.entries) {
          final label = initStepPurposeLabel(entry.value, step.command);
          expect(label.trim(), isNotEmpty, reason: '${step.command} ${entry.key}');
          expect(
            label,
            isNot(step.command),
            reason: '${step.command} has no ${entry.key} purpose, so the row '
                'prints the command twice',
          );
        }
        expect(
          initStepPurposeLabel(en, step.command),
          isNot(initStepPurposeLabel(zh, step.command)),
          reason: '${step.command} fell back to the English template',
        );
        expect(
          chinese.hasMatch(initStepPurposeLabel(en, step.command)),
          isFalse,
          reason: '${step.command} en',
        );
      }
    });

    test('an unknown command falls back to itself, never to a guess', () {
      expect(initStepPurposeLabel(en, 'ATPPS'), 'ATPPS');
      expect(initStepPurposeLabel(zh, 'ATPPS'), 'ATPPS');
    });

    test('InitNote', () {
      for (final note in InitNote.values) {
        for (final entry in locales.entries) {
          expect(
            initNoteLabel(entry.value, note).trim(),
            isNotEmpty,
            reason: '$note ${entry.key}',
          );
        }
        expect(
          initNoteLabel(en, note),
          isNot(initNoteLabel(zh, note)),
          reason: '$note fell back to the English template',
        );
        expect(chinese.hasMatch(initNoteLabel(en, note)), isFalse, reason: '$note');
      }
    });

    test('Elm327ErrorCode, and none says nothing', () {
      for (final entry in locales.entries) {
        expect(adapterErrorLabel(entry.value, Elm327ErrorCode.none), isEmpty);
      }
      for (final code in Elm327ErrorCode.values) {
        if (code == Elm327ErrorCode.none) continue;
        for (final entry in locales.entries) {
          expect(
            adapterErrorLabel(entry.value, code).trim(),
            isNotEmpty,
            reason: '$code ${entry.key}',
          );
        }
        expect(
          adapterErrorLabel(en, code),
          isNot(adapterErrorLabel(zh, code)),
          reason: '$code fell back to the English template',
        );
        expect(
          chinese.hasMatch(adapterErrorLabel(en, code)),
          isFalse,
          reason: '$code en',
        );
      }
    });

    test('NO DATA keeps both of its explanations', () {
      // Silence is the adapter reporting that nothing arrived before its own
      // timeout. Rendering it as a flat capability claim is the mistake this
      // codebase is organised against.
      final english = en.adapterErrorNoData.toLowerCase();
      expect(english, contains('may'));
      expect(zh.adapterErrorNoData, contains('可能'));
      for (final entry in locales.entries) {
        expect(
          adapterErrorLabel(entry.value, Elm327ErrorCode.noData),
          isNot(
            adapterErrorLabel(entry.value, Elm327ErrorCode.unknownCommand),
          ),
          reason: '${entry.key}: the adapter and the vehicle are not the same '
              'subject',
        );
      }
    });

    test('a classified failure is never flattened into silence', () {
      // `obd_session` writes 初始化在 X 失敗（<detail> 或 無回應）. If the error
      // moved into `errorCode` and left `detail` null, every handshake failure
      // — CAN ERROR, UNABLE TO CONNECT, LV RESET — would come out as "no
      // response", which is the one thing it is not.
      for (final code in Elm327ErrorCode.values) {
        if (code == Elm327ErrorCode.none) continue;
        final progress = InitProgress(
          step: Elm327Client.initSequence.first,
          index: 0,
          total: Elm327Client.initSequence.length,
          status: InitStatus.failed,
          errorCode: code,
        );
        expect(progress.detail, code.description, reason: '$code');
        expect(progress.detail, isNotEmpty, reason: '$code');
        expect(initProgressLine(en, progress), adapterErrorLabel(en, code));
      }
    });

    test('the note keeps the wording the transcript already reads', () {
      for (final note in InitNote.values) {
        final progress = InitProgress(
          step: Elm327Client.initSequence.first,
          index: 0,
          total: Elm327Client.initSequence.length,
          status: InitStatus.failed,
          note: note,
        );
        expect(progress.detail, initNoteText(note), reason: '$note');
        expect(initProgressLine(en, progress), initNoteLabel(en, note));
        expect(chinese.hasMatch(initProgressLine(en, progress)), isFalse);
      }
      expect(initNoteText(InitNote.aborted), '已中止');
      expect(initNoteText(InitNote.timedOut), '逾時');
    });

    test('adapter data is shown as it arrived, never translated', () {
      // Version strings, voltages and protocol names are evidence, not copy.
      final progress = InitProgress(
        step: Elm327Client.initSequence.first,
        index: 0,
        total: Elm327Client.initSequence.length,
        status: InitStatus.ok,
        detail: 'ELM327 v1.5',
      );
      for (final entry in locales.entries) {
        expect(initProgressLine(entry.value, progress), 'ELM327 v1.5');
      }
    });

    test('a running step explains what it is doing', () {
      final step = Elm327Client.initSequence.firstWhere(
        (candidate) => candidate.command == '0100',
      );
      final progress = InitProgress(
        step: step,
        index: 0,
        total: Elm327Client.initSequence.length,
        status: InitStatus.running,
      );
      expect(initProgressLine(en, progress), en.handshakeStepSupportProbe);
      expect(initProgressLine(zh, progress), zh.handshakeStepSupportProbe);
    });
  });

  group('why a connection ended', () {
    InitProgress step({
      required int index,
      InitNote? note,
      Elm327ErrorCode? errorCode,
    }) => InitProgress(
      step: Elm327Client.initSequence[index],
      index: index,
      total: Elm327Client.initSequence.length,
      status: InitStatus.failed,
      note: note,
      errorCode: errorCode,
    );

    ObdConnectionState failed(ObdConnectionIssue issue, {InitProgress? at}) =>
        ObdConnectionState(
          phase: ConnectionPhase.failed,
          error: 'exported sentence',
          issue: issue,
          issueStep: at,
        );

    test('every issue is answered in both languages', () {
      for (final issue in ObdConnectionIssue.values) {
        final state = failed(
          issue,
          at: step(index: 1, errorCode: Elm327ErrorCode.canError),
        );
        for (final entry in locales.entries) {
          final text = connectionIssueText(entry.value, state);
          expect(text, isNotNull, reason: '$issue ${entry.key}');
          expect(text!.trim(), isNotEmpty, reason: '$issue ${entry.key}');
        }
        expect(
          connectionIssueText(en, state),
          isNot(connectionIssueText(zh, state)),
          reason: '$issue fell back to the English template',
        );
        expect(
          chinese.hasMatch(connectionIssueText(en, state)!),
          isFalse,
          reason: '$issue en',
        );
      }
    });

    test('every busy activity is answered in both languages', () {
      for (final activity in ObdConnectionActivity.values) {
        final state = ObdConnectionState(
          phase: ConnectionPhase.connecting,
          activity: activity,
        );
        expect(chinese.hasMatch(connectionActivityText(en, state)!), isFalse);
        expect(
          connectionActivityText(en, state),
          isNot(connectionActivityText(zh, state)),
          reason: '$activity fell back to the English template',
        );
      }
      expect(
        connectionActivityText(en, const ObdConnectionState()),
        isNull,
      );
    });

    test('a classified handshake failure never reads as silence', () {
      // The trap this refactor could have walked into: move the adapter's
      // error into `errorCode`, leave `detail` null, and every failure —
      // CAN ERROR, UNABLE TO CONNECT, LV RESET — comes out of the sentence
      // 初始化在 X 失敗（無回應）as "no response", which is the one thing it
      // is not.
      for (final code in Elm327ErrorCode.values) {
        if (code == Elm327ErrorCode.none) continue;
        final state = failed(
          ObdConnectionIssue.handshakeStepFailed,
          at: step(index: 3, errorCode: code),
        );
        final text = connectionIssueText(en, state)!;
        expect(text, contains(adapterErrorLabel(en, code)), reason: '$code');
        expect(
          text,
          isNot(contains(en.handshakeStepNoReason)),
          reason: '$code was flattened into silence',
        );
        expect(
          text,
          contains(Elm327Client.initSequence[3].command),
          reason: 'the command that died is the value of the message',
        );
      }
    });

    test('a refused reply names the refusal, not the step purpose', () {
      final state = failed(
        ObdConnectionIssue.handshakeStepFailed,
        at: step(index: 1, note: InitNote.notAcknowledged),
      );
      final text = connectionIssueText(en, state)!;
      expect(text, contains(en.handshakeNoteNotAcknowledged));
      expect(text, isNot(contains(en.handshakeStepEchoOff)));
    });

    test('a transport sentence is still shown rather than dropped', () {
      // The four transports author their own messages and this wave did not
      // move them. `issue` is null there, and the caller falls back.
      const state = ObdConnectionState(
        phase: ConnectionPhase.failed,
        error: '轉接器不在範圍內',
      );
      expect(connectionIssueText(en, state), isNull);
      expect(state.error, '轉接器不在範圍內');
    });

    test('the exported sentence and the identifier are cleared together', () {
      final state = failed(ObdConnectionIssue.adapterStoppedResponding);
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
      expect(cleared.issue, isNull);
      expect(cleared.issueStep, isNull);
    });

    test('a new busy line drops the activity the last one carried', () {
      // Otherwise a Bluetooth Classic tier notice inherits "stopping the
      // previous connection" and the screen keeps saying it.
      const aborting = ObdConnectionState(
        phase: ConnectionPhase.connecting,
        detail: '正在中止上一個連線，請稍候…',
        activity: ObdConnectionActivity.abortingPreviousConnection,
      );
      final tier = aborting.copyWith(detail: '未加密 SPP 連線');
      expect(tier.activity, isNull);
      expect(connectionActivityText(en, tier), isNull);
    });

    test('the transcript keeps the sentence it always wrote', () {
      // `_failAttempt` records `error` into the attempt transcript, which is
      // evidence. Localizing it would make two readers' records incomparable.
      expect(
        describeConnectException(TimeoutException('x')),
        contains('多數 OBD 插座要電門轉到 ON 才供電'),
      );
      expect(
        connectExceptionIssue(TimeoutException('x')),
        ObdConnectionIssue.adapterAcceptedThenSilent,
      );
      expect(
        connectExceptionIssue(StateError('x')),
        ObdConnectionIssue.connectionSetupFailed,
      );
    });
  });

  test('the engine layer never reaches for a localization', () {
    // The architectural rule this wave exists to keep. `flutter/foundation`
    // and `flutter/services` are already used by the catalogs and are not
    // widgets; what may never appear is AppLocalizations, BuildContext, or a
    // widget library.
    final banned = RegExp(
      r'package:flutter/(material|widgets|cupertino)\.dart'
      r'|AppLocalizations'
      r'|BuildContext',
    );
    final offenders = <String>[];
    for (final directory in ['lib/obd', 'lib/diagnostics']) {
      for (final entity in Directory(directory).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        // Comments may name the rule; code may not import it. Through the
        // shared reader rather than a line-prefix test, because a comment does
        // not have to start the line: `const x = 1; // AppLocalizations` was
        // read as code and this guard accused the file that documented its own
        // rule. Not `codeOnly` either — the thing it forbids is
        // `import 'package:flutter/material.dart'`, which is a string literal,
        // and blanking literals would leave the scan seeing nothing while
        // still reporting success.
        final code = withoutComments(entity.readAsStringSync());
        if (banned.hasMatch(code)) offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty);
  });
}
