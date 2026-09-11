import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_csv.dart';
import 'package:torque_obd/obd/pid/priority_tier.dart';

void main() {
  _reorderedColumns();
  _strictParsingTests();
  _torqueProCompatibility();
  _humanReportNotReimported();
  group('export / import round trip', () {
    test(
      'streamed export preserves exact CSV bytes in bounded chunks',
      () async {
        const pid = Pid(
          name: 'Coolant',
          shortName: 'ECT',
          modeAndPid: '0105',
          equation: 'A-40',
          minValue: -40,
          maxValue: 215,
          units: '°C',
        );
        final chunks = await PidCsv.stream([pid], maxChunkBytes: 32).toList();
        expect(chunks.every((chunk) => chunk.length <= 32), isTrue);
        expect(
          chunks.expand((chunk) => chunk),
          utf8.encode(PidCsv.export([pid])),
        );
      },
    );
    test('every field survives a round trip', () {
      const original = Pid(
        name: 'Transmission Fluid Temp',
        shortName: 'Trans',
        modeAndPid: '221E1C',
        equation: '((A*256)+B)/8-40',
        minValue: -40,
        maxValue: 215,
        units: '°C',
        header: '7E1',
        priority: PriorityTier.high,
        redlineFrom: 120,
        isCustom: true,
      );

      final result = PidCsv.parse(PidCsv.export([original]));
      expect(result.errors, isEmpty);
      final restored = result.pids.single;

      expect(restored.name, original.name);
      expect(restored.shortName, original.shortName);
      expect(restored.modeAndPid, original.modeAndPid);
      expect(restored.equation, original.equation);
      expect(restored.minValue, original.minValue);
      expect(restored.maxValue, original.maxValue);
      // Unit labels are the reason the exporter writes a BOM.
      expect(restored.units, '°C');
      expect(restored.header, '7E1');
      expect(restored.priority, PriorityTier.high);
      expect(restored.redlineFrom, 120);
      expect(restored.isCustom, isTrue);
    });

    test('the Torque subset export is not the Telltale complete export', () {
      const original = Pid(
        name: 'Transmission Fluid Temp',
        shortName: 'Trans',
        modeAndPid: '221E1C',
        equation: '((A*256)+B)/8-40',
        minValue: -40,
        maxValue: 215,
        units: '°C',
        header: '7E1',
        priority: PriorityTier.high,
        redlineFrom: 120,
        variant: 'tf',
        isCustom: true,
      );

      final complete = PidCsv.export([original]);
      final subset = PidCsv.exportTorqueSubset([original]);
      expect(complete, isNot(subset));
      expect(complete, contains('Priority'));
      expect(complete, contains('Redline'));
      expect(complete, contains('Variant'));
      expect(subset, isNot(contains('Priority')));
      expect(subset, isNot(contains('Redline')));
      expect(subset, isNot(contains('Variant')));
      expect(
        subset,
        contains('OBD Header'),
        reason: 'Torque consumers match the documented eighth column name',
      );
      expect(
        subset.split('\r\n').first,
        isNot(contains(',Header')),
        reason: 'the Telltale Header spelling is not the Torque subset heading',
      );

      final restored = PidCsv.parse(subset);
      expect(restored.errors, isEmpty);
      expect(restored.pids.single.name, original.name);
      expect(restored.pids.single.equation, original.equation);
      expect(restored.pids.single.header, '7E1');
      expect(restored.pids.single.units, '°C');
      expect(
        restored.pids.single.priority,
        PriorityTier.medium,
        reason: 'lossy Torque interchange must not invent Telltale metadata',
      );
      expect(restored.pids.single.redlineFrom, isNull);
      expect(restored.pids.single.variant, isNull);
    });

    test(
      'streamed Torque subset preserves exact subset bytes in bounded chunks',
      () async {
        const original = Pid(
          name: 'Transmission Fluid Temp',
          shortName: 'Trans',
          modeAndPid: '221E1C',
          equation: '((A*256)+B)/8-40',
          minValue: -40,
          maxValue: 215,
          units: '°C',
          header: '7E1',
          priority: PriorityTier.high,
          redlineFrom: 120,
          variant: 'tf',
          isCustom: true,
        );
        final chunks = await PidCsv.streamTorqueSubset(
          [original],
          maxChunkBytes: 32,
        ).toList();
        expect(chunks.every((chunk) => chunk.length <= 32), isTrue);
        expect(
          chunks.expand((chunk) => chunk),
          utf8.encode(PidCsv.exportTorqueSubset([original])),
        );
        expect(
          utf8.decode(chunks.expand((chunk) => chunk).toList()),
          isNot(contains('Priority')),
        );
      },
    );

    test(
      're-exporting a parsed Torque subset still uses OBD Header',
      () {
        const original = Pid(
          name: 'Transmission Fluid Temp',
          shortName: 'Trans',
          modeAndPid: '221E1C',
          equation: '((A*256)+B)/8-40',
          minValue: -40,
          maxValue: 215,
          units: '°C',
          header: '7E1',
          priority: PriorityTier.high,
          redlineFrom: 120,
          variant: 'tf',
          isCustom: true,
        );
        final first = PidCsv.exportTorqueSubset([original]);
        final restored = PidCsv.parse(first).pids.single;
        final second = PidCsv.exportTorqueSubset([restored]);
        expect(
          second.split('\r\n').first,
          contains('OBD Header'),
          reason: 'human interchange must keep Torque\'s eighth heading',
        );
        expect(
          second.split('\r\n').first,
          isNot(contains(',Header')),
          reason: 're-export must not switch back to the Telltale Header spelling',
        );
        expect(PidCsv.parse(second).errors, isEmpty);
        expect(PidCsv.parse(second).pids.single.header, '7E1');
        expect(PidCsv.parse(second).pids.single.priority, PriorityTier.medium);
        expect(second, isNot(contains('Priority')));
      },
    );

    test('Torque subset cells are selected by Telltale column name', () {
      final source = File('lib/obd/pid/pid_csv.dart').readAsStringSync();
      expect(
        source.contains('sublist(0, torqueHeader.length)'),
        isFalse,
        reason:
            'positional slice would put Priority under OBD Header if a '
            'Telltale-only column is inserted before Header',
      );
    });
  });

  group('parsing files from elsewhere', () {
    test('reads a stock eight-column Torque file', () {
      const wire =
          'Name,ShortName,ModeAndPID,Equation,Min Value,Max Value,Units,Header\r\n'
          'Engine RPM,RPM,010C,((A*256)+B)/4,0,8000,rpm,7E0\r\n';
      final result = PidCsv.parse(wire);
      expect(result.errors, isEmpty);
      expect(result.pids.single.modeAndPid, '010C');
      expect(result.pids.single.units, 'rpm');
    });

    test('a file with no header row still parses', () {
      const wire = 'Boost,Boost,010B,A-101,-100,200,kPa,7E0\r\n';
      expect(PidCsv.parse(wire).pids, hasLength(1));
    });

    test('a UTF-8 BOM does not end up inside the first column', () {
      const wire =
          '﻿Name,ShortName,ModeAndPID,Equation,Min Value,Max Value,Units,Header\r\n'
          'Oil Temp,Oil,015C,A-40,-40,215,°C,7E0\r\n';
      final result = PidCsv.parse(wire);
      expect(result.pids.single.name, 'Oil Temp');
    });

    test('bad rows are reported rather than silently skipped', () {
      const wire =
          'Good,G,010C,A,0,100,x,7E0\r\n'
          'Broken,B,ZZ,A,0,100,x,7E0\r\n'
          'NoFormula,N,0105,,0,100,x,7E0\r\n';
      final result = PidCsv.parse(wire);
      expect(result.pids, hasLength(1));
      expect(result.errors, hasLength(2));
      // The row, by number rather than by a substring that any digit anywhere
      // in the sentence would have satisfied.
      expect(result.errors.first.lineNumber, 2);
      expect(result.errors.first.issue, PidCsvIssue.rowInvalidModeAndPid);
      // And the cell it choked on, not just that it choked. The importer
      // deliberately refuses rather than repairs — `22-11O1` with a letter O
      // must not become the valid-and-different `22111` — so the reader has to
      // see the characters they wrote. `text: cell(2)` is a second copy of
      // that value now the sentence no longer interpolates it at the throw;
      // replacing it with `'ZZZ'` left the suite green.
      expect(result.errors.first.text, 'ZZ');
      expect(result.errors.last.lineNumber, 3);
      expect(result.errors.last.issue, PidCsvIssue.rowEmptyEquation);
    });

    test('a defaulted range reports the bounds that were actually applied', () {
      // The warning exists because a substituted scale is invisible: a needle
      // reads as authoritative against whatever bounds it is drawn on, whoever
      // picked them. Which makes the two numbers the whole content of it —
      // `999`/`999` substituted at the construction is a warning about a scale
      // that was never applied, and the suite did not notice.
      const columns =
          'Name,ShortName,ModeAndPID,Equation,Min Value,Max Value,'
          'Units,Header\r\n';

      final bothBlank =
          PidCsv.parse('${columns}Trans,T,2211A6,A-40,,,C,7E0\r\n');
      expect(bothBlank.errors, isEmpty);
      expect(bothBlank.warnings.single.issue, PidCsvIssue.rowRangeDefaulted);
      expect(bothBlank.warnings.single.lineNumber, 2);
      expect(bothBlank.warnings.single.minValue, 0);
      expect(bothBlank.warnings.single.maxValue, 100);

      // A lower bound that parsed is kept, and the upper one is derived from
      // it — so the two fields are not interchangeable and a value taken from
      // the wrong one shows up here.
      final maxBlank =
          PidCsv.parse('${columns}Trans,T,2211A6,A-40,50,,C,7E0\r\n');
      expect(maxBlank.errors, isEmpty);
      expect(maxBlank.warnings.single.minValue, 50);
      expect(maxBlank.warnings.single.maxValue, 150);
    });

    test('an empty file reports why nothing was imported', () {
      expect(PidCsv.parse('').errors, isNotEmpty);
    });

    test('each way of importing nothing says which way it was', () {
      // condition -> identifier for the file-level arms. `isNotEmpty` above is
      // satisfied by any of them, and the reviewer transposed
      // `noRows` and `nothingImportable` at their two throw sites with the
      // whole suite still green: an empty file was then reported as "has rows
      // but none of them is a PID", which sends the reader looking through a
      // file that has nothing in it.
      expect(
        PidCsv.parse('').errors.single.issue,
        PidCsvIssue.noRows,
        reason: 'no rows at all is not the same as rows that yielded nothing',
      );

      // Rows were read — the header — and produced no definition.
      expect(
        PidCsv.parse('Name,ShortName,ModeAndPID,Equation\r\n')
            .errors
            .single
            .issue,
        PidCsvIssue.nothingImportable,
      );

      // A named header with a short data row is missing mapped values, not a
      // positional cell count. ModeAndPID is empty, so the row is invalid
      // rather than "too few columns".
      final shortNamed = PidCsv.parse(
        'Name,ShortName,ModeAndPID,Equation\r\nTrans,T\r\n',
      );
      expect(shortNamed.errors.single.issue, PidCsvIssue.rowInvalidModeAndPid);
      expect(shortNamed.errors.single.lineNumber, 2);

      // Headerless positional files still refuse a row shorter than four cells.
      final shortPositional = PidCsv.parse('Trans,T\r\n');
      expect(
        shortPositional.errors.single.issue,
        PidCsvIssue.rowTooFewColumns,
      );

      final threeColumn = PidCsv.parse(
        'Name,ModeAndPID,Equation\r\nCoolant,0105,A-40\r\n',
      );
      expect(threeColumn.errors, isEmpty, reason: 'named three-column Torque CSV');
      expect(threeColumn.pids, hasLength(1));
      expect(threeColumn.pids.single.modeAndPid, '0105');
      expect(threeColumn.pids.single.equation, 'A-40');

      // And the empty-cell case really is the other one, so the two are told
      // apart by input rather than by which happens to be checked first.
      final blankEquation = PidCsv.parse(
        'Name,ShortName,ModeAndPID,Equation\r\nTrans,T,2211A6,\r\n',
      );
      expect(blankEquation.errors.single.issue, PidCsvIssue.rowEmptyEquation);
    });

    test('malformedCsv is unreachable with the decoder this app ships', () {
      // Stated rather than left as a gap. `PidCsvIssue.malformedCsv` is the
      // arm for a `FormatException` out of `Csv().decode`, and `csv` 8.0.0
      // never throws one: its only `throw` is an assertion in the decoder's
      // constructor over the quote/escape characters, which this file does not
      // configure. Every shape that ought to be malformed comes back as rows.
      //
      // So the copy for it cannot be exercised through `PidCsv.parse`, and a
      // test claiming to drive it would be driving something else. What is
      // pinned instead is the reason: if a decoder upgrade starts throwing,
      // these expectations change and whoever changes them is looking straight
      // at the arm that becomes live.
      for (final malformed in const [
        '"unterminated',
        'a,"b\r\n',
        '"a"x,b\r\n',
      ]) {
        final result = PidCsv.parse(malformed);
        expect(
          result.errors.map((e) => e.issue),
          isNot(contains(PidCsvIssue.malformedCsv)),
          reason: 'csv 8.0.0 does not throw FormatException; if it now does, '
              'pin the malformedCsv arm here for real',
        );
      }
    });

    test('imported definitions are namespaced away from the built-ins', () {
      // A stock Torque file contains 010C. It must not take over the shipped
      // Engine RPM definition, which the physics engine depends on.
      const wire = 'My RPM,RPM,010C,A*2,0,8000,rpm,7E0\r\n';
      final imported = PidCsv.parse(wire).pids.single;
      const builtIn = Pid(
        name: 'Engine RPM',
        shortName: 'RPM',
        modeAndPid: '010C',
        equation: '((A*256)+B)/4',
        minValue: 0,
        maxValue: 8000,
        units: 'rpm',
      );
      expect(imported.id, isNot(builtIn.id));
    });
    test('a row refused by the DEFINITION rule names that rule and its value',
        () {
      // `rowDefinitionRejected` has two producers, and only one of them was
      // reachable from any test: the unsafe-service branch, which
      // safety_allowlist_test.dart covers. Its sibling — the branch fed by
      // `PidDefinition.rejectionReason` — had nothing standing on it, so
      // swapping its issue to `rowEmptyEquation` passed the whole suite while
      // a row rejected for a malformed header rendered
      // "Row 2: the formula cell is empty." Fluent, English, and wrong about
      // the file in front of the reader.
      //
      // The mode+PID here is deliberately VALID (`010C` is a read-only
      // current-data query), so the unsafe-service branch cannot fire and this
      // can only be reaching the definition branch. `7EG` is not hex.
      const wire =
          'Name,ShortName,ModeAndPID,Equation,Min Value,Max Value,Units,Header\r\n'
          'Engine RPM,RPM,010C,((A*256)+B)/4,0,8000,rpm,7EG\r\n';
      final result = PidCsv.parse(wire);

      expect(result.pids, isEmpty);
      final error = result.errors.single;
      expect(error.issue, PidCsvIssue.rowDefinitionRejected);
      expect(error.lineNumber, 2, reason: 'the data row, not the header row');

      // The nested reason, which nothing in the repository read before. The
      // sentence the importer shows quotes `text`, so an identifier without
      // its value renders `The CAN header "" is not…`.
      expect(error.rejection, isNotNull);
      expect(error.rejection!.issue, PidRejection.invalidHeader);
      expect(error.rejection!.text, '7EG');
    });

    test('the two producers of rowDefinitionRejected stay distinguishable', () {
      // Same issue code, different reasons. A change that routed the unsafe
      // service through the definition branch, or the reverse, would be
      // invisible to a test that only checked `issue`.
      const unsafe =
          'Name,ShortName,ModeAndPID,Equation,Min Value,Max Value,Units,Header\r\n'
          'Actuate,ACT,2F01,A,0,100,x,7E0\r\n';
      const malformed =
          'Name,ShortName,ModeAndPID,Equation,Min Value,Max Value,Units,Header\r\n'
          'Engine RPM,RPM,010C,((A*256)+B)/4,0,8000,rpm,7EG\r\n';

      expect(PidCsv.parse(unsafe).errors.single.rejection!.issue,
          PidRejection.serviceNotReadOnly);
      expect(PidCsv.parse(malformed).errors.single.rejection!.issue,
          PidRejection.invalidHeader);
    });

  });
}

