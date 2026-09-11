/// Integrity-checked, offline Taiwan MOEA vehicle identity catalog.
///
/// Rows are passenger-car certification identities from dataset 6032.
/// Dataset 11163 is pinned as the annual guide PDF and is not a row source.
/// 參考車重 is kept as a source attribute and is not curb mass.
library;

import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import 'catalog_digest.dart';

class TwVehicleCatalogException implements Exception {
  const TwVehicleCatalogException(this.message);

  final String message;

  @override
  String toString() => 'TwVehicleCatalogException: $message';
}

class TwVehicleConfiguration {
  const TwVehicleConfiguration({
    required this.twId,
    required this.origin,
    required this.vehicleClass,
    required this.powertrain,
    required this.issueYearCe,
    required this.issueDate,
    required this.make,
    required this.model,
    required this.transmission,
    required this.doors,
    required this.displacementCc,
    required this.referenceMassKg,
    required this.applicant,
    required this.sourceFile,
  });

  final String twId;
  final String origin;
  final String vehicleClass;
  final String powertrain;
  final int issueYearCe;
  final String issueDate;
  final String make;
  final String model;
  final String transmission;
  final String doors;
  final String displacementCc;
  final String referenceMassKg;
  final String applicant;
  final String sourceFile;

  static const market = 'TW';

  double? get displacementL {
    if (displacementCc.isEmpty) return null;
    final cc = double.tryParse(displacementCc);
    if (cc == null || !cc.isFinite || cc <= 0) return null;
    return cc / 1000.0;
  }
}

class TwVehicleCatalog {
  TwVehicleCatalog._({
    required Map<String, TwVehicleConfiguration> byId,
    required this.snapshotSha256,
    required this.retrievedAtUtc,
  }) : _byId = Map.unmodifiable(byId) {
    final years = <int>{};
    final makesByYear = <int, Set<String>>{};
    final modelsByYearMake = <int, Map<String, Set<String>>>{};
    final configurations =
        <int, Map<String, Map<String, List<TwVehicleConfiguration>>>>{};
    for (final configuration in _byId.values) {
      years.add(configuration.issueYearCe);
      makesByYear
          .putIfAbsent(configuration.issueYearCe, () => {})
          .add(configuration.make);
      modelsByYearMake
          .putIfAbsent(configuration.issueYearCe, () => {})
          .putIfAbsent(configuration.make, () => {})
          .add(configuration.model);
      configurations
          .putIfAbsent(configuration.issueYearCe, () => {})
          .putIfAbsent(configuration.make, () => {})
          .putIfAbsent(configuration.model, () => [])
          .add(configuration);
    }
    _years = years.toList()..sort();
    _makesByYear = Map<int, List<String>>.unmodifiable({
      for (final entry in makesByYear.entries)
        entry.key: List<String>.unmodifiable(entry.value.toList()..sort()),
    });
    _modelsByYearMake = Map<int, Map<String, List<String>>>.unmodifiable({
      for (final yearEntry in modelsByYearMake.entries)
        yearEntry.key: Map<String, List<String>>.unmodifiable({
          for (final makeEntry in yearEntry.value.entries)
            makeEntry.key: List<String>.unmodifiable(
              makeEntry.value.toList()..sort(),
            ),
        }),
    });
    _configurations =
        Map<
          int,
          Map<String, Map<String, List<TwVehicleConfiguration>>>
        >.unmodifiable({
          for (final yearEntry in configurations.entries)
            yearEntry.key:
                Map<
                  String,
                  Map<String, List<TwVehicleConfiguration>>
                >.unmodifiable({
                  for (final makeEntry in yearEntry.value.entries)
                    makeEntry.key:
                        Map<String, List<TwVehicleConfiguration>>.unmodifiable({
                          for (final modelEntry in makeEntry.value.entries)
                            modelEntry.key:
                                List<TwVehicleConfiguration>.unmodifiable(
                                  modelEntry.value,
                                ),
                        }),
                }),
        });
  }

  static const catalogAsset = 'assets/vehicle_catalog/tw_moeaea_vehicles.csv';
  static const manifestAsset =
      'assets/vehicle_catalog/tw_moeaea_vehicles.manifest.json';

  static const requiredColumns = <String>[
    'tw_id',
    'market',
    'origin',
    'vehicle_class',
    'powertrain',
    'issue_year_ce',
    'issue_date',
    'make',
    'model',
    'transmission',
    'doors',
    'displacement_cc',
    'reference_mass_kg',
    'applicant',
    'source_file',
  ];

