// What the custom-PID reason codes actually say, in both shipped languages.
//
// Every table below is written out by hand. Not read back from
// `AppLocalizations`, not read from the ARB, not produced by the function under
// test: the expected sentence is typed here, and the test compares the shipped
// one against it.
//
// That is the whole point, and it is not the obvious way to write this file.
// The obvious way is `expect(formulaIssueText(en, e), en.pidFormulaEmpty)`,
// which reads the same ARB entry the mapper reads and therefore agrees with
// itself — it would go on passing if the entry were replaced with the wrong
// sentence, and it passes today with any two arms of the switch transposed.
// Three sibling slices were blocked this week for exactly that defect, because
// the tests they shipped asserted uniqueness, non-emptiness, presence in both
// languages and no-Chinese-in-English, and a transposition preserves all four.
//
// So the tables are the assertion and the properties below are the safety net,
// not the other way round. Swapping two arms of any of the three switches turns
// this file red; that was run, not assumed.
//
// The interpolated values are fixed here (`0133`, byte `C`, row 7) so each
// sentence has exactly one correct rendering to type out.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/pid/formula_engine.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_csv.dart';
import 'package:torque_obd/state/pid_mutation_lock.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/ui/screens/pids/pid_formula_copy.dart';
import 'package:torque_obd/ui/screens/pids/pid_import_copy.dart';
import 'package:torque_obd/ui/screens/pids/pid_mutation_copy.dart';
import 'package:torque_obd/ui/screens/pids/pid_rejection_copy.dart';

import '../support/cjk.dart';

/// The exception each [FormulaIssue] is rendered from.
///
/// The message is empty on purpose: it is the engine's own diagnostic and no
/// screen may show it, so a copy function that quietly fell back to it would
/// render nothing and every expectation below would fail.
FormulaException _thrown(FormulaIssue issue) => FormulaException(
  '',
  'A*2',
  issue: issue,
  pidKey: '0133',
  byteLetter: 'C',
  byteCount: 2,
  argument: -3,
  term: 'A@B',
);

const _formulaEnglish = <FormulaIssue, String>{
  FormulaIssue.emptyFormula: 'The formula is empty.',
  FormulaIssue.emptySubExpression:
      'Part of the formula is empty — an operator with nothing after it, or '
      'brackets with nothing in them.',
  FormulaIssue.unbalancedParentheses:
      'The brackets do not match: every ( needs a closing ).',
  FormulaIssue.unparsableTerm:
      '“A@B” is not a number, an operator, or a name this editor understands.',
  FormulaIssue.functionNestingTooDeep:
      'ABS(), LOG10(), LOG() and SQRT() are nested too deeply to evaluate. Simplify the '
      'formula.',
  FormulaIssue.parenthesisNestingTooDeep:
      'The brackets are nested too deeply to evaluate. Simplify the formula.',
  FormulaIssue.divisionByZero: 'The formula divides by zero.',
  FormulaIssue.moduloByZero: 'The formula takes a remainder modulo zero.',
  FormulaIssue.log10NonPositiveArgument:
      'LOG10 needs an argument greater than 0, and this one came out as -3.0.',
  FormulaIssue.logNonPositiveArgument:
      'LOG needs an argument greater than 0, and this one came out as -3.0.',
  FormulaIssue.sqrtNegativeArgument:
      'SQRT needs an argument of 0 or greater, and this one came out as -3.0.',
  FormulaIssue.resultNotFinite:
      'The arithmetic produced no usable number, so there is no reading to '
      'show.',
  FormulaIssue.byteBeyondResponse:
      'The formula refers to byte C, but the reply carried only 2 bytes.',
  FormulaIssue.baroControllerUnknown:
      'BARO cannot be used here, because which controller’s ambient pressure '
      'is meant is not known.',
  FormulaIssue.baroTwoDefinitions:
      'Two definitions both supply ambient pressure, so the value could be '
      'either one and neither can be used. Remove one of the gauges that '
      'measures ambient pressure.',
  FormulaIssue.baroNotYetMeasured:
      'Ambient pressure has not been read yet, so this cannot be calculated.',
  FormulaIssue.baroMeasurementStale:
      'The ambient pressure reading is out of date, so this cannot be '
      'calculated.',
  FormulaIssue.baroParenFormUnsupported:
      'BARO() is the Android barometer / ECU baro in psi, which this dialect '
      'does not implement. Use BARO without parentheses for cached ambient '
      'pressure.',
  FormulaIssue.int16Unclaimed:
      'INT16 is unclaimed: the wiki says it can replace (A*255)+B, which is '
      'not (A*256)+B. Write one of those identities explicitly.',
  FormulaIssue.timeWindowUnsupported:
      'A@B is a delay, average, or totalizer Torque function this dialect '
      'does not implement, so it cannot be evaluated here. It is not 0 and '
      'not MIN or MAX.',
  FormulaIssue.dependencyControllerUnknown:
      'VAL{0133} cannot be resolved here, because which controller that PID '
      'belongs to is not known.',
  FormulaIssue.dependencyTwoDefinitions:
      'Two definitions both decode 0133, so the value could be either one and '
      'neither can be used. Change one of them to a different mode+PID. Note: '
      'the PIDs the estimates need (010B, 010C, 010D) are always read, so '
      'taking a gauge off the dashboard does not stop them.',
  FormulaIssue.dependencyNotYetMeasured:
      'No usable value has been read for 0133 yet.',
  FormulaIssue.unsupportedConstruct:
      'A@B is a Torque function this dialect does not implement, so the '
      'formula cannot be evaluated here.',
};

