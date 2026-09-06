/// What the four transports are called on screen.
///
/// [TransportKind] is engine code: lib/obd is pure Dart with no Flutter, no
/// `BuildContext` and no `AppLocalizations`, so it holds the identity of a link
/// and nothing a driver reads. The tile title and subtitle on the connect
/// screen — the first thing anybody opens — come from here instead.
///
/// An [AppLocalizations] parameter rather than a [BuildContext], following
/// lib/ui/widgets/telemetry/telemetry_status_copy.dart: these are pure
/// functions, so a test can walk every value in both languages with
/// `lookupAppLocalizations(...)` and no widget pump.
///
/// `TransportKind.label` is **not** the same string and must not be used here.
/// It is the transport's identity in an exported evidence file, deliberately
/// frozen so two exports stay comparable; see its doc comment.
library;

import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/transport/obd_transport.dart';

/// The tile title, and the transport name on the "last adapter used" line.
///
/// Three of the four are product names that stay byte-identical in both
/// languages (docs/i18n/do-not-translate.md); they are ARB entries anyway so
/// that the rule is enforced by `arb_parity_test.dart` rather than by whoever
/// remembers it.
String transportKindTitle(AppLocalizations l10n, TransportKind kind) =>
    switch (kind) {
      TransportKind.bluetoothClassic => l10n.connectTransportClassicTitle,
      TransportKind.bluetoothLe => l10n.connectTransportBleTitle,
      TransportKind.wifi => l10n.connectTransportWifiTitle,
      TransportKind.demo => l10n.connectTransportDemoTitle,
    };

/// The one-line subtitle under the title.
///
/// The pairing rule is the reason these are worth reading carefully rather than
/// translating fluently: Bluetooth Classic is the one transport the app cannot
/// pair for the driver, and a BLE adapter must NOT be paired in system settings
/// — that route does not work, and the connect screen says so at length
/// (`connectAnswerClassic`, `connectAnswerBleWithClassic`). Neither subtitle
/// mentions pairing, in either language, so neither can send somebody the wrong
/// way; the instruction lives where there is room to give it properly.
String transportKindDescription(AppLocalizations l10n, TransportKind kind) =>
    switch (kind) {
      TransportKind.bluetoothClassic => l10n.connectTransportClassicDescription,
      TransportKind.bluetoothLe => l10n.connectTransportBleDescription,
      TransportKind.wifi => l10n.connectTransportWifiDescription,
      TransportKind.demo => l10n.connectTransportDemoDescription,
    };
