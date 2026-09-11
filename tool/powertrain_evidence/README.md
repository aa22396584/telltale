# Powertrain evidence matrix

Research tooling for GitHub issue #332. This directory is **not** a Flutter
asset and is **not** read by app runtime. It does not change catalog status,
commands, or limitations.

The committed artifact is `matrix.json`. It has two sections:

- `catalog` — regenerated from `assets/powertrain_battery/powertrain_battery_catalog.json` and its manifest. Never hand-edit this section.
- `research` — copied from `research/rows.json` (sorted by `id`). Hand-authored claims only.

## Generate

PowerShell and POSIX (repo root):

```text
python tool/powertrain_evidence/generate_matrix.py
python tool/powertrain_evidence/generate_matrix.py --check
```

`--check` exits 1 when `matrix.json` would change. Output is UTF-8, sorted keys, LF, trailing newline.

## Validate

```text
python tool/powertrain_evidence/validate_matrix.py
```

Exit 0 only when every rule below is satisfied. Exit 1 prints one issue per line.

## Tests

```text
python -m unittest discover -s tool/powertrain_evidence -p "test_*.py" -v
```

## Disposition

Research `disposition` is one of: `unknown`, `no-source`, `identity-only`, `single-family`, `transport-blocked`, `experimental-candidate`, `community-qualified`.

`unknown` rows may have empty `source_families` and empty `signals`. They must not carry a wire contract.

## Source family derivation

`family` is not a free-form label. The validator derives it with
`schema.derive_source_family` from the source identity:

- GitHub `github.com`, `raw.githubusercontent.com`, and `api.github.com/repos` URL → lowercase `org/repo` (blob/tree/raw path, revision, `www.`, default ports, and a trailing DNS dot ignored; hostnames IDNA-canonicalized so Unicode and punycode forms match; percent-encoded unreserved path characters decoded so `github.com/%6frg/repo` is `org/repo`; two files or revisions in one repo are one family)
- common forges (`gitlab.com`, `bitbucket.org`, `codeberg.org`, `gitea.com`, `git.sr.ht`) → lowercase `host/org/repo` (GitLab keeps the full group/project path up to `/-/` so nested `org/subgroup/repo-a` and `org/subgroup/repo-b` are distinct; blob/tree/src path and revision ignored)
- other http(s) URL → lowercase `host` plus path (query/fragment ignored; host IDNA-canonicalized; percent-encoded unreserved characters decoded; `.` / `..` path segments collapsed so `example.net/a` and `example.net/x/../a` are one family); renaming the source does not create a second family
- otherwise lowercase `name` (`org/repo` when `name` contains a slash)

One family means one capture lineage. A fork, copy, wrapper, derived CSV, or
the same capture (same `org/repo` plus path, or the same artifact hash) is the
same family even when the row writes a different `family` string. Declared
`derived_from` / `fork_of` is rejected rather than treated as independence.

## Rules the validator fails closed on

