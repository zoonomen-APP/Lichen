# Aposological Zonation Analysis — Lab Notes 2026.02.07

## Overview

Extended the aposology framework from 36 counties (≥5,000 records) to 84 counties (≥3,000 species-level records) 
and applied hierarchical clustering to both counties and states based on taxon absence profiles. 
The central finding: clustering states purely by which taxa they *lack* recovers geographically contiguous zones 
resembling biogeographic regions — despite the algorithm knowing nothing about geography.

## Process

### Step 1: Expanded pipeline at ≥3,000 threshold

Reran `aposology_pipeline.sql` with threshold lowered from 5,000 to 3,000 species-level records.

- Script: `c:/Lichen/aposology/scripts/aposology_pipeline_3000.sql`
- Output: `c:/Lichen/aposology/output/top84_counties_aposology_species.tsv`
- Result: 833 lines, 84 counties, 326 unique taxa

New counties added geographic coverage including Iowa (Fayette_Co.), South Dakota (Custer_Co.), Montana (Flathead_Co.), Nevada (Lincoln_Co.), Texas (Brewster_Co.), West Virginia (Pocahontas_Co.), Connecticut (Litchfield_Co.), and several additional counties in California, Washington, North Carolina, Massachusetts, and elsewhere.

### Step 2: Absence matrix

Built an 84 × 48 matrix. Each cell = number of a county's top-10 taxa absent from a given state (values 0–10).

- File: `c:/Lichen/aposology/output/absence_matrix_84x48.tsv`

### Step 3: Hierarchical clustering

**Method:** Ward's method (ward.D2) on Euclidean distances.

**County clustering:** Clustered 84 counties by their 48-dimensional absence profiles (which states lack their taxa).

**State clustering:** Transposed the matrix so each state has an 84-dimensional profile (how absent it is from each county's perspective). Clustered the 48 states.

Cut both dendrograms at k=5.

- Script: `c:/Lichen/aposology/scripts/aposology_zonation.R`
- Outputs:
  - `c:/Lichen/aposology/output/county_dendrogram.png`
  - `c:/Lichen/aposology/output/state_dendrogram.png`
  - `c:/Lichen/aposology/output/aposology_zone_map.png` (counties colored by cluster)
  - `c:/Lichen/aposology/output/aposology_state_zones.png` (states colored by cluster)

## Key Finding: The State Zone Map

Five zones emerged that are almost entirely geographically contiguous, despite the algorithm knowing nothing about state locations, borders, climate, elevation, or biogeography. It received only a matrix of numbers.

### The five zones

| Zone | Color | States | Interpretation |
|------|-------|--------|---------------|
| 1 (Red) | Red | MS, AL, LA, FL, SC, DE | Deep South + Delaware. Subtropical flora AND severely under-collected |
| 2 (Blue) | Blue | WA, OR, CA, ID, MT, WY, CO, UT, AZ, NM, SD, NE | Western/mountain arc |
| 3 (Green) | Green | OH, IN, IL, MO, KY, TN, WV, VA, GA, NC, PA, MD, NJ, CT, RI | Mid-latitude transitional band |
| 4 (Purple) | Purple | KS, OK, TX, IA, ND, NV, AR | Great Plains void zone — clustered by shared absence |
| 5 (Orange) | Orange | ME, NH, VT, MA, NY, MI, WI, MN | Northeast + upper Midwest boreal-temperate |

### What the algorithm knew

A matrix of numbers. 84 rows, 48 columns. Nothing else.

### What the algorithm did NOT know

- Where any state is located
- Which states share borders
- Anything about climate, elevation, or habitat
- Anything about who collected where
- Anything about botany or biogeography

### What came out

Geographically contiguous zones from numbers alone. The absences have structure, and that structure is geographic. Structured absence is information.

## Anomalies and What They Reveal

Every anomaly tells a story about the data rather than the biology:

**South Dakota clusters blue (western) instead of purple (Plains):** Clifford Wetmore collected intensively in the Black Hills, making South Dakota's taxon presence profile look like the Mountain West rather than its Great Plains neighbors.

**Delaware clusters red (Deep South):** Total absence score of 604 — highest of any state. Almost nobody has collected there. The algorithm cannot distinguish "subtropical flora" from "nobody collected here."

**Connecticut and Rhode Island cluster green (transitional) instead of orange (New England):** Small states with sparse collecting. Absence scores (CT: 385, RI: 477) much higher than their New England neighbors (MA: 295, ME: 267, NH: 271). A gradient of small-state data sparsity: DE (604) → RI (477) → CT (385), each falling into a progressively different cluster despite being geographically close.

**Georgia clusters green (transitional) instead of red (Deep South):** Most Georgia lichen records likely come from the southern Appalachian mountains in the north of the state. The collectors go to the mountains, so Georgia's absence profile looks mid-latitude Appalachian rather than coastal plain subtropical.

## Conceptual Framework

The usual approach maps what is *present* — distribution maps, species lists, occurrence records. This inverts that entirely. The signal is in the zeros.

Each county's top-10 list implicitly predicts "these common species should be found widely." The absence matrix maps where those predictions fail. The failures cluster geographically, which means the reasons for failure are also geographic — whether biological (real range limits) or sociological (collector voids) or administrative (data structure artifacts).

The zones are real until they aren't. Every breakdown reveals something about the database rather than the biology. A zone map based on what is NOT found.

## Total Absence Scores for Reference

Selected states, ranked by total absence score across all 84 counties:

| State | Total absences | Zone |
|-------|---------------|------|
| New York | 254 | Orange (NE) |
| Maine | 267 | Orange (NE) |
| New Hampshire | 271 | Orange (NE) |
| Vermont | 282 | Orange (NE) |
| Massachusetts | 295 | Orange (NE) |
| Virginia | 310 | Green (transitional) |
| West Virginia | 334 | Green (transitional) |
| Pennsylvania | 338 | Green (transitional) |
| Ohio | 383 | Green (transitional) |
| Connecticut | 385 | Green (transitional) |
| New Jersey | 390 | Green (transitional) |
| Maryland | 402 | Green (transitional) |
| Rhode Island | 477 | Green (transitional) |
| Delaware | 604 | Red (Deep South) |

## Files

| File | Location |
|------|----------|
| Pipeline SQL (3000 threshold) | `c:/Lichen/aposology/scripts/aposology_pipeline_3000.sql` |
| Main output (84 counties) | `c:/Lichen/aposology/output/top84_counties_aposology_species.tsv` |
| Absence matrix | `c:/Lichen/aposology/output/absence_matrix_84x48.tsv` |
| County coordinates (84) | `c:/Lichen/aposology/output/county_coords_84.tsv` |
| Zonation R script | `c:/Lichen/aposology/scripts/aposology_zonation.R` |
| County dendrogram | `c:/Lichen/aposology/output/county_dendrogram.png` |
| State dendrogram | `c:/Lichen/aposology/output/state_dendrogram.png` |
| County zone map | `c:/Lichen/aposology/output/aposology_zone_map.png` |
| State zone map | `c:/Lichen/aposology/output/aposology_state_zones.png` |

## Next Steps

1. Examine county zone map and dendrogram for similar insights
2. Investigate sensitivity to k (number of clusters) — do the zones sharpen or fragment at k=6, 7?
3. Consider regional comparison approach as alternative framing
4. Explore whether the zonation changes substantially with different thresholds or different numbers of taxa per county
