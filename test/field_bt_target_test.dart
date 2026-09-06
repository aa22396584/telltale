import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/field_bt_target.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'support/localized_app.dart';

DiscoveredDevice _dev(String id, {String name = 'OBDBLE'}) {
  return DiscoveredDevice(
    id: id,
    name: name,
    kind: TransportKind.bluetoothLe,
  );
}

void main() {
  const left = 'AA:BB:CC:00:00:01';
  const right = 'AA:BB:CC:00:00:02';

  test('address selects the matching id among same-name devices', () {
    final chosen = selectFieldBtDevice(
      devices: [_dev(left), _dev(right)],
      name: 'OBDBLE',
      address: right,
    );
    expect(chosen?.id, right);
  });

  test('address does not fall back to the other same-name tile', () {
    final chosen = selectFieldBtDevice(
      devices: [_dev(left), _dev(right)],
      name: 'OBDBLE',
      address: 'DE:AD:BE:EF:00:01',
    );
    expect(chosen, isNull);
  });

  test('address match is case-insensitive', () {
    final chosen = selectFieldBtDevice(
      devices: [_dev(right)],
      name: 'OBDBLE',
      address: right.toLowerCase(),
    );
    expect(chosen?.id, right);
  });

  test('without address, a unique name is selected', () {
    final chosen = selectFieldBtDevice(
      devices: [_dev(left, name: 'OBDBLE'), _dev(right, name: 'Buds')],
      name: 'OBDBLE',
    );
    expect(chosen?.id, left);
  });

  test('without address, duplicate names are not auto-picked', () {
    final chosen = selectFieldBtDevice(
      devices: [_dev(left), _dev(right)],
      name: 'OBDBLE',
    );
    expect(chosen, isNull);
  });

  test('finder label is device.id when address is set, else the name', () {
    expect(
      fieldBtFinderLabel(name: 'OBDBLE', address: right),
      right,
    );
    expect(
      fieldBtFinderLabel(name: 'OBDBLE', address: ''),
      'OBDBLE',
    );
  });

  testWidgets('tap uses device.id when address is set, not the first name', (
    tester,
  ) async {
    String? tapped;
    final devices = [_dev(left), _dev(right)];
    await tester.pumpWidget(
      localizedMaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              for (final device in devices)
                InkWell(
                  onTap: () => tapped = device.id,
                  child: Column(
                    children: [
                      Text(device.name),
                      Text(device.id),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final target = selectFieldBtDevice(
      devices: devices,
      name: 'OBDBLE',
      address: right,
    );
    expect(target, isNotNull);
    await tester.tap(find.text(target!.id));
    expect(tapped, right);
    expect(tapped, isNot(left));
  });
}
