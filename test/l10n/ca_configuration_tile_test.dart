/// Holds the Canada picker tile to the official NRCan fuel letter.
///
/// Rows that share class, displacement and transmission are distinguished
/// only by `fuelType`. The letter is catalog data, not a new ARB string.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Canada configuration tiles include the official fuel letter', () {
    final source = File(
      'lib/ui/screens/settings/settings_screen.dart',
    ).readAsStringSync();
    expect(source.contains('ca_config_'), isTrue);
    expect(source.contains('if (item.fuelType.trim().isNotEmpty)'), isTrue);
    expect(
      source.contains('item.fuelType.trim()'),
      isTrue,
    );
  });
}
