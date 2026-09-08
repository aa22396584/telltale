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

  test('the battery catalog does not snack PowertrainProfileInstallException.message',
      () {
    final code = _code('lib/ui/screens/pids/powertrain_battery_catalog_screen.dart');
    expect(code.contains('error.message'), isFalse);
  });

  test('the Wi-Fi binder does not interpolate PlatformException.message', () {
    final code = _code('lib/core/network/android_wifi_route_binder.dart');
    expect(code.contains('\${e.message}'), isFalse);
  });

  test('the Wi-Fi transport does not wrap the binder sentence in another interpolation',
      () {
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
}