  final Map<String, TwVehicleConfiguration> _byId;
  late final List<int> _years;
  late final Map<int, List<String>> _makesByYear;
  late final Map<int, Map<String, List<String>>> _modelsByYearMake;
  late final Map<int, Map<String, Map<String, List<TwVehicleConfiguration>>>>
  _configurations;

  final String snapshotSha256;
  final DateTime retrievedAtUtc;

  int get length => _byId.length;
  List<int> get years => List.unmodifiable(_years);

  static Future<TwVehicleCatalog> load([AssetBundle? bundle]) async {
    final assets = bundle ?? rootBundle;
    try {
      final values = await Future.wait([
        assets.loadString(manifestAsset),
        assets.loadString(catalogAsset),
      ]);
      return TwVehicleCatalog.fromStrings(
        manifestJson: values[0],
        csv: values[1],
      );
    } on TwVehicleCatalogException {
      rethrow;
    } catch (error) {
      throw TwVehicleCatalogException('cannot load bundled catalog: $error');
    }
  }

  factory TwVehicleCatalog.fromStrings({
    required String manifestJson,
    required String csv,
  }) {
    try {
      final manifest = _TwManifest.parse(manifestJson);
      final csvBytes = utf8.encode(csv);
      final actualHash = sha256Hex(csvBytes);
      if (manifest.sha256 != actualHash) {
        throw const TwVehicleCatalogException(
          'catalog SHA-256 does not match its manifest',
        );
      }
      if (manifest.sizeBytes != csvBytes.length) {
        throw const TwVehicleCatalogException(
          'catalog byte size does not match its manifest',
        );
      }
      final decoded = Csv(autoDetect: false, lineDelimiter: '\n').decode(csv);
      if (decoded.isEmpty) {
        throw const TwVehicleCatalogException('catalog CSV is empty');
      }
      final header = decoded.first.map((value) => value.toString()).toList();
      if (!_sameStrings(header, requiredColumns)) {
        throw const TwVehicleCatalogException(
          'catalog CSV columns do not match schema version 1',
        );
      }
      final byId = <String, TwVehicleConfiguration>{};
      final makes = <String>{};
      int? yearMin;
      int? yearMax;
      for (var index = 1; index < decoded.length; index++) {
        final row = decoded[index].map((value) => value.toString()).toList();
        if (row.length != requiredColumns.length) {
          throw TwVehicleCatalogException(
            'catalog row $index does not match the schema',
          );
        }
        final mapped = <String, String>{
          for (var column = 0; column < requiredColumns.length; column++)
            requiredColumns[column]: row[column],
        };
        if (mapped['market'] != 'TW') {
          throw TwVehicleCatalogException(
            'catalog row $index is not market=TW',
          );
        }
        final year = int.parse(mapped['issue_year_ce']!);
        final configuration = TwVehicleConfiguration(
          twId: mapped['tw_id']!,
          origin: mapped['origin']!,
          vehicleClass: mapped['vehicle_class']!,
          powertrain: mapped['powertrain']!,
          issueYearCe: year,
          issueDate: mapped['issue_date']!,
          make: mapped['make']!,
          model: mapped['model']!,
          transmission: mapped['transmission']!,
          doors: mapped['doors']!,
          displacementCc: mapped['displacement_cc']!,
          referenceMassKg: mapped['reference_mass_kg']!,
          applicant: mapped['applicant']!,
          sourceFile: mapped['source_file']!,
        );
        if (configuration.twId.isEmpty ||
            configuration.make.isEmpty ||
            configuration.model.isEmpty) {
          throw TwVehicleCatalogException(
            'catalog row $index is missing identity',
          );
        }
        if (byId.containsKey(configuration.twId)) {
          throw TwVehicleCatalogException(
            'catalog contains duplicate tw_id ${configuration.twId}',
          );
        }
        byId[configuration.twId] = configuration;
        makes.add(configuration.make);
        yearMin = yearMin == null ? year : (year < yearMin ? year : yearMin);
        yearMax = yearMax == null ? year : (year > yearMax ? year : yearMax);
      }
      if (byId.length != manifest.rowCount) {
        throw const TwVehicleCatalogException(
          'catalog row count does not match its manifest',
        );
      }
      if (makes.length != manifest.uniqueMakeCount) {
        throw const TwVehicleCatalogException(
          'catalog make count does not match its manifest',
        );
      }
      if (yearMin != manifest.yearMin || yearMax != manifest.yearMax) {
        throw const TwVehicleCatalogException(
          'catalog year bounds do not match its manifest',
        );
      }
      return TwVehicleCatalog._(
        byId: byId,
        snapshotSha256: manifest.sha256,
        retrievedAtUtc: manifest.retrievedAtUtc,
      );
    } on TwVehicleCatalogException {
      rethrow;
    } catch (error) {
      throw TwVehicleCatalogException('invalid catalog format: $error');
    }
  }

