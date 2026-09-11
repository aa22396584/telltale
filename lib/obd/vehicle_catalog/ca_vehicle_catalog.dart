/// Integrity-checked, offline Canada NRCan vehicle identity catalog.
///
/// ICE, BEV, and PHEV stay separate resource classes. Motor kW is a source
/// attribute and is not wheel horsepower. Consumption, range, and CO2 are
/// not copied into [VehicleProfile].
library;

import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

import 'catalog_digest.dart';

class CaVehicleCatalogException implements Exception {
  const CaVehicleCatalogException(this.message);

  final String message;

  @override
  String toString() => 'CaVehicleCatalogException: $message';
}

class CaVehicleConfiguration {
  const CaVehicleConfiguration({
    required this.caId,
    required this.resourceClass,
    required this.modelYear,
    required this.make,
    required this.model,
    required this.vehicleClass,
    required this.engineSizeL,
    required this.cylinders,
    required this.transmission,
    required this.fuelType,
    required this.motorKw,
    required this.sourceFile,
  });

  final String caId;
  final String resourceClass;
  final int modelYear;
  final String make;
  final String model;
  final String vehicleClass;
  final String engineSizeL;
  final String cylinders;
  final String transmission;
  final String fuelType;
  final String motorKw;
  final String sourceFile;

  static const market = 'CA';

  double? get displacementL {
    if (engineSizeL.isEmpty) return null;
    final litres = double.tryParse(engineSizeL);
    if (litres == null || !litres.isFinite || litres <= 0) return null;
    return litres;
  }
}

