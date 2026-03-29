-- APOSOLOGY PIPELINE
-- Species-level records only, CONUS 48 states
-- Counties with >= 3000 species-level records
-- Top 10 taxa per county with state absence lists
-- 2026.02.07

WITH conus(st) AS (
  SELECT 'Alabama' UNION ALL SELECT 'Arizona' UNION ALL SELECT 'Arkansas' UNION ALL
  SELECT 'California' UNION ALL SELECT 'Colorado' UNION ALL SELECT 'Connecticut' UNION ALL
  SELECT 'Delaware' UNION ALL SELECT 'Florida' UNION ALL SELECT 'Georgia' UNION ALL
  SELECT 'Idaho' UNION ALL SELECT 'Illinois' UNION ALL SELECT 'Indiana' UNION ALL
  SELECT 'Iowa' UNION ALL SELECT 'Kansas' UNION ALL SELECT 'Kentucky' UNION ALL
  SELECT 'Louisiana' UNION ALL SELECT 'Maine' UNION ALL SELECT 'Maryland' UNION ALL
  SELECT 'Massachusetts' UNION ALL SELECT 'Michigan' UNION ALL SELECT 'Minnesota' UNION ALL
  SELECT 'Mississippi' UNION ALL SELECT 'Missouri' UNION ALL SELECT 'Montana' UNION ALL
  SELECT 'Nebraska' UNION ALL SELECT 'Nevada' UNION ALL SELECT 'New_Hampshire' UNION ALL
  SELECT 'New_Jersey' UNION ALL SELECT 'New_Mexico' UNION ALL SELECT 'New_York' UNION ALL
  SELECT 'North_Carolina' UNION ALL SELECT 'North_Dakota' UNION ALL SELECT 'Ohio' UNION ALL
  SELECT 'Oklahoma' UNION ALL SELECT 'Oregon' UNION ALL SELECT 'Pennsylvania' UNION ALL
  SELECT 'Rhode_Island' UNION ALL SELECT 'South_Carolina' UNION ALL SELECT 'South_Dakota' UNION ALL
  SELECT 'Tennessee' UNION ALL SELECT 'Texas' UNION ALL SELECT 'Utah' UNION ALL
  SELECT 'Vermont' UNION ALL SELECT 'Virginia' UNION ALL SELECT 'Washington' UNION ALL
  SELECT 'West_Virginia' UNION ALL SELECT 'Wisconsin' UNION ALL SELECT 'Wyoming'
),
species_records AS (
  SELECT *
  FROM narrow
  WHERE countryEd = 'United States'
    AND stateProvinceEd IN (SELECT st FROM conus)
    AND countyEd IS NOT NULL AND countyEd != ''
    AND scientificName LIKE '% %'
    AND LOWER(scientificName) NOT LIKE '% sp.'
    AND LOWER(scientificName) NOT LIKE '% indet.'
),
county_counts AS (
  SELECT stateProvinceEd, countyEd, COUNT(*) AS county_total
  FROM species_records
  GROUP BY stateProvinceEd, countyEd
  HAVING COUNT(*) >= 3000
),
taxon_counts AS (
  SELECT s.stateProvinceEd, s.countyEd, s.scientificName, COUNT(*) AS n
  FROM species_records s
  INNER JOIN county_counts cc
    ON s.stateProvinceEd = cc.stateProvinceEd AND s.countyEd = cc.countyEd
  GROUP BY s.stateProvinceEd, s.countyEd, s.scientificName
),
ranked AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY stateProvinceEd, countyEd ORDER BY n DESC) AS rk
  FROM taxon_counts
),
top_taxa AS (
  SELECT stateProvinceEd AS source_state, countyEd, scientificName, n AS county_n
  FROM ranked
  WHERE rk <= 10
),
taxon_state_presence AS (
  SELECT DISTINCT scientificName, stateProvinceEd
  FROM species_records
  WHERE scientificName IN (SELECT DISTINCT scientificName FROM top_taxa)
),
absent AS (
  SELECT t.source_state, t.countyEd, t.scientificName, t.county_n, c.st AS absent_state
  FROM top_taxa t
  CROSS JOIN conus c
  WHERE NOT EXISTS (
    SELECT 1 FROM taxon_state_presence p
    WHERE p.scientificName = t.scientificName AND p.stateProvinceEd = c.st
  )
)
SELECT source_state, countyEd, scientificName, county_n,
  48 - COUNT(absent_state) AS n_states_present,
  GROUP_CONCAT(absent_state, '; ') AS absent_from
FROM absent
GROUP BY source_state, countyEd, scientificName
ORDER BY source_state, countyEd, county_n DESC;
