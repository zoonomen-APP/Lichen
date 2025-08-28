# Herbarium out-of-county-bounds Coordinate Outliers - Interactive Data Explorer

## Quick Start Guide

This repository lists records where the latitude longitude coordinates fall outside the county named for the location. 
They are grouped by herbarium and sorted by the distance from the designated point and the border of the listed county.. 
The analysis is restricted to records listing country as 'United States' (or some of the many variant 
renderings and misspellings thereof).



## How to Use This Data

### 1. Choose an Institution
Click on any active link below to view that herbarium's outlier records. Each dataset includes:
- Distance from coordinates to county boundary (km)
- Confidence level of county matching
- Direct links to online specimen records
- Implied locations based on coordinate reverse geocoding

### 2. Review the Data
Files are in tab-separated format (.tsv) that can be opened in:
- Excel or Google Sheets (for general viewing)
- R, Python, or other analysis tools (for deeper investigation)
- Any text editor (for quick inspection)

### 3. Interpret Results
- **Distance > 0**: Coordinates fall outside stated county
- **Larger distances**: More likely to represent data entry errors
- **Status codes**: Indicate matching confidence and potential issues

## Active Herbarium Datasets

### Currently Available
- [**OSC** - Oregon State University](./data/OSC/)
- [**SRP** - Boise State University Lichen Herbarium](./data/SRP/)
### Test Institutions (Limited Data)
- 

## Expanding Dataset (Commented Out - Activate as Needed)

```markdown
### Additional Herbaria
<!-- Uncomment lines below as data becomes available -->

<!-- - [**NY** - New York Botanical Garden](./data/NY/) - Large comprehensive collection -->
<!-- - [**MIN** - University of Minnesota](./data/MIN/) - Great Lakes region -->
<!-- - [**WIS** - University of Wisconsin](./data/WIS/) - Midwestern collection -->
<!-- - [**KANU** - University of Kansas](./data/KANU/) - Great Plains specimens -->

<!-- - [**DUKE** - Duke University](./data/DUKE/) - Southeastern US -->
<!-- - [**LSU** - Louisiana State University](./data/LSU/) - Gulf Coast region -->
<!-- - [**MSC** - Miami University](./data/MSC/) - Eastern deciduous forest -->

<!-- - [**CAS** - California Academy of Sciences](./data/CAS/) - Pacific Coast -->
<!-- - [**UWSP** - University of Wisconsin Stevens Point](./data/UWSP/) - Northern forests -->
<!-- - [**GAM** - Gamma Herbarium](./data/GAM/) - Specialized lichen collection -->
```

## Data Structure

Each herbarium folder contains state-specific files:
```
data/INSTITUTION_CODE/
├── INST_Arizona_out_of_bounds_20240823_143022.tsv
├── INST_California_out_of_bounds_20240823_143045.tsv
└── INST_Texas_out_of_bounds_20240823_143102.tsv
```

## Key Fields in Data Files

| Field | Description |
|-------|-------------|
| `occurrenceID` | Unique specimen identifier |
| `institutionCode` | Herbarium code |
| `stateProvince` | Recorded state |
| `county` | Recorded county name |
| `distance_km` | Distance to county boundary |
| `status` | Confidence level in matching county name|
| `coordinates` | GPS coordinates (lat,lon) |
| `implied_location` | Location from coordinate lookup |
| `references` | Direct "clickable" link to online record |


## Technical Notes

### Analysis Methodology
- Based on US Census TIGER/Line county boundaries
- Uses liberal county name matching to minimize false positives  
- Calculates shortest distance to boundary edges
- Provides confidence scores for uncertain matches

### Data Freshness
- Analysis reflects database state at time of processing
- Timestamps in filenames indicate processing date
- Periodic re-analysis planned for active collections

### Limitations
- US specimens only (requires Census boundary data)
- County boundaries reflect current political divisions
- Historical collection locations may have different county assignments
- Distance calculations are approximate (suitable for error detection, not precise surveying)

---

## Data Quality Considerations and Limitations

### Coordinate Datum Assumptions
This analysis assumes all latitude/longitude coordinates use the WGS84 datum. However, this assumption is maybe incorrect, particularly for older specimen records. 
Historical collections used previous geodetic datums (such as NAD27 or local survey datums), and coordinate values may not have been converted when digitized.
Additionally it appears possible that some WGS84 values may have been "converted" based on the false assumption that they were NOT WGS84, although they actually were.

**Impact on Results**: Small boundary violations (< 5km) may represent datum conversion errors rather than true coordinate mistakes. 
Records originally collected using older datums could appear as false positives when tested against modern WGS84-based county boundaries.

### Sources of Geographic Errors include, but are not limited to
Coordinate and location errors originate from multiple sources throughout the specimen lifecycle:
- **Field collection**: GPS device errors, waypoint confusion, transcription mistakes, uncertainty regarding state and county boundaries.
	Some records include errors intentionally introduced in locality data to mask the actual location.
- **Label preparation**: Handwriting interpretation, abbreviation ambiguity
- **Digitization**: Data entry errors, optical character recognition failures
- **Database management**: Import/export conversions, field mapping errors

**Important Note**: Geographic errors are made by collectors and data managers at all experience levels, from student assistants to senior researchers. 
The goal should always be error correction, not assigning blame.

### Precision vs. Accuracy Paradox
Modern databases frequently contain coordinates with extreme precision (8+ decimal places, theoretically accurate to centimeters) but poor accuracy (coordinates in wrong hemispheres or continents). This reflects the ease of copying high-precision numbers without validating their accuracy.

**Example**: A record might show coordinates precise to "a few Angstroms" (as you noted) while being inaccurate at the hemisphere level—demonstrating that decimal precision does not guarantee geographic accuracy.

### Error Classification
- **True positives**: Genuine coordinate-county mismatches requiring correction
- **False positives**: Correct coordinates flagged due to datum issues or boundary changes
- **False negatives**: Incorrect coordinates that happen to fall within stated counties
- **Undetected errors**: Problems in records lacking sufficient geographic data for validation

---

## Quick Links for Common Tasks

- **Find worst outliers**: Sort by `distance_km` descending
- **Check specific collector**: Filter by `recordedBy` field
- **View online records**: Click URLs in `references` column
- **Compare locations**: Cross-reference `county` vs `implied_location`