const _formulaChinese = <FormulaIssue, String>{
  FormulaIssue.emptyFormula: '公式是空的。',
  FormulaIssue.emptySubExpression: '公式有一段是空的 —— 運算子後面沒有東西，或括號裡沒有內容。',
  FormulaIssue.unbalancedParentheses: '括號沒有配對：每一個 ( 都需要一個對應的 )。',
  FormulaIssue.unparsableTerm: '「A@B」不是數值、運算子，也不是這個編輯器認得的名稱。',
  FormulaIssue.functionNestingTooDeep:
      'ABS()、LOG10()、LOG() 與 SQRT() 巢狀太深，無法求值。請簡化公式。',
  FormulaIssue.parenthesisNestingTooDeep: '括號巢狀太深，無法求值。請簡化公式。',
  FormulaIssue.divisionByZero: '公式除以零。',
  FormulaIssue.moduloByZero: '公式對零取餘數。',
  FormulaIssue.log10NonPositiveArgument: 'LOG10 的引數必須大於 0，這裡算出來的是 -3.0。',
  FormulaIssue.logNonPositiveArgument: 'LOG 的引數必須大於 0，這裡算出來的是 -3.0。',
  FormulaIssue.sqrtNegativeArgument: 'SQRT 的引數必須大於或等於 0，這裡算出來的是 -3.0。',
  FormulaIssue.resultNotFinite: '這串運算沒有得出可用的數值，因此沒有讀數可顯示。',
  FormulaIssue.byteBeyondResponse: '公式參照位元組 C，但回應只有 2 個位元組。',
  FormulaIssue.baroControllerUnknown: '這裡無法使用 BARO，因為無法判斷指的是哪一個控制器的大氣壓力。',
  FormulaIssue.baroTwoDefinitions:
      '有兩個定義同時提供大氣壓力，數值可能是其中任何一個，因此無法採用。請移除其中一個測量大氣壓力的錶。',
  FormulaIssue.baroNotYetMeasured: '尚未取得大氣壓力量測值，無法計算。',
  FormulaIssue.baroMeasurementStale: '大氣壓力量測值已過期，無法計算。',
  FormulaIssue.baroParenFormUnsupported:
      'BARO() 是 Android 氣壓計／ECU 大氣壓（psi），這個方言沒有實作。要用快取的大氣壓力請寫不帶括號的 BARO。',
  FormulaIssue.int16Unclaimed:
      'INT16 尚未被這個方言認領：wiki 寫可代替 (A*255)+B，那不是 (A*256)+B。請把其中一個等式直接寫進公式。',
  FormulaIssue.timeWindowUnsupported:
      'A@B 是這個方言尚未實作的延遲、平均或 totalizer Torque 函式，因此無法在這裡求值。它不是 0，也不是 MIN 或 MAX。',
  FormulaIssue.dependencyControllerUnknown:
      '這裡無法解析 VAL{0133}，因為無法判斷那個 PID 屬於哪一個控制器。',
  FormulaIssue.dependencyTwoDefinitions:
      '有兩個定義同時解讀 0133，數值可能是其中任何一個，因此無法採用。請讓其中一個改用不同的模式+PID。'
      '注意：推算數值需要的 PID（010B、010C、010D）本 App 一定會讀取，把面板上的錶移掉不會停止讀取它們。',
  FormulaIssue.dependencyNotYetMeasured: '尚未取得相依 PID 0133 的有效數值。',
  FormulaIssue.unsupportedConstruct: 'A@B 是這個方言尚未實作的 Torque 函式，因此無法在這裡求值。',
};