/// A malformed import must fail the row rather than become a different,
/// perfectly valid request.
void _strictParsingTests() {
  group('malformed rows are rejected, not repaired', () {
    const columns =
        'Name,ShortName,ModeAndPID,Equation,Min Value,Max Value,'
        'Units,Header,Priority,Redline,Variant\r\n';

    PidCsvResult parseRow(String row) => PidCsv.parse('$columns$row\r\n');

    test(
      'a letter O typed for a zero fails instead of changing the request',
      () {
        // `22-11O1` had every non-hex character deleted, yielding a request the
        // author never wrote. The gauge then polled a different identifier and
        // displayed whatever came back.
        final result = parseRow('Trans,T,22-11O1,A,0,100,C,7E0');
        expect(result.pids, isEmpty);
        expect(result.errors, isNotEmpty);
      },
    );

    test('an odd number of hex digits fails', () {
      final result = parseRow('Odd,O,010C0,A,0,100,C,7E0');
      expect(result.pids, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('spaces between bytes are still accepted', () {
      final result = parseRow('Spaced,S,22 1E 1C,A,0,100,C,7E0');
      expect(result.errors, isEmpty);
      expect(result.pids.single.modeAndPid, '221E1C');
    });

    test('unparseable bounds fail instead of defaulting to 0 and 100', () {
      // Silently substituting 0/100 gave the gauge a scale nobody chose, and
      // the needle then read as authoritative against invented bounds.
      final result = parseRow('Bad,B,0105,A,foo,bar,C,7E0');
      expect(result.pids, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('an inverted range fails', () {
      final result = parseRow('Inv,I,0105,A,100,0,C,7E0');
      expect(result.pids, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('a header of an impossible width fails', () {
      final result = parseRow('Head,H,0105,A,0,100,C,7E01');
      expect(result.pids, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('the three legal header widths are accepted', () {
      for (final header in ['7E0', '6810F1', '18DA10F1']) {
        final result = parseRow('Head,H,0105,A,0,100,C,$header');
        expect(result.errors, isEmpty, reason: header);
        expect(result.pids.single.header, header);
      }
    });
  });

  group('the editor and the importer agree', () {
    test('one rule decides whether a definition is admissible', () {
      // These used to disagree: the importer refused a malformed header or an
      // inverted range, while the editor accepted both and substituted 0/100
      // for bounds it could not parse — a gauge given a scale nobody chose,
      // whose needle then reads as authoritative against it.
      expect(
        PidDefinition.rejectionReason(
          name: 'x',
          modeAndPid: '010C',
          header: '7EG',
          minText: '0',
          maxText: '100',
        )?.issue,
        PidRejection.invalidHeader,
      );
      expect(
        PidDefinition.rejectionReason(
          name: 'x',
          modeAndPid: '010C',
          header: '7E0',
          minText: '100',
          maxText: '10',
        )?.issue,
        PidRejection.maxNotAboveMin,
      );
      expect(
        PidDefinition.rejectionReason(
          name: 'x',
          modeAndPid: '010C',
          header: '7E0',
          minText: 'abc',
          maxText: '100',
        )?.issue,
        PidRejection.minNotANumber,
      );
    });

    test('a refusal quotes back what was actually typed', () {
      // The four arms that carry `text`. Before the identifier migration the
      // typed value was interpolated into the sentence at the return, so there
      // was one copy of it; now the screen reads `reason.text` and nothing
      // compared the two. Substituting `'ZZZ'` at all three of the sites
      // below left the whole suite green and told the reader that a header
      // they never typed was the invalid one.
      //
      // Distinct fixtures per arm on purpose: a value copied from the wrong
      // field would otherwise pass.
      final header = PidDefinition.rejectionReason(
        name: 'x',
        modeAndPid: '010C',
        header: '7EG',
        minText: '0',
        maxText: '100',
      );
      expect(header?.issue, PidRejection.invalidHeader);
      expect(header?.text, '7EG');

      final min = PidDefinition.rejectionReason(
        name: 'x',
        modeAndPid: '010C',
        header: '7E0',
        minText: 'lo',
        maxText: '100',
      );
      expect(min?.issue, PidRejection.minNotANumber);
      expect(min?.text, 'lo');

      final max = PidDefinition.rejectionReason(
        name: 'x',
        modeAndPid: '010C',
        header: '7E0',
        minText: '0',
        maxText: 'hi',
      );
      expect(max?.issue, PidRejection.maxNotANumber);
      expect(max?.text, 'hi');

      final redline = PidDefinition.rejectionReason(
        name: 'x',
        modeAndPid: '010C',
        header: '7E0',
        minText: '0',
        maxText: '100',
        redlineText: 'red',
      );
      expect(redline?.issue, PidRejection.redlineNotANumber);
      expect(redline?.text, 'red');
    });

    test('each way of being inadmissible names itself', () {
      // condition -> identifier for the arms nothing else in this suite
      // reaches. Each of these was transposable in silence: the reviewer
      // pointed `nameRequired` at `boundsRequired` (a blank name answered with
      // "Fill in both ends of the gauge range") and swapped
      // `minNotFinite`/`maxNotFinite` (the sentence pointing at the field that
      // is fine), and the whole suite stayed green both times.
      //
      // The fixtures differ in exactly one field from an admissible
      // definition, so nothing here can be satisfied by the wrong arm.
      PidRejectionReason? reason({
        String name = 'x',
        String modeAndPid = '010C',
        String header = '7E0',
        String minText = '0',
        String maxText = '100',
        String? redlineText,
        bool requireBounds = false,
      }) =>
          PidDefinition.rejectionReason(
            name: name,
            modeAndPid: modeAndPid,
            header: header,
            minText: minText,
            maxText: maxText,
            redlineText: redlineText,
            requireBounds: requireBounds,
          );

      // Whitespace only, not empty: the rule trims, and a name of spaces is
      // the shape a spreadsheet actually produces.
      expect(reason(name: '   ')?.issue, PidRejection.nameRequired);

      // Blank bounds, and only because this caller is the editor. The
      // importer's own answer for the same input is null, which the
      // blank-bounds test below pins — so this arm is about `requireBounds`
      // and cannot be reached by a name or a range problem.
      expect(
        reason(minText: '', maxText: '', requireBounds: true)?.issue,
        PidRejection.boundsRequired,
      );

      // `double.tryParse` accepts these, so they are *numbers* — the arm is
      // not `minNotANumber`, and the remedy is different: NaN pins the needle
      // at full scale and wedges `jsonEncode` on save.
      expect(reason(minText: 'NaN')?.issue, PidRejection.minNotFinite);
      expect(reason(maxText: 'Infinity')?.issue, PidRejection.maxNotFinite);
      // The transposable pair, from opposite sides: a lower bound of
      // -Infinity with a perfectly ordinary upper one, and the reverse.
      expect(reason(minText: '-Infinity')?.issue, PidRejection.minNotFinite);
      expect(reason(maxText: 'NaN')?.issue, PidRejection.maxNotFinite);

      expect(
        reason(redlineText: 'NaN')?.issue,
        PidRejection.redlineNotFinite,
      );
      // And the finite redline still passes, so the arm above is about the
      // value rather than about the field being present.
      expect(reason(redlineText: '90'), isNull);
    });

    test('the editor and the importer still agree on the blank-bounds rule',
        () {

      // Blank bounds are a spreadsheet's business and not the editor's, which
      // is the one place the two callers legitimately differ.
      expect(
        PidDefinition.rejectionReason(
          name: 'x',
          modeAndPid: '010C',
          header: '7E0',
          minText: '',
          maxText: '',
        ),
        isNull,
      );
      expect(
        PidDefinition.rejectionReason(
          name: 'x',
          modeAndPid: '010C',
          header: '7E0',
          minText: '',
          maxText: '',
          requireBounds: true,
        ),
        isNotNull,
      );

      // And a well-formed definition passes both ways.
      expect(
        PidDefinition.rejectionReason(
          name: 'x',
          modeAndPid: '010C',
          header: '7E0',
          minText: '0',
          maxText: '8000',
          requireBounds: true,
        ),
        isNull,
      );
    });
  });
}

void _reorderedColumns() {
  group('a header row means the names decide, not the positions', () {
    test('columns in a different order are read correctly', () {
      // Found by an independent audit of the importer. The header row was read
      // only to decide whether to skip it, and every field was then taken by
      // index — so a file with exactly the right column names in a different
      // order was misread without a word.
      //
      // The worst arrangement is not the one that fails. `Units` and `Header`
      // landing where `Min Value` and `Max Value` are expected produces a PID
      // that polls the wrong controller and renders against wrong bounds: two
      // numbers on a gauge that look exactly like the right ones.
      const csv =
          'Header,Name,Equation,ModeAndPID,Units,Max Value,Min Value\r\n'
          '7E1,Trans Temp,A-40,2211A6,°C,215,-40\r\n';
      final result = PidCsv.parse(csv);
      expect(result.errors, isEmpty);
      final pid = result.pids.single;
      expect(pid.name, 'Trans Temp');
      expect(pid.modeAndPid, '2211A6');
      expect(pid.equation, 'A-40');
      expect(
        pid.header,
        '7E1',
        reason:
            'the header decides which controller is asked; reading it '
            'from the wrong column asks a different module',
      );
      expect(pid.units, '°C');
      expect(pid.minValue, -40);
      expect(pid.maxValue, 215);
    });

    test('a header row missing a required column is refused, not guessed', () {
      const csv = 'Name,Units\r\nTrans Temp,°C\r\n';
      final result = PidCsv.parse(csv);
      expect(result.pids, isEmpty);
      expect(result.errors.single.issue, PidCsvIssue.missingRequiredColumns);
      // Spelled as a spreadsheet spells it. The importer compares column names
      // with case and spaces removed, and reporting `modeandpid` sends the
      // reader looking for a column that is not in their file under that name.
      //
      // Both lists, in full and in order — not `contains('ModeAndPID')`, which
      // the *required* list also satisfies. The two arguments are adjacent, the
      // same type and the same shape, so swapping them compiles and every
      // assertion that only looked for one name went on passing: the file has
      // `Name` and lacks the other two, and the sentence then told the reader
      // that `Name` was missing — the one column they did supply.
      expect(
        result.errors.single.columns,
        orderedEquals(const ['ModeAndPID', 'Equation']),
        reason: 'the missing list must name only what the file does not have',
      );
      expect(
        result.errors.single.requiredColumns,
        orderedEquals(const ['Name', 'ModeAndPID', 'Equation']),
        reason: 'the required list is the full set, whatever the file has',
      );
      expect(
        result.errors.single.columns,
        isNot(contains('Name')),
        reason: 'the file supplies Name; saying otherwise sends the reader to '
            'fix the one column that is already right',
      );
    });

    test(
      'a three-column Name/ModeAndPID/Equation header is not a cell-count miss',
      () {
        // `_required` is Name/ModeAndPID/Equation. The conventional spelling
        // already imports. Header detection used trim+lowercase *before*
        // `_key()`, so a spreadsheet that writes `Mode And PID` (the same
        // column, spaces kept) was classified as positional and then refused
        // by `row.length < 4` — a complete named contract reported as too
        // few cells. Name is not first, so `first.first == 'name'` cannot
        // rescue it.
        const spaced =
            'Mode And PID,Name,Equation\r\n0105,Coolant,A-40\r\n';
        final spacedResult = PidCsv.parse(spaced);
        expect(
          spacedResult.errors.map((e) => e.issue),
          isNot(contains(PidCsvIssue.rowTooFewColumns)),
          reason:
              'a named three-column file is missing no required mapped '
              'value; cell count is the positional rule',
        );
        expect(spacedResult.errors, isEmpty);
        expect(spacedResult.pids, hasLength(1));
        expect(spacedResult.pids.single.name, 'Coolant');
        expect(spacedResult.pids.single.modeAndPid, '0105');
        expect(spacedResult.pids.single.equation, 'A-40');

        const underscored =
            'mode_and_pid,name,equation\r\n0105,Coolant,A-40\r\n';
        final underscoredResult = PidCsv.parse(underscored);
        expect(underscoredResult.errors, isEmpty);
        expect(underscoredResult.pids.single.modeAndPid, '0105');

        // Headerless three cells are still too few for the positional layout.
        final positional = PidCsv.parse('Coolant,0105,A-40\r\n');
        expect(
          positional.errors.single.issue,
          PidCsvIssue.rowTooFewColumns,
        );
      },
    );

    test(
      'a positional row whose free-text cell _keys to modeandpid still imports',
      () {
        // `_key` strips spaces, so `Mode And PID` in ShortName is the same
        // token as the column name. Named mode needs a second `_required`
        // marker (`name` or `equation`) — a headerless eight-cell Torque row
        // has neither. Assert the imported fields, not only that the row
        // was not refused: a remap into a different PID would also be empty
        // errors.
        Pid assertPositional(String csv) {
          final result = PidCsv.parse(csv);
          expect(result.errors, isEmpty, reason: csv);
          expect(result.pids, hasLength(1), reason: csv);
          return result.pids.single;
        }

        final spaced = assertPositional(
          'Coolant,Mode And PID,0105,A-40,-40,215,C,7E0\r\n',
        );
        expect(spaced.name, 'Coolant');
        expect(spaced.shortName, 'Mode And PID');
        expect(spaced.modeAndPid, '0105');
        expect(spaced.equation, 'A-40');
        expect(spaced.minValue, -40);
        expect(spaced.maxValue, 215);
        expect(spaced.units, 'C');
        expect(spaced.header, '7E0');

        final underscored = assertPositional(
          'Coolant,mode_and_pid,0105,A-40,-40,215,C,7E0\r\n',
        );
        expect(underscored.name, 'Coolant');
        expect(underscored.shortName, 'mode_and_pid');
        expect(underscored.modeAndPid, '0105');
        expect(underscored.equation, 'A-40');
        expect(underscored.header, '7E0');

        final nameCell = assertPositional(
          'Mode And PID,Coolant,0105,A-40,-40,215,C,7E0\r\n',
        );
        expect(nameCell.name, 'Mode And PID');
        expect(nameCell.shortName, 'Coolant');
        expect(nameCell.modeAndPid, '0105');
        expect(nameCell.equation, 'A-40');
        expect(nameCell.header, '7E0');
      },
    );

    test(
      'an incomplete named header with ModeAndPID still refuses the file',
      () {
        // Codex P2 on the first follow-up: `ModeAndPID,Units,ShortName,
        // Min Value` is a header vocabulary, not a positional Name.
        // Parsing it by index would upsert a mis-mapped PID.
        final result = PidCsv.parse(
          'ModeAndPID,Units,ShortName,Min Value\r\n'
          '0105,C,Coolant,-40\r\n',
        );
        expect(result.pids, isEmpty);
        expect(result.errors, hasLength(1));
        expect(
          result.errors.single.issue,
          PidCsvIssue.missingRequiredColumns,
        );
        expect(
          result.errors.single.columns,
          containsAll(['Name', 'Equation']),
        );
      },
    );

    test('no header row still means positional, as it always did', () {
      const csv = 'Trans Temp,TTemp,2211A6,A-40,-40,215,°C,7E1\r\n';
      final result = PidCsv.parse(csv);
      expect(result.errors, isEmpty);
      final pid = result.pids.single;
      expect(pid.modeAndPid, '2211A6');
      expect(pid.header, '7E1');
      expect(pid.minValue, -40);
    });

    test('a duplicated column name is refused, not resolved by position', () {
      // Taking the first occurrence is a silent choice between two columns
      // that both claim to be the equation. Whichever is wrong produces a PID
      // that computes with the wrong formula — a number on a gauge that looks
      // exactly like the right one, from a file the author believed was fine.
      const csv =
          'Name,ModeAndPID,Equation,Equation\r\n'
          'Trans Temp,2211A6,A-40,A*100/255\r\n';
      final result = PidCsv.parse(csv);
      expect(result.pids, isEmpty);
      expect(result.errors.single.issue, PidCsvIssue.duplicateHeaderColumns);
      expect(result.errors.single.columns, contains('Equation'));
    });

    test(
      'and a duplicated Header, which decides which controller is asked',
      () {
        const csv =
            'Name,ModeAndPID,Equation,Header,Header\r\n'
            'Trans Temp,2211A6,A-40,7E0,7E1\r\n';
        expect(PidCsv.parse(csv).pids, isEmpty);
      },
    );

    test('spelling variants of a column name are the same column', () {
      const csv =
          'name,modeandpid,equation,minvalue,max value\r\n'
          'Trans Temp,2211A6,A-40,-40,215\r\n';
      final result = PidCsv.parse(csv);
      expect(result.errors, isEmpty);
      expect(result.pids.single.minValue, -40);
      expect(result.pids.single.maxValue, 215);
    });
  });
}

/// Files written for Torque Pro, which is where nearly all of these come from.
///
/// torque-bhp.com documents the columns as `Name`, `ShortName`, `ModeAndPID`,
/// `Equation`, `Min Value`, `Max Value`, `Units`, `OBD Header`. The first seven
/// are this app's names exactly; the eighth is not, and the mismatch was
/// silent — the file imported with no errors and every PID quietly addressed
/// to the default `7E0`.
///
/// That is the shape this file exists to prevent. A community set for a
/// transmission (`7E1`) or a body module (`7E2`) does not fail to import; it
/// imports and asks the *engine* the transmission's question. Best case, no
/// data. Worst case `7E0` answers something at that address and the gauge
/// shows a number that looks exactly like the right one.
void _torqueProCompatibility() {
  group('a file written for Torque Pro keeps its addressing', () {
    test('OBD Header is the same column as Header', () {
      // The documented column names, and the documented example row.
      const file =
          'Name,ShortName,ModeAndPID,Equation,Min Value,Max Value,Units,OBD Header\r\n'
          '"Transmission Temperature(Method 3)","Trans","0105","A-40",0,200,"C",""\r\n'
          '"Trans Temp","TT","221E1C","((A*256)+B)/8-40",-40,215,"C","7E1"\r\n';
      final result = PidCsv.parse(file);
      expect(result.errors, isEmpty);
      expect(result.pids, hasLength(2));

      expect(
        result.pids[1].header,
        '7E1',
        reason:
            'this PID is addressed to the transmission; sending it to '
            'the engine is how an imported set produces a plausible wrong '
            'number',
      );
      expect(result.pids[1].modeAndPid, '221E1C');
      expect(result.pids[1].equation, '((A*256)+B)/8-40');

      // The blank-header row is the documented "auto" case and must still fall
      // back rather than fail.
      expect(result.pids[0].header, isNotEmpty);
    });

    test('and the spelling this app exports still wins when both appear', () {
      // Not a real file, but the ambiguity has to resolve somewhere, and a
      // round trip through this app must not be degraded by an alias.
      const file =
          'Name,ModeAndPID,Equation,Header,OBD Header\r\n'
          '"X","0105","A",7E1,7E2\r\n';
      final result = PidCsv.parse(file);
      expect(result.errors, isEmpty);
      expect(result.pids.single.header, '7E1');
    });
  });
}

void _humanReportNotReimported() {
  group('human spreadsheet report', () {
    const pid = Pid(
      name: 'Coolant',
      shortName: 'ECT',
      modeAndPid: '0105',
      equation: 'A-40',
      minValue: -40,
      maxValue: 215,
      units: '°C',
      priority: PriorityTier.high,
    );

    test('is labeled separately from the machine file', () {
      final human = PidCsv.exportHumanReport([pid]);
      expect(human.contains('Telltale human report'), isTrue);
      expect(human.contains('Priority'), isFalse);
      expect(PidCsv.export([pid]).contains('Telltale human report'), isFalse);
    });

    test('cannot be silently reimported as unchanged formulas', () {
      final result = PidCsv.parse(PidCsv.exportHumanReport([pid]));
      expect(result.pids, isEmpty);
      expect(result.errors, isNotEmpty);
    });

    test('neutralizes spreadsheet formula cells', () {
      const injected = Pid(
        name: '=1+1',
        shortName: 'X',
        modeAndPid: '0105',
        equation: '+A',
        minValue: 0,
        maxValue: 1,
        units: '@C',
      );
      final human = PidCsv.exportHumanReport([injected]);
      expect(human.contains("'=1+1"), isTrue);
      expect(human.contains("'+A"), isTrue);
      expect(human.contains("'@C"), isTrue);
      expect(human.contains(',=1+1'), isFalse);
    });

    test(
      'streamed human report preserves exact bytes in bounded chunks',
      () async {
        const injected = Pid(
          name: '=1+1',
          shortName: 'X',
          modeAndPid: '0105',
          equation: '+A',
          minValue: 0,
          maxValue: 1,
          units: '@C',
        );
        final chunks = await PidCsv.streamHumanReport(
          [pid, injected],
          maxChunkBytes: 32,
        ).toList();
        expect(chunks.every((chunk) => chunk.length <= 32), isTrue);
        expect(
          chunks.expand((chunk) => chunk),
          utf8.encode(PidCsv.exportHumanReport([pid, injected])),
        );
        final streamed = utf8.decode(
          chunks.expand((chunk) => chunk).toList(),
        );
        expect(streamed.contains('Telltale human report'), isTrue);
        expect(streamed.contains("'=1+1"), isTrue);
        expect(PidCsv.parse(streamed).pids, isEmpty);
      },
    );
  });
}
