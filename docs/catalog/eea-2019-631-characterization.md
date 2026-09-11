# EEA Regulation (EU) 2019/631 characterization

Stage C of #331. This file is the reviewed decision **not** to bundle a
European identity snapshot from the 2019/631 monitoring tables. It is not a
catalog, not a parser, and not permission to map mass or power into
`VehicleProfile`.

Pinned 2026-09-11 against the live EEA Datahub.

## 1. Official revision

| Item | Pin |
| --- | --- |
| Series | [DAT-116-en](https://www.eea.europa.eu/data-and-maps/data/co2-cars-emission-18) Monitoring of CO2 emissions from passenger cars, Regulation (EU) 2019/631 |
| Series UUID | `fa8b1229-3db6-495d-b18e-9c9b3267c02b` |
| Dataset | Monitoring of CO2 emissions from passenger cars, 2025 — Provisional |
| Record UUID | `b4044b06-2e6b-4f8e-a6e6-66e0e98bb0dd` |
| DOI | https://doi.org/10.2909/b4044b06-2e6b-4f8e-a6e6-66e0e98bb0dd |
| SQL table | `[CO2Emission].[latest].[co2cars_2025Pv31]` |
| Published | 2026-06-25 (Datahub “Published: 25 Jun 2026”; [EEA press release](https://www.eea.europa.eu/en/newsroom/news/average-co2-emissions-from-new-cars-and-vans-significantly-decreased-in-2025) the same calendar day for 2025 provisional cars) |
| Series last modified | 2026-08-19 |
| Status | `P` = provisional (`Version_file` `v31`) |
| Table definition | `Table-definition-cars-2025-Provisional.xlsx` SHA-256 `aa9caf445886466cec99e56da80316c92c0ff19bf23b0a98480f7ba61f2112b3` size 20765 |
| Count query | `SELECT COUNT(*) AS n FROM [CO2Emission].[latest].[co2cars_2025Pv31]` → **10833597** |

Vans are a separate DAT-130-en series (`co2vans_2025Pv27`) and were not counted here.

## 2. Licence / reuse

EEA materials are published under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
unless a dataset says otherwise ([EEA legal notice](https://www.eea.europa.eu/legal/copyright),
modified 2026-07-02). Re-use requires acknowledging the EEA as the source and
not distorting the original meaning.

That licence would permit a derived identity snapshot **if** the other Stage C
gates passed. It is not a reason to bundle registration rows.

## 3. VIN and registration-level identifiers

The 2025 provisional **monitoring** table has no `VIN` column. Sample
`SELECT TOP 5 *` columns:

`ID`, `MS`, `Mp`, `VFN`, `Mh`, `Man`, `MMS`, `TAN`, `T`, `Va`, `Ve`, `Mk`,
`Cn`, `Ct`, `Cr`, `M (kg)`, `Mt`, `Enedc (g/km)`, `Ewltp (g/km)`, `W (mm)`,
`At1 (mm)`, `At2 (mm)`, `Ft`, `Fm`, `Ec (cm3)`, `Ep (KW)`, `Z (Wh/km)`,
`IT`, `Ernedc (g/km)`, `Erwltp (g/km)`, `De`, `Vf`, `R`, `Year`, `Status`,
`Version_file`, `E (g/km)`, `Er (g/km)`, `Zr`, `Dr`, `Fc`, `Ech`, `RLFI`

| Column | Table-definition meaning | Identity risk |
| --- | --- | --- |
| `VFN` | Vehicle family identification number | Family key, not a VIN |
| `Dr` | Registration date | Instance-level |
| `R` | Total new registrations | Often `1` on a row; the table is still registration-oriented |
| `ID` | Identification number | Internal row id |

A **different** EEA product, [real-world emissions (Article 12)](https://www.eea.europa.eu/en/datahub/datahubitem-view/1c1ffad2-34c3-471b-bd69-dd013cdd7b80),
is collected with Vehicle Identification Numbers. That product is out of
scope for an identity catalog and must not be fetched or stored.

Any future normalized candidate from the monitoring table must drop `Dr` and
must not join to the Article 12 VIN-bearing files.

## 4. Configuration identity (not reviewed for aggregation)

Homologation fields exist (`TAN`, `T`/`Va`/`Ve`, `Mk`, `Cn`, `Ft`, `Ec`).
They are not a reviewed configuration contract. `R` is a registration count
on a row that still typically represents one Member-State registration event
(`MS` + `Dr`), not a market-wide unique configuration.

No aggregation/deduplication rule is accepted in this characterization.

## 5. Size / memory / lookup

| Measurement | Value |
| --- | --- |
| Provisional 2025 passenger-car rows | 10 833 597 |
| Sample row | Hyundai i20, `M (kg)` 1140, `Mt` 1237, `Ep (KW)` 74, `R` 1 |
| Flutter asset | Not practical: an order of magnitude above the Canada snapshot (12 971 rows / 1.6 MB) even before CSV expansion |

Parser memory and on-device lookup of 10.8 million registration rows are
rejected without a reviewed aggregate.

## 6. Bundle decision

**Do not bundle.** Reasons, each sufficient:

1. The unit of the table is a new registration in a reporting country, not a
   reusable configuration identity.
2. 10.8 million rows fail the size/lookup gate.
3. No reviewed aggregation contract exists.
4. `M (kg)` is mass in running order, `Mt` is WLTP test mass, `Ep (KW)` is
   engine power in kilowatts. None of those is curb mass or wheel horsepower
   (#335 owns any later mapping).

`assets/vehicle_catalog/` must not contain an EEA/EU CO2-monitoring CSV until
a later issue records a reviewed aggregate that still excludes VIN, `Dr`, and
silent physics relabeling.
