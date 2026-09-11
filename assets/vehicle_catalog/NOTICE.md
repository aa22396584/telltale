# Vehicle catalog notices

These notices apply to the normalized data snapshots in this directory. The
project's GPL licence covers the application source code; it does not purport to
relicense government data, agency names, trademarks, photographs, or other
third-party material.

## U.S. EPA FuelEconomy.gov Find-a-Car snapshot

- Dataset: `www.FuelEconomy.gov`
- Data.gov identifier: `E87A4099-3793-47D7-A687-969577FFE4F4`
- Publisher recorded by Data.gov: U.S. EPA Office of Air and Radiation (OAR) –
  Office of Air Quality Planning and Standards (OAQPS)
- Dataset metadata and access terms:
  <https://catalog.data.gov/dataset/www-fueleconomy-gov>
- EPA Standard Open Data License:
  <https://edg.epa.gov/EPA_Data_License.htm>
- Download page: <https://www.fueleconomy.gov/feg/download.shtml>
- FuelEconomy.gov / ORNL disclaimer:
  <https://www.fueleconomy.gov/feg/ORNL-disclaimer.htm>
- Retrieved: `2026-08-29T15:08:19+00:00`
- Source ZIP SHA-256:
  `66a2948c425c3cf8ad61a184a12296099ef368217d3012b3f7531dcc9c5e2649`
- Normalized CSV SHA-256:
  `6dc8aed9232a88844e18f0160e94eeaa75abc0dcf8a36286e3166797f4933331`

Data.gov identifies this EPA dataset's licence as the EPA Standard Open Data
License. That licence states that, unless otherwise specified, data produced by
the U.S. EPA is in the U.S. public domain and is not subject to domestic
copyright protection under 17 U.S.C. section 105. It provides no warranty for
accuracy or utility and recommends reviewing dataset metadata for limitations.

This project applies that basis only to the normalized vehicle-data rows in
`us_epa_vehicles.csv`. It does not include or claim rights in FuelEconomy.gov
vehicle photographs, logos, trademarks, page copy, or third-party content.

## U.S. NHTSA vPIC make snapshot

- Dataset: NHTSA Product Information Catalog and Vehicle Listing (vPIC)
- API source:
  <https://vpic.nhtsa.dot.gov/api/vehicles/GetAllMakes?format=json>
- NHTSA terms: <https://www.nhtsa.gov/about-nhtsa/terms-use>
- Retrieved: `2026-08-29T15:11:00+00:00`
- Source response SHA-256:
  `6efad9b16d1179ff051c450e9abfecefd77319fa08c71af9c90c9aeafeab668a`
- Normalized CSV SHA-256:
  `58b84c162e2cb3a47a6245c117002e337a2b00eedab074382d8ff762bea9cda5`

NHTSA/DOT states that information presented on its website is considered
public information and may be distributed or copied. This file is a normalized
derivative of the cited vPIC response; it is not represented as a distinct
NHTSA publication or as a complete list of consumer-facing brands.

## Taiwan MOEA Energy Administration identity snapshot

- Named Stage A dataset: [車輛油耗指南 dataset 11163](https://data.gov.tw/dataset/11163)
- Publisher: 經濟部能源署 (MOEA Energy Administration)
- Licence: 政府資料開放授權條款第 1 版
  <https://data.gov.tw/license>
- Retrieved: `2026-09-11T02:09:14+00:00`
- Dataset 11163 index SHA-256:
  `49af372921867c26a7349792ba1ae69dc55fc2d9c33172baeaa824bf07b4401e`
- Dataset 11163 FileUrl artifact (PDF, 114年車輛油耗指南):
  `4f0666ef18339bca855112c23866588ad5a274cf9b89a18c2909d7aaa197bbb9`
- Configuration identity rows are **not** parsed from that PDF. The official
  FileUrl at retrieval is a guidebook, not a configuration table.
- Configuration identity CSV comes from sibling official dataset
  [車型耗能證明核發資料 dataset 6032](https://data.gov.tw/dataset/6032)
  ZIP SHA-256:
  `da6b72a1885d4a291b64ed2fc9094b6935e2eed96b830407e493a1df5cc1b687`
- Normalized CSV SHA-256:
  `97a4a4d14012c90204a124795a3286a96d91141075abfc37ab1f415da27b60cd`

The snapshot copies exact source fields for passenger-car certification
identity. `issue_year_ce` is the certification calendar year (ROC year + 1911),
not a U.S. model year. `reference_mass_kg` is 參考車重, not curb mass, not mass
in running order, and not test mass. A Taiwan make/model string is not a
FuelEconomy.gov configuration.

## No endorsement or warranty

EPA, DOE, ORNL, NHTSA, DOT, and the MOEA Energy Administration do not endorse
this project, its authors, or any vehicle, manufacturer, product, or service
shown by the application. The source data and normalized snapshots are provided
as-is. The agencies make no warranty as to accuracy, completeness, adequacy,
non-infringement, merchantability, fitness for a particular purpose, or
usefulness. Consult the adjacent manifests for exact scope, exclusions,
retrieval metadata, and hashes.
