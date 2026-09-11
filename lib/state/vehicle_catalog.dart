/// Lazily loads the bundled vehicle catalog only when the driver opens it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../obd/vehicle_catalog/tw_vehicle_catalog.dart';
import '../obd/vehicle_catalog/us_vehicle_catalog.dart';

typedef UsVehicleCatalogLoader = Future<UsVehicleCatalog> Function();
typedef TwVehicleCatalogLoader = Future<TwVehicleCatalog> Function();

final usVehicleCatalogLoaderProvider = Provider<UsVehicleCatalogLoader>(
  (ref) => UsVehicleCatalog.load,
);

final twVehicleCatalogLoaderProvider = Provider<TwVehicleCatalogLoader>(
  (ref) => TwVehicleCatalog.load,
);