/// The [PidRejectionReason] each [PidRejection] is rendered from.
PidRejectionReason _refused(PidRejection issue) => PidRejectionReason(
  issue,
  text: '7EG',
  service: '2F',
  expectedBytes: 1,
  allowedServices: const ['01', '02', '09', '22'],
);

const _rejectionEnglish = <PidRejection, String>{
  PidRejection.malformedModeAndPid:
      'Not a valid mode+PID: hexadecimal characters only, in whole byte pairs.',
  PidRejection.serviceNotReadOnly:
      'Service 2F is not a read-only query and must not be sent to the vehicle '
      'over and over. Only 01, 02, 09, 22 are allowed — current data, freeze '
      'frame, vehicle information and ReadDataByIdentifier.',
  PidRejection.freezeFrameNeedsFrame:
      'A freeze-frame query needs two bytes, the PID and the frame number — '
      'for example 020500 (PID 05, frame 0).',
  PidRejection.identifierNeedsTwoBytes:
      'ReadDataByIdentifier needs a two-byte identifier — for example 221101.',
  PidRejection.identifierWrongLength:
      'A service 2F query needs a 1-byte identifier.',
  PidRejection.nameRequired: 'Enter a name.',
  PidRejection.invalidHeader:
      '“7EG” is not a valid header: 3 digits for 11-bit CAN, 6 for the legacy '
      'protocols, 8 for 29-bit CAN.',
  PidRejection.boundsRequired: 'Fill in both ends of the gauge range.',
  PidRejection.minNotANumber: 'The lower bound “7EG” is not a valid number.',
  PidRejection.maxNotANumber: 'The upper bound “7EG” is not a valid number.',
  PidRejection.minNotFinite: 'The lower bound has to be a finite number.',
  PidRejection.maxNotFinite: 'The upper bound has to be a finite number.',
  PidRejection.redlineNotANumber:
      'The redline start “7EG” is not a valid number.',
  PidRejection.redlineNotFinite: 'The redline start has to be a finite number.',
  PidRejection.maxNotAboveMin:
      'The upper bound has to be greater than the lower bound.',
};

const _rejectionChinese = <PidRejection, String>{
  PidRejection.malformedModeAndPid: '不是有效的模式+PID（只接受十六進位字元，且位元組須成對）。',
  PidRejection.serviceNotReadOnly:
      '服務 2F 不是唯讀查詢，不能週期性發送到車上。'
      '只允許 01、02、09、22（現值、凍結幀、車輛資訊、ReadDataByIdentifier）。',
  PidRejection.freezeFrameNeedsFrame:
      '凍結幀查詢需要 PID 與幀編號兩個位元組，例如 020500（PID 05、第 0 幀）。',
  PidRejection.identifierNeedsTwoBytes:
      'ReadDataByIdentifier 需要兩個位元組的識別碼，例如 221101。',
  PidRejection.identifierWrongLength: '服務 2F 的查詢需要 1 個位元組的識別碼。',
  PidRejection.nameRequired: '請輸入名稱。',
  PidRejection.invalidHeader:
      '「7EG」不是有效的標頭（11-bit CAN 為 3 碼、舊協定為 6 碼、29-bit CAN 為 8 碼）。',
  PidRejection.boundsRequired: '請填寫量程的上下限。',
  PidRejection.minNotANumber: '量程下限「7EG」不是有效的數值。',
  PidRejection.maxNotANumber: '量程上限「7EG」不是有效的數值。',
  PidRejection.minNotFinite: '量程下限必須是有限的數值。',
  PidRejection.maxNotFinite: '量程上限必須是有限的數值。',
  PidRejection.redlineNotANumber: '紅線起點「7EG」不是有效的數值。',
  PidRejection.redlineNotFinite: '紅線起點必須是有限的數值。',
  PidRejection.maxNotAboveMin: '量程上限必須大於下限。',
};