  TwVehicleConfiguration? byTwId(String twId) => _byId[twId];

  List<String> makes({int? year}) {
    if (year == null) {
      final all = <String>{};
      for (final names in _makesByYear.values) {
        all.addAll(names);
      }
      return List<String>.unmodifiable(all.toList()..sort());
    }
    return _makesByYear[year] ?? const [];
  }

  List<String> models({required int year, required String make}) =>
      _modelsByYearMake[year]?[make] ?? const [];

  List<TwVehicleConfiguration> configurations({
    required int year,
    required String make,
    required String model,
  }) => _configurations[year]?[make]?[model] ?? const [];
}

class _TwManifest {
  const _TwManifest({
    required this.sha256,
    required this.sizeBytes,
    required this.rowCount,
    required this.uniqueMakeCount,
    required this.yearMin,
    required this.yearMax,
    required this.retrievedAtUtc,
  });

  final String sha256;
  final int sizeBytes;
  final int rowCount;
  final int uniqueMakeCount;
  final int yearMin;
  final int yearMax;
  final DateTime retrievedAtUtc;

  static _TwManifest parse(String manifestJson) {
    final Object? decoded = jsonDecode(manifestJson);
    if (decoded is! Map<String, Object?>) {
      throw const TwVehicleCatalogException('manifest must be a JSON object');
    }
    if (decoded['schema_version'] != 1) {
      throw const TwVehicleCatalogException(
        'unsupported vehicle catalog schema version',
      );
    }
    if (decoded['dataset'] !=
        'Taiwan MOEA Energy Administration vehicle identity') {
      throw const TwVehicleCatalogException(
        'manifest does not identify the Taiwan catalog',
      );
    }
    final coverage = decoded['coverage'];
    if (coverage is! Map<String, Object?> || coverage['market'] != 'Taiwan') {
      throw const TwVehicleCatalogException(
        'manifest does not identify market=Taiwan',
      );
    }
    final source = decoded['source'];
    if (source is! Map<String, Object?>) {
      throw const TwVehicleCatalogException('manifest source is missing');
    }
    final retrievedText = source['retrieved_at_utc'];
    if (retrievedText is! String) {
      throw const TwVehicleCatalogException(
        'source.retrieved_at_utc must be an ISO-8601 UTC timestamp',
      );
    }
    final retrievedAt = DateTime.tryParse(retrievedText);
    if (retrievedAt == null || !retrievedAt.isUtc) {
      throw const TwVehicleCatalogException(
        'source.retrieved_at_utc must be an ISO-8601 UTC timestamp',
      );
    }
    final output = decoded['output'];
    if (output is! Map<String, Object?>) {
      throw const TwVehicleCatalogException('manifest output is missing');
    }
    if (output['file'] != 'tw_moeaea_vehicles.csv') {
      throw const TwVehicleCatalogException('unexpected catalog output file');
    }
    final hash = output['sha256'];
    if (hash is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      throw const TwVehicleCatalogException(
        'output.sha256 is not a lowercase SHA-256 digest',
      );
    }
    int positive(Object? value, String name) {
      if (value is! int || value <= 0) {
        throw TwVehicleCatalogException('$name must be a positive integer');
      }
      return value;
    }

    return _TwManifest(
      sha256: hash,
      sizeBytes: positive(output['size_bytes'], 'output.size_bytes'),
      rowCount: positive(output['row_count'], 'output.row_count'),
      uniqueMakeCount: positive(
        output['unique_make_count'],
        'output.unique_make_count',
      ),
      yearMin: positive(output['year_min'], 'output.year_min'),
      yearMax: positive(output['year_max'], 'output.year_max'),
      retrievedAtUtc: retrievedAt,
    );
  }
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