class CaVehicleCatalog {
  CaVehicleCatalog._({
    required Map<String, CaVehicleConfiguration> byId,
    required this.snapshotSha256,
    required this.retrievedAtUtc,
  }) : _byId = Map.unmodifiable(byId) {
    final years = <int>{};
    final makesByYear = <int, Set<String>>{};
    final modelsByYearMake = <int, Map<String, Set<String>>>{};
    final configurations =
        <int, Map<String, Map<String, List<CaVehicleConfiguration>>>>{};
    for (final configuration in _byId.values) {
      years.add(configuration.modelYear);
      makesByYear
          .putIfAbsent(configuration.modelYear, () => {})
          .add(configuration.make);
      modelsByYearMake
          .putIfAbsent(configuration.modelYear, () => {})
          .putIfAbsent(configuration.make, () => {})
          .add(configuration.model);
      configurations
          .putIfAbsent(configuration.modelYear, () => {})
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
          Map<String, Map<String, List<CaVehicleConfiguration>>>
        >.unmodifiable({
          for (final yearEntry in configurations.entries)
            yearEntry.key:
                Map<
                  String,
                  Map<String, List<CaVehicleConfiguration>>
                >.unmodifiable({
                  for (final makeEntry in yearEntry.value.entries)
                    makeEntry.key:
                        Map<String, List<CaVehicleConfiguration>>.unmodifiable({
                          for (final modelEntry in makeEntry.value.entries)
                            modelEntry.key: List<CaVehicleConfiguration>.unmodifiable(
                              modelEntry.value,
                            ),
                        }),
                }),
        });
  }

  static const catalogAsset = 'assets/vehicle_catalog/ca_nrcan_vehicles.csv';
  static const manifestAsset =
      'assets/vehicle_catalog/ca_nrcan_vehicles.manifest.json';

  static const requiredColumns = <String>[
    'ca_id',
    'market',
    'resource_class',
    'model_year',
    'make',
    'model',
    'vehicle_class',
    'engine_size_l',
    'cylinders',
    'transmission',
    'fuel_type',
    'motor_kw',
    'source_file',
  ];

  final Map<String, CaVehicleConfiguration> _byId;
  late final List<int> _years;
  late final Map<int, List<String>> _makesByYear;
  late final Map<int, Map<String, List<String>>> _modelsByYearMake;
  late final Map<int, Map<String, Map<String, List<CaVehicleConfiguration>>>>
  _configurations;

  final String snapshotSha256;
  final DateTime retrievedAtUtc;

  int get length => _byId.length;
  List<int> get years => List.unmodifiable(_years);

  CaVehicleConfiguration? byCaId(String caId) => _byId[caId];

  static Future<CaVehicleCatalog> load([AssetBundle? bundle]) async {
    final assets = bundle ?? rootBundle;
    try {
      final values = await Future.wait([
        assets.loadString(manifestAsset),
        assets.loadString(catalogAsset),
      ]);
      return CaVehicleCatalog.fromStrings(
        manifestJson: values[0],
        csv: values[1],
      );
    } on CaVehicleCatalogException {
      rethrow;
    } catch (error) {
      throw CaVehicleCatalogException('cannot load bundled catalog: $error');
    }
  }

  factory CaVehicleCatalog.fromStrings({
    required String manifestJson,
    required String csv,
  }) {
    try {
      final manifest = _CaManifest.parse(manifestJson);
      final csvBytes = utf8.encode(csv);
      final actualHash = sha256Hex(csvBytes);
      if (manifest.sha256 != actualHash) {
        throw const CaVehicleCatalogException(
          'catalog SHA-256 does not match its manifest',
        );
      }
      if (manifest.sizeBytes != csvBytes.length) {
        throw const CaVehicleCatalogException(
          'catalog byte size does not match its manifest',
        );
      }
      final decoded = Csv(autoDetect: false, lineDelimiter: '\n').decode(csv);
      if (decoded.isEmpty) {
        throw const CaVehicleCatalogException('catalog CSV is empty');
      }
      final header = decoded.first.map((value) => value.toString()).toList();
      if (!_sameStrings(header, requiredColumns)) {
        throw const CaVehicleCatalogException(
          'catalog CSV columns do not match schema version 1',
        );
      }
      final byId = <String, CaVehicleConfiguration>{};
      final makes = <String>{};
      int? yearMin;
      int? yearMax;
      for (var index = 1; index < decoded.length; index++) {
        final row = decoded[index].map((value) => value.toString()).toList();
        if (row.length != requiredColumns.length) {
          throw CaVehicleCatalogException(
            'catalog row $index does not match the schema',
          );
        }
        final mapped = <String, String>{
          for (var column = 0; column < requiredColumns.length; column++)
            requiredColumns[column]: row[column],
        };
        if (mapped['market'] != 'CA') {
          throw CaVehicleCatalogException(
            'catalog row $index is not market=CA',
          );
        }
        final resourceClass = mapped['resource_class']!;
        if (resourceClass != 'ice' &&
            resourceClass != 'bev' &&
            resourceClass != 'phev') {
          throw CaVehicleCatalogException(
            'catalog row $index has unknown resource_class $resourceClass',
          );
        }
        final year = int.parse(mapped['model_year']!);
        final configuration = CaVehicleConfiguration(
          caId: mapped['ca_id']!,
          resourceClass: resourceClass,
          modelYear: year,
          make: mapped['make']!,
          model: mapped['model']!,
          vehicleClass: mapped['vehicle_class']!,
          engineSizeL: mapped['engine_size_l']!,
          cylinders: mapped['cylinders']!,
          transmission: mapped['transmission']!,
          fuelType: mapped['fuel_type']!,
          motorKw: mapped['motor_kw']!,
          sourceFile: mapped['source_file']!,
        );
        if (configuration.caId.isEmpty ||
            configuration.make.isEmpty ||
            configuration.model.isEmpty) {
          throw CaVehicleCatalogException(
            'catalog row $index is missing identity',
          );
        }
        if (byId.containsKey(configuration.caId)) {
          throw CaVehicleCatalogException(
            'catalog contains duplicate ca_id ${configuration.caId}',
          );
        }
        byId[configuration.caId] = configuration;
        makes.add(configuration.make);
        yearMin = yearMin == null ? year : (year < yearMin ? year : yearMin);
        yearMax = yearMax == null ? year : (year > yearMax ? year : yearMax);
      }
      if (byId.length != manifest.rowCount) {
        throw const CaVehicleCatalogException(
          'catalog row count does not match its manifest',
        );
      }
      if (makes.length != manifest.uniqueMakeCount) {
        throw const CaVehicleCatalogException(
          'catalog make count does not match its manifest',
        );
      }
      if (yearMin != manifest.yearMin || yearMax != manifest.yearMax) {
        throw const CaVehicleCatalogException(
          'catalog year bounds do not match its manifest',
        );
      }
      return CaVehicleCatalog._(
        byId: byId,
        snapshotSha256: manifest.sha256,
        retrievedAtUtc: manifest.retrievedAtUtc,
      );
    } on CaVehicleCatalogException {
      rethrow;
    } on FormatException catch (error) {
      throw CaVehicleCatalogException('catalog is not usable: $error');
    }
  }

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

  List<CaVehicleConfiguration> configurations({
    required int year,
    required String make,
    required String model,
  }) => _configurations[year]?[make]?[model] ?? const [];
}

class _CaManifest {
  const _CaManifest({
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

  static _CaManifest parse(String manifestJson) {
    final Object? decoded = jsonDecode(manifestJson);
    if (decoded is! Map<String, Object?>) {
      throw const CaVehicleCatalogException('manifest must be a JSON object');
    }
    if (decoded['schema_version'] != 1) {
      throw const CaVehicleCatalogException(
        'unsupported vehicle catalog schema version',
      );
    }
    if (decoded['dataset'] !=
        'Canada NRCan Fuel Consumption Ratings vehicle identity') {
      throw const CaVehicleCatalogException(
        'manifest does not identify the Canada catalog',
      );
    }
    final coverage = decoded['coverage'];
    if (coverage is! Map<String, Object?> || coverage['market'] != 'Canada') {
      throw const CaVehicleCatalogException(
        'manifest does not identify market=Canada',
      );
    }
    final source = decoded['source'];
    if (source is! Map<String, Object?>) {
      throw const CaVehicleCatalogException('manifest source is missing');
    }
    final retrievedText = source['retrieved_at_utc'];
    if (retrievedText is! String) {
      throw const CaVehicleCatalogException(
        'source.retrieved_at_utc must be an ISO-8601 UTC timestamp',
      );
    }
    final retrievedAt = DateTime.tryParse(retrievedText);
    if (retrievedAt == null || !retrievedAt.isUtc) {
      throw const CaVehicleCatalogException(
        'source.retrieved_at_utc must be an ISO-8601 UTC timestamp',
      );
    }
    final output = decoded['output'];
    if (output is! Map<String, Object?>) {
      throw const CaVehicleCatalogException('manifest output is missing');
    }
    if (output['file'] != 'ca_nrcan_vehicles.csv') {
      throw const CaVehicleCatalogException('unexpected catalog output file');
    }
    final hash = output['sha256'];
    if (hash is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      throw const CaVehicleCatalogException(
        'output.sha256 is not a lowercase SHA-256 digest',
      );
    }
    int positive(Object? value, String name) {
      if (value is! int || value <= 0) {
        throw CaVehicleCatalogException('$name must be a positive integer');
      }
      return value;
    }

    return _CaManifest(
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
