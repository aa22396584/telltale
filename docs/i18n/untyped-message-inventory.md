# Remaining untyped screen messages (#45)

Census of `app/lib` after public `main@1ace9e90` / source `master@93c2bd91`
(#127/#128 merged). This is an inventory, not a close.

## Still bakes `issue: null`

| Site | Reachable on a screen? | Notes |
| --- | --- | --- |
| ~~`UnaddressableRequestException`~~ | Polling loop still keys off the type | Now carries `TransportIssue.requestUnaddressable`. Copy exists; gauge still uses `PidFault.busError`. |

Doc comments that mention `issue: null` in `manual_command_refusal.dart`,
`settings_screen.dart`, `manual_command_copy.dart`, and `pid_formula_copy.dart`
are history, not throw sites.

## `error.message` / `e.message` still interpolated into user-visible copy

These are the remaining #45/#92 candidates. Engine diagnostics that stay in
transcripts/export are listed only to keep the census honest.

| Site | Kind |
| --- | --- |
| `core/network/android_wifi_route_binder.dart` | Chinese UI strings interpolate `e.message` |
| `obd/transport/wifi_transport.dart` | Chinese connect failure interpolates `e.message` |
| `ui/screens/pids/powertrain_battery_catalog_screen.dart` | snack uses `error.message` |
| `ui/screens/pids/pid_editor_screen.dart` | `formulaIssueText(...) ?? e.message` |
| `state/dtc_scan.dart` | `message = e.message` |
| `obd/polling_engine.dart` | Chinese status interpolates exception text |
| `obd/transport/ble_transport.dart`, `classic_transport.dart` | platform `error.message` into connect path |
| `obd/pid/formula_engine.dart`, `pid_csv.dart` | diagnostic/export, not a locale screen |

## Not closed

#45 stays open: reachable untyped messages remain. #128 closed the two
manual-command bakers; it did not empty this list.