- `signals`, `commands`, nested `observations`, or `source_families` (when present) that is not a list — a dict/object is rejected rather than coerced to empty, so an `unknown` row cannot hide a wire contract or a source family
- `status=community` or `status=ready` (catalog profile or research row) with zero *concrete* executable commands (a nonempty `commands: [{}]` list is not executable; catalog commands must use native `mode` / `identifier` keys — research `service` / `did` aliases are not enough to load `PowertrainBatteryCommand.fromJson` — Mode 22 only for installable catalog tiers (`profile_catalog_validator.dart` ~215-225); every command on a reviewed profile is checked (a valid sibling does not hide Mode 21 / malformed extras); and every signal on a counted command must pass id/name, equation, width ≤ 14, and min/max range (`profile_catalog_validator.dart` ~243-303) — empty `signals` is `missing_signals` ~471-476)
- `disposition: community-qualified` without agreeing observations from at least two distinct *derived* source families per shipped signal (wire observations **or** a nonempty `contract`)
- observation or nonempty `contract` that is missing any mandatory wire field (`request_header`, `expected_responder`, `service`, `did`, `payload_length`, `formula`, `signedness`, `unit`) or a valid `byte_window` (`offset` ≥ 0, `width` ≥ 1, `width` ≤ 14, `offset + width <= payload_length`; same bounds as `profile_catalog_validator.dart`)
- observation or nonempty `contract` whose wire values are present but not syntax-valid (`request_header` / `expected_responder` must be exact 11-bit or 29-bit CAN ids per `isExactPowertrainCanId`; `service`/`mode` is read-only `21`/`22` with matching identifier width; `formula` is nonempty and FormulaEngine-sound for the window, including LOOKUP/CLOSEST wiki grammar `value:default:key=val` — comma forms and two-part `LOOKUP(A:0)` fail — and evaluation uses the catalog's fixed all-1s probe (`profile_catalog_validator.dart` ~277-280) so constant `/0` or `%0` such as `A/0` / `1/(A-A)` and catalog-undefined `1/(A-1)` fail; the probe result must be finite (`formula_engine.dart` ~609-616; a 400-digit literal that overflows to `inf` fails); `INT` truncates toward zero (`formula_engine.dart` ~1119-1132; `1/INT(A/2)` fails on the all-1s probe); `BIT` index must be a finite nonnegative integer (`formula_engine.dart` ~1869-1875; `BIT(A,1.5)` fails); `SIGNED` is only `SIGNED([A-N])` (`formula_engine.dart` ~367; `SIGNED(A+1)` and `SIGNED((A))` fail); `FLOAT32`/`FLOAT64` decode IEEE-754 and reject non-finite bit patterns such as `FLOAT32(127:128:0:0)`; `unit` nonempty; `signedness` `unsigned`|`signed`; `payload_length` / `offset` / `width` are non-bool ints)
- research `command_count` that disagrees with `len(commands)` (`command_count` is informational; a claimed count is not an executable claim)
- command that is present but not a concrete read-only command (exact CAN ids, service `21`/`22`, identifier width 2 or 4, required positive non-bool `payload_length`; a `payload` string is not a substitute)
- executable claim that is neither a concrete command (header/responder/service/DID + payload) nor a signal with a complete wire contract
- shipped `contract` whose wire signature disagrees with independently corroborated observations
- executable observation whose `source_id` does not resolve to a unique declared source
- two sources that share a normalized URL (default HTTP/HTTPS ports stripped) but declare different families
- source `role` not one of `primary`, `corroborating`, `secondary`
- `disposition: community-qualified` across two or more families with no `independence_rationale` (even when every source is `primary`)
- `disposition: experimental-candidate` with zero executable claims (corroboration is not required; that is what keeps it distinct from `community-qualified`)
- declared `family` that does not match the derived family
- source whose `url`/`name` yield no derived family (declared `family` is not a fallback identity)
- two sources that share repo+path (any revision) or the same `artifact_sha256` but declare different families
- `derived_from` / `fork_of` on a row or source
- corroborating *derived* family equal to the primary family
- corroborating source with no `independence_rationale`
- executable wire claim with no `licence_redistribution.decision`
- executable wire claim with no immutable `revision` (40/64 hex) or `artifact_sha256`
- non-`unknown` row missing market, year (`year` or `year_from`/`year_to`), or `firmware_scope` (`market` and `firmware_scope` must be nonempty strings; year values are non-bool ints in 1886..2100 and ranges are ordered, matching `profile_catalog_validator.dart`)
- `inherits_from` / `inherit_from` / `inherited_from` on the row, a source, a command, a signal, a contract, an observation, or `vehicle_evidence`, or a locator of the form `row:` / `research:` / `research_row:` / `sibling:` on those objects (including `command.locator`, `contract.locator` / `evidence_locator`), or a locator equal to another row/catalog id
- signal `agreement` `confirmed` or `agreeing` while observations disagree on header/responder/service-or-mode/DID-or-identifier/payload length/byte window/formula/signedness/unit (aliases are resolved before comparison)
- sales/popularity data outside the `priority` block (`evidence_tier: sales`, `kind: sales`, or keys `sales` / `sales_rank` / `popularity` / `units_sold` / `market_share`)
- `evidence: physicalVehicle` with no retained `vehicle_evidence.locator` / `vehicle_evidence_locator` (a locator, when present, is extracted and the path can pass)
- catalog `status: ready` without `evidence: physicalVehicle` and a retained vehicle-evidence locator
- catalog-derived section stale versus the catalog
- catalog manifest `sha256` / `size_bytes` not matching the catalog file bytes
- `research` section stale versus `research/rows.json`
- `disposition: unknown` carrying an executable claim

`priority` (`source`, `as_of`, `scope`, `method`) is prioritization metadata only. It is never an evidence tier.

## Path choice

`pubspec.yaml` lists two specific powertrain catalog files, not a directory glob. The matrix still lives here rather than under `assets/powertrain_battery/` so it cannot be mistaken for a bundled catalog input. Tests assert the matrix path is absent from `pubspec.yaml` assets and from `lib/`.