/// The diagnostic each [PidCsvIssue] is rendered from.
///
/// The nested rejection is [PidRejection.nameRequired] because it is the one
/// arm with no interpolation of its own, so the row sentence has exactly one
/// correct rendering.
PidCsvDiagnostic _reported(PidCsvIssue issue) => PidCsvDiagnostic(
  issue,
  lineNumber: 7,
  text: '22-11O1',
  columns: const ['Equation', 'Header'],
  requiredColumns: const ['Name', 'ModeAndPID', 'Equation'],
  rejection: const PidRejectionReason(PidRejection.nameRequired),
  minValue: 0,
  maxValue: 100,
  preflight: _thrown(FormulaIssue.unsupportedConstruct),
);

const _importEnglish = <PidCsvIssue, String>{
  PidCsvIssue.malformedCsv: 'This file could not be read as CSV: 22-11O1',
  PidCsvIssue.noRows: 'The file has no rows in it.',
  PidCsvIssue.duplicateHeaderColumns:
      'The header row names the same column twice: Equation, Header. There is '
      'no way to tell which one to use, so fix the file first.',
  PidCsvIssue.missingRequiredColumns:
      'The header row is missing required columns: Equation, Header. Name, '
      'ModeAndPID, Equation are all needed.',
  PidCsvIssue.rowTooFewColumns:
      'Row 7: not enough cells — name, short name, PID and formula are the '
      'minimum.',
  PidCsvIssue.rowInvalidModeAndPid:
      'Row 7: “22-11O1” is not a valid mode+PID (hexadecimal characters only, '
      'in whole byte pairs).',
  PidCsvIssue.rowEmptyEquation: 'Row 7: the formula cell is empty.',
  PidCsvIssue.rowDefinitionRejected: 'Row 7: Enter a name.',
  PidCsvIssue.rowRangeDefaulted:
      'Row 7: the gauge range was blank, so 0.0–100.0 was applied. Check that '
      'this scale suits this sensor.',
  PidCsvIssue.nothingImportable:
      'The file has rows in it, but none of them is a PID definition.',
  PidCsvIssue.rowFormulaRejected:
      'Row 7: A@B is a Torque function this dialect does not implement, so '
      'the formula cannot be evaluated here.',
};

const _importChinese = <PidCsvIssue, String>{
  PidCsvIssue.malformedCsv: '這個檔案無法以 CSV 讀取：22-11O1',
  PidCsvIssue.noRows: '檔案沒有任何資料列。',
  PidCsvIssue.duplicateHeaderColumns:
      '標題列有重複的欄位名稱：Equation、Header。無法判斷該用哪一欄，請先修正檔案。',
  PidCsvIssue.missingRequiredColumns:
      '標題列缺少必要欄位：Equation、Header。Name、ModeAndPID、Equation 都是必要的。',
  PidCsvIssue.rowTooFewColumns: '第 7 行：欄位不足，至少需要名稱、簡稱、PID、公式。',
  PidCsvIssue.rowInvalidModeAndPid:
      '第 7 行：「22-11O1」不是有效的模式+PID（只接受十六進位字元，且位元組須成對）。',
  PidCsvIssue.rowEmptyEquation: '第 7 行：公式為空。',
  PidCsvIssue.rowDefinitionRejected: '第 7 行：請輸入名稱。',
  PidCsvIssue.rowRangeDefaulted: '第 7 行：量程留空，已套用預設 0.0–100.0。請確認這個刻度適合這個感測器。',
  PidCsvIssue.nothingImportable: '檔案裡有資料列，但沒有任何一列是 PID 定義。',
  PidCsvIssue.rowFormulaRejected: '第 7 行：A@B 是這個方言尚未實作的 Torque 函式，因此無法在這裡求值。',
};

