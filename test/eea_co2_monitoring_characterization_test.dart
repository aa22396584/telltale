import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String characterization;
  late String sources;
  late List<String> catalogFiles;

  setUpAll(() {
    characterization = File('docs/catalog/eea-2019-631-characterization.md')
        .readAsStringSync();
    sources = File('docs/vehicle-data-sources.md').readAsStringSync();
    catalogFiles = Directory('assets/vehicle_catalog')
        .listSync()
        .map((entity) => entity.uri.pathSegments.last)
        .toList();
  });

  test('Stage C pins the 2025 provisional monitoring table', () {
    expect(characterization, contains('co2cars_2025Pv31'));
    expect(
      characterization,
      contains('10.2909/b4044b06-2e6b-4f8e-a6e6-66e0e98bb0dd'),
    );
    expect(characterization, contains('10833597'));
    expect(
      characterization,
      contains(
        'aa9caf445886466cec99e56da80316c92c0ff19bf23b0a98480f7ba61f2112b3',
      ),
    );
    expect(characterization, contains('CC BY 4.0'));
    expect(characterization, contains('| Published | 2026-06-25'));
    expect(
      characterization,
      isNot(contains('2025-06-25')),
      reason: 'publication is 2026-06-25; 2025 is the monitoring year, not the pin date',
    );
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

  test('Stage C records measured dedupe prototype and lookup timings', () {
    expect(characterization, contains('https://discodata.eea.europa.eu/sql'));
    expect(characterization, contains('66736'));
    expect(characterization, contains('17063'));
    expect(characterization, contains('63841'));
    expect(characterization, contains('10067'));
    expect(characterization, contains('7 330 901'));
    expect(characterization, contains('28.8 ns'));
    expect(characterization, contains('7 512 666 176 bytes'));
    expect(
      characterization,
      contains(
        'Parser memory of the **full 10 833 597-row registration table**',
      ),
    );
    expect(characterization, contains('remains **not-run**'));
    expect(
      characterization,
      contains("Mk=''`, `Cn=''"),
      reason: 'empty commercial-name tuples must stay visible so 66736 is not an identity',
    );
    expect(
      characterization,
      contains('These numbers do **not** accept an aggregation contract'),
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
