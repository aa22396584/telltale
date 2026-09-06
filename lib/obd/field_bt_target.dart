/// Field BT target selection. Address (device.id) wins over display name.
library;

import 'transport/obd_transport.dart';

/// Label the field journey taps. When [address] is set this is `device.id`,
/// never the first same-name tile.
String fieldBtFinderLabel({required String name, required String address}) {
  final trimmed = address.trim();
  return trimmed.isEmpty ? name : trimmed;
}

/// Pick the unique device that matches [address] if given, else a unique [name].
///
/// Duplicate names without an address are not auto-picked. An address that
/// matches no `device.id` does not fall back to another same-name tile.
DiscoveredDevice? selectFieldBtDevice({
  required Iterable<DiscoveredDevice> devices,
  required String name,
  String address = '',
}) {
  final wantedAddress = address.trim();
  if (wantedAddress.isNotEmpty) {
    final needle = wantedAddress.toLowerCase();
    final hits = [
      for (final device in devices)
        if (device.id.toLowerCase() == needle) device,
    ];
    return hits.length == 1 ? hits.single : null;
  }
  final hits = [
    for (final device in devices)
      if (device.name == name) device,
  ];
  return hits.length == 1 ? hits.single : null;
}