void main() {
  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  /// One table checked against one renderer, in one language.
  void handTyped<T>(
    String what,
    String language,
    AppLocalizations l10n,
    List<T> values,
    Map<T, String> expected,
    String Function(AppLocalizations, T) render,
  ) {
    test('$what says what it is supposed to say in $language', () {
      // Not `containsAll`: a value missing from the table is a value nobody
      // typed a sentence for, and the whole file is worth what this line is.
      expect(
        expected.keys.toSet(),
        values.toSet(),
        reason:
            'the hand-typed $language table for $what is out of step with '
            'the enum; a new value needs a sentence typed for it here',
      );
      for (final value in values) {
        expect(render(l10n, value), expected[value], reason: '$value');
      }
    });
  }

  String formula(AppLocalizations l10n, FormulaIssue issue) =>
      formulaIssueText(l10n, _thrown(issue))!;
  String rejection(AppLocalizations l10n, PidRejection issue) =>
      pidRejectionText(l10n, _refused(issue));
  String import(AppLocalizations l10n, PidCsvIssue issue) =>
      pidCsvDiagnosticText(l10n, _reported(issue));

  handTyped(
    'formula copy',
    'English',
    en,
    FormulaIssue.values,
    _formulaEnglish,
    formula,
  );
  handTyped(
    'formula copy',
    'Traditional Chinese',
    zh,
    FormulaIssue.values,
    _formulaChinese,
    formula,
  );
  handTyped(
    'rejection copy',
    'English',
    en,
    PidRejection.values,
    _rejectionEnglish,
    rejection,
  );
  handTyped(
    'rejection copy',
    'Traditional Chinese',
    zh,
    PidRejection.values,
    _rejectionChinese,
    rejection,
  );
  handTyped(
    'import copy',
    'English',
    en,
    PidCsvIssue.values,
    _importEnglish,
    import,
  );
  handTyped(
    'import copy',
    'Traditional Chinese',
    zh,
    PidCsvIssue.values,
    _importChinese,
    import,
  );

  test('TOT copy names a totalizer, not only delay or average', () {
    final text = formulaIssueText(
      en,
      const FormulaException(
        '',
        'TOT(A)',
        issue: FormulaIssue.timeWindowUnsupported,
        term: 'TOT',
      ),
    )!;
    expect(text, contains('TOT'));
    expect(text, contains('totalizer'));
    expect(text, isNot(contains('delay or average Torque')));
  });

  test('a null identifier renders nothing rather than the engine sentence', () {
    // The editor maps a null identifier to `pidFormulaUnidentified`, not
    // `e.message`. What this pins is the shape: the copy function answers
    // null rather than quietly handing back Chinese itself.
    expect(
      formulaIssueText(
        en,
        const FormulaException('運算結果不是有效數值', 'A', issue: null),
      ),
      isNull,
    );
  });

  group('properties the tables above do not already cover', () {
    test('no English sentence carries a Chinese character or mark', () {
      for (final text in [
        ...FormulaIssue.values.map((i) => formula(en, i)),
        ...PidRejection.values.map((i) => rejection(en, i)),
        ...PidCsvIssue.values.map((i) => import(en, i)),
      ]) {
        expect(
          chinese.hasMatch(text),
          isFalse,
          reason:
              'left behind while the words around it were translated: '
              '${chineseIn(text)} in $text',
        );
      }
    });

    test('the list joins follow the language, not the source file', () {
      // The defect this repo has already shipped once: every word translated
      // and the separator left as an ideographic comma, so an English reader
      // got `01、02、09、22`.
      expect(
        rejection(en, PidRejection.serviceNotReadOnly),
        contains('01, 02'),
      );
      expect(rejection(zh, PidRejection.serviceNotReadOnly), contains('01、02'));
    });

    test('no two reasons in one table render the same sentence', () {
      // Distinctness is not what the hand-typed tables prove — two identical
      // expectations would satisfy them — and a reason that cannot be told
      // from its neighbour is a state the app claims to distinguish and does
      // not.
      for (final (name, l10n) in [('en', en), ('zh-Hant', zh)]) {
        for (final texts in [
          FormulaIssue.values.map((i) => formula(l10n, i)).toList(),
          PidRejection.values.map((i) => rejection(l10n, i)).toList(),
          PidCsvIssue.values.map((i) => import(l10n, i)).toList(),
        ]) {
          expect(texts.toSet(), hasLength(texts.length), reason: name);
        }
      }
    });

    test('the two languages differ for every reason', () {
      // Catches a key added to app_en.arb and copied verbatim into the Chinese
      // ones, which passes every other check here.
      for (final issue in FormulaIssue.values) {
        expect(formula(en, issue), isNot(formula(zh, issue)), reason: '$issue');
      }
      for (final issue in PidRejection.values) {
        expect(
          rejection(en, issue),
          isNot(rejection(zh, issue)),
          reason: '$issue',
        );
      }
      for (final issue in PidCsvIssue.values) {
        expect(import(en, issue), isNot(import(zh, issue)), reason: '$issue');
      }
    });
  });

  test('import outcome snack is handwritten in both languages', () {
    const clean = PidImportOutcome(
      inserted: 3,
      replaced: 0,
      duplicatesInFile: [],
    );
    expect(pidImportOutcomeText(en, clean), 'Imported 3 custom PIDs.');
    expect(pidImportOutcomeText(zh, clean), '已匯入 3 項自訂 PID。');
    const one = PidImportOutcome(
      inserted: 1,
      replaced: 0,
      duplicatesInFile: [],
    );
    expect(pidImportOutcomeText(en, one), 'Imported 1 custom PID.');
    expect(pidImportOutcomeText(zh, one), '已匯入 1 項自訂 PID。');

    const replacing = PidImportOutcome(
      inserted: 1,
      replaced: 2,
      duplicatesInFile: [],
    );
    expect(
      pidImportOutcomeText(en, replacing),
      'Imported 3 items, 2 items replaced existing definitions.',
    );
    expect(pidImportOutcomeText(zh, replacing), '匯入 3 項，2 項覆蓋了現有定義。');

    const duped = PidImportOutcome(
      inserted: 1,
      replaced: 0,
      duplicatesInFile: ['RPM raw'],
    );
    expect(
      pidImportOutcomeText(en, duped),
      'Imported 1 item, 1 row duplicated another row in the file and was skipped.',
    );
    expect(pidImportOutcomeText(zh, duped), '匯入 1 項，1 行與檔案內其他行重複已略過。');

    const messy = PidImportOutcome(
      inserted: 1,
      replaced: 1,
      duplicatesInFile: ['a', 'b'],
    );
    expect(
      pidImportOutcomeText(en, messy, skippedRows: 4, defaultedRanges: 2),
      'Imported 2 items, 4 rows had problems and were skipped, '
      '2 rows used the default gauge range, '
      '1 item replaced an existing definition, '
      '2 rows duplicated another row in the file and were skipped.',
    );
    expect(
      pidImportOutcomeText(zh, messy, skippedRows: 4, defaultedRanges: 2),
      '匯入 2 項，4 行有問題已略過、2 行套用了預設量程、1 項覆蓋了現有定義、2 行與檔案內其他行重複已略過。',
    );

    const locked = PidImportOutcome(
      inserted: 0,
      replaced: 0,
      duplicatesInFile: [],
      failure: PidMutationFailure.locked,
    );
    expect(
      pidImportOutcomeText(en, locked),
      'Stop and save the recording first',
    );
    expect(pidImportOutcomeText(zh, locked), '請先停止並儲存');

    const persistFailed = PidImportOutcome(
      inserted: 0,
      replaced: 0,
      duplicatesInFile: [],
      failure: PidMutationFailure.persistFailed,
    );
    expect(
      pidImportOutcomeText(en, persistFailed),
      'The custom PID list could not be saved. Nothing was changed.',
    );
    expect(pidImportOutcomeText(zh, persistFailed), '自訂 PID 清單無法寫入。沒有任何變更。');
  });

  test('mutation failure copy is handwritten in both languages', () {
    expect(
      pidMutationFailureText(en, PidMutationFailure.locked),
      'Stop and save the recording first',
    );
    expect(pidMutationFailureText(zh, PidMutationFailure.locked), '請先停止並儲存');
    expect(
      pidMutationFailureText(en, PidMutationFailure.persistFailed),
      'The custom PID list could not be saved. Nothing was changed.',
    );
    expect(
      pidMutationFailureText(zh, PidMutationFailure.persistFailed),
      '自訂 PID 清單無法寫入。沒有任何變更。',
    );
    for (final failure in PidMutationFailure.values) {
      expect(
        pidMutationFailureText(en, failure),
        isNot(pidMutationFailureText(zh, failure)),
        reason: '$failure',
      );
    }
  });
}
