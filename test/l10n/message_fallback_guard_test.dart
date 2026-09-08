// Source census for the four #45 interpolation sites that were still baking
// `error.message` into screen state after UnaddressableRequestException got a
// typed reason.
//
// A substring in a comment is not a throw. The shared reader blanks comments
// and strings so a doc quoting the old `?? e.message` cannot keep this green
// after the call site returns.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/dart_source_reader.dart';

String _code(String path) => codeOnly(File(path).readAsStringSync());

void main() {
  test('the PID editor does not fall back to FormulaException.message', () {
    final code = _code('lib/ui/screens/pids/pid_editor_screen.dart');
    expect(code.contains('?? e.message'), isFalse);
    expect(code.contains(r"error: '$e'"), isFalse);
    expect(code.contains(r'error: "$e"'), isFalse);
  });

  test('the battery catalog does not snack PowertrainProfileInstallException.message', () {
    final code = _code(
      'lib/ui/screens/pids/powertrain_battery_catalog_screen.dart',
    );
    expect(code.contains('error.message'), isFalse);
  });

  test('the Wi-Fi binder does not interpolate PlatformException.message', () {
    final code = _code('lib/core/network/android_wifi_route_binder.dart');
    expect(code.contains('\${e.message}'), isFalse);
  });

  test('the Wi-Fi transport does not wrap the binder sentence in another interpolation', () {
    final code = _code('lib/obd/transport/wifi_transport.dart');
    expect(code.contains('\${e.message}'), isFalse);
  });

  test('dtc_scan does not copy DtcReadException.message onto screen state', () {
    final code = _code('lib/state/dtc_scan.dart');
    expect(code.contains('message = e.message'), isFalse);
    expect(code.contains(r"DtcReadException('$e')"), isFalse);
    expect(code.contains(r'DtcReadException("$e")'), isFalse);
    expect(code.contains(r'（$e）'), isFalse);
    expect(code.contains("'scan failed'"), isFalse);
    expect(code.contains('transcript?.recordNote'), isTrue);
    expect(code.contains('session.client?.transcript.recordNote'), isFalse);
  });

  test('the category panel does not interpolate DtcReadException.message', () {
    final code = _code('lib/ui/screens/dtc/dtc_screen.dart');
    expect(code.contains('failure.message'), isFalse);
  });

  test('the paired-list path does not interpolate the caught exception', () {
    final code = _code('lib/ui/screens/connect/connect_screen.dart');
    expect(code.contains(r"_scanError = '$e'"), isFalse);
    expect(code.contains(r'_scanError = "$e"'), isFalse);
  });

  test('classic tier notes do not interpolate plugin error.message', () {
    final code = _code('lib/obd/transport/classic_transport.dart');
    expect(code.contains('error.message'), isFalse);
  });

  test(
    'clear disconnect copy does not interpolate TransportException.message',
    () {
      final code = _code('lib/obd/polling_engine.dart');
      expect(
        code.contains(r'e is TransportException ? e.message : e'),
        isFalse,
      );
      expect(
        code.contains('negativeResponseCode: e.negativeResponseCode'),
        isTrue,
      );
      expect(
        code.contains('silentSources: Set.unmodifiable(e.silentSources)'),
        isTrue,
      );
      expect(code.contains('decodeFailure ??= e.message'), isFalse);
      expect(code.contains('issueDetail: source'), isFalse);
      expect(code.contains('issueDetail: frame.sourceId'), isTrue);
    },
  );

  test('NRC clear copy selects a repeat-safety variant', () {
    final code = _code('lib/ui/screens/dtc/dtc_copy.dart');
    expect(code.contains('dtcClearNrcConditionsDoNotRepeat'), isTrue);
    expect(code.contains('failure.repeatWouldHarm'), isTrue);
  });

  test('polling-engine status interpolations carry structured counts', () {
    final code = _code('lib/obd/polling_engine.dart');
    expect(
      code.contains('unresolvedSources: Set.unmodifiable(unresolved)'),
      isTrue,
    );
    expect(
      code.contains(
        'unresolvedSources: Set.unmodifiable(openIdentityQuestions)',
      ),
      isTrue,
    );
    expect(
      code.contains('unresolvedSources: Set.unmodifiable(e.unresolvedSources)'),
      isTrue,
    );
    expect(code.contains('refusedCount: refused'), isTrue);
    expect(code.contains('answeredCount: answered'), isTrue);
    expect(code.contains('unrecognisedCount: unrecognised'), isTrue);
    expect(code.contains('refusedCount: e.refusedCount'), isTrue);
  });

  test('category copy maps structured counts before kind fallback', () {
    final code = _code('lib/ui/screens/dtc/dtc_copy.dart');
    expect(code.contains('dtcCategorySilentControllers'), isTrue);
    expect(code.contains('dtcCategoryUnresolvedSources'), isTrue);
    expect(code.contains('dtcCategoryRefusedControllers'), isTrue);
    expect(code.contains('dtcCategoryPendingControllers'), isTrue);
    expect(code.contains('dtcCategoryUnrecognisedResponses'), isTrue);
    expect(code.contains('dtcClearUnresolvedSourcesDoNotRepeat'), isTrue);
    expect(code.contains('failure.message'), isFalse);
  });

  test('the BLE scan panel does not interpolate userFacingScanFailure', () {
    final code = _code('lib/ui/screens/connect/connect_screen.dart');
    expect(code.contains('userFacingScanFailure'), isFalse);
    expect(code.contains(r'BLE 搜尋失敗：$error'), isFalse);
    expect(
      'FlutterError.reportError'.allMatches(code).length,
      greaterThanOrEqualTo(3),
      reason: 'paired list plus both BLE scan failure paths',
    );
    expect(code.contains('error.cause'), isTrue);
    expect(code.contains('_bleScanFlutterError'), isTrue);
  });

  test('BLE startScan failures keep the originating stack', () {
    final code = _code('lib/obd/transport/ble_transport.dart');
    expect(code.contains('on Object catch (e, stack)'), isTrue);
    expect(code.contains('on Object catch (e)'), isFalse);
  });

  test(
    'PID import picker/read copy does not interpolate the caught exception',
    () {
      // Raw source: codeOnly blanks string literals, so `'$e'` would disappear.
      final source = File('lib/ui/screens/pids/pid_manager_screen.dart')
          .readAsStringSync();
      expect(source.contains(r"pidImportPickerFailed('$e')"), isFalse);
      expect(source.contains(r'pidImportPickerFailed("$e")'), isFalse);
      expect(source.contains(r"pidImportReadFailed('$e')"), isFalse);
      expect(source.contains(r'pidImportReadFailed("$e")'), isFalse);
      expect(
        'FlutterError.reportError'.allMatches(source).length,
        greaterThanOrEqualTo(2),
      );
    },
  );
}
