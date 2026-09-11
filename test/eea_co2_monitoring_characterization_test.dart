import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String characterization;
  late String sources;
  late List<String> catalogFiles;

  setUpAll(() {
    characterization =
        File('docs/catalog/eea-2019-631-characterization.md').readAsStringSync();
    sources = File('docs/vehicle-data-sources.md').readAsStringSync();
    catalogFiles = Directory('assets/vehicle_catalog')
        .listSync()
        .map((entity) => entity.uri.pathSegments.last)
        .toList();
  });

  test('Stage C pins the 2025 provisional monitoring table', () {
    expect(characterization, contains('co2cars_2025Pv31'));
    expect(characterization, contains('10.2909/b4044b06-2e6b-4f8e-a6e6-66e0e98bb0dd'));
    expect(characterization, contains('10833597'));
    expect(
      characterization,
      contains('aa9caf445886466cec99e56da80316c92c0ff19bf23b0a98480f7ba61f2112b3'),
    );
    expect(characterization, contains('CC BY 4.0'));
    expect(characterization, contains('Do not bundle'));
  });

  test('the monitoring table is recorded as having no VIN column', () {
    expect(characterization, contains('has no `VIN` column'));
    expect(characterization, contains('VFN'));
    expect(
      characterization,
      contains('Article 12'),
      reason: 'the VIN-bearing product must stay named so it is not fetched',
    );
  });

  test('mass and power keep their source names', () {
    expect(characterization, contains('mass in running order'));
    expect(characterization, contains('WLTP test mass'));
    expect(characterization, contains('engine power in kilowatts'));
    expect(
      characterization,
      contains('None of those is curb mass or wheel horsepower'),
    );
  });

  test('no EEA monitoring CSV is bundled', () {
    expect(
      catalogFiles.where(
        (name) =>
            name.toLowerCase().contains('eea') ||
            name.toLowerCase().contains('co2cars') ||
            name.toLowerCase().contains('eu_2019'),
      ),
      isEmpty,
    );
    expect(sources, contains('It is not bundled'));
  });
}
