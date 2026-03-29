################################################################################
# county_coverage.R
# 
# How many US counties (excluding Alaska) have no lichen records in the CLH?
# exclusion of Hawaii added. 2026.03.15
#
# METHOD:
#   1. Canonical county list from tigris (CONUS + Hawaii, excl. Alaska)
#   2. Distinct stateProvinceEd + countyEd pairs from CLH narrow (US only)
#   3. Normalize both sides, then fuzzy-match within state
#   4. Classify each canonical county:
#        "clh_present"   -- matched to >=1 CLH record
#        "clh_absent"    -- matched, zero CLH records
#        "match_uncertain" -- fuzzy match below confidence threshold
#   5. Report summary + write CSVs for inspection
#
# IMPORTANT CAVEAT (make explicit):
#   Zero CLH records != zero lichen collections. A county may have
#   collections sitting in herbaria not yet contributing to CLH, or
#   collections that predate databasing. This analysis measures CLH
#   coverage, not lichen presence/absence.
#
# OUTPUTS:
#   county_coverage_summary.txt   -- headline counts
#   county_clh_absent.csv         -- counties with no CLH records
#   county_match_uncertain.csv    -- counties where match was ambiguous
#   county_coverage_full.csv      -- full table for inspection
#
# DEPENDENCIES:
#   tigris, dplyr, stringdist, DBI, RSQLite
#
# 2026.03.15
################################################################################

library(tigris)
library(dplyr)
library(stringdist)
library(DBI)
library(RSQLite)

options(tigris_use_cache = TRUE)

db_path   <- "c:/Lichen/SQL/clh_2025_11.db"
out_dir   <- "C:/Lichen/Letharia_aposology/output/"

# Jaro-Winkler distance threshold for a confident match
# 0 = identical, 1 = completely different
# 0.10 means strings are very similar -- tune if needed
JW_THRESHOLD <- 0.10


#==============================================================================
# STEP 1: CANONICAL COUNTY LIST FROM TIGRIS
#==============================================================================
cat("Loading canonical county list from tigris...\n")

# cb = TRUE uses smaller cartographic boundary files (faster, no geometry needed)
counties_raw <- counties(cb = TRUE, resolution = "20m", year = 2022)

# Exclude Alaska (FIPS 02) and territories
# Include all 48 contiguous + Hawaii (FIPS 15) + DC (FIPS 11)
counties_canon <- counties_raw %>%
  filter(!STATEFP %in% c("02",        # Alaska
                          "15",        # Hawaii
                          "60",        # American Samoa
                          "66",        # Guam
                          "69",        # Northern Mariana Islands
                          "72",        # Puerto Rico
                          "78")) %>%   # US Virgin Islands
  as.data.frame() %>%
  select(STATEFP, COUNTYFP, GEOID, NAME, NAMELSAD, STATE_NAME) %>%
  mutate(
    # Normalized county name for matching: lowercase, remove punctuation,
    # strip trailing " county", " parish", " borough", " census area" etc.
    county_norm = NAME %>%
      tolower() %>%
      gsub("[[:punct:]]", "", .) %>%
      gsub("\\s+", " ", .) %>%
      trimws(),
    state_norm = STATE_NAME %>%
      tolower() %>%
      trimws()
  )

cat("  Canonical counties loaded:", nrow(counties_canon), "\n")
cat("  States represented:", n_distinct(counties_canon$STATE_NAME), "\n")


#==============================================================================
# STEP 2: CLH COUNTY PAIRS
#==============================================================================
cat("\nQuerying CLH for distinct state/county pairs (US only)...\n")

con <- dbConnect(SQLite(), db_path)

sql <- "
SELECT DISTINCT
  stateProvinceEd,
  countyEd
FROM narrow
WHERE countryEd = 'United States'
  AND countyEd IS NOT NULL
  AND countyEd != ''
ORDER BY stateProvinceEd, countyEd
"

clh_pairs <- dbGetQuery(con, sql)
dbDisconnect(con)

cat("  Distinct state/county pairs in CLH:", nrow(clh_pairs), "\n")

# Normalize CLH county names for matching
# CLH format is typically "Missoula_Co." -- strip underscores, " Co.", " County" etc.
normalize_county <- function(x) {
  x %>%
    tolower() %>%
    gsub("_", " ", .) %>%          # underscore to space
    gsub("[[:punct:]]", "", .) %>% # remove punctuation
    gsub("\\bcounty\\b", "", .) %>%
    gsub("\\bco\\b", "", .) %>%
    gsub("\\bparish\\b", "", .) %>%
    gsub("\\bborough\\b", "", .) %>%
    gsub("\\bcensus area\\b", "", .) %>%
    gsub("\\s+", " ", .) %>%
    trimws()
}

normalize_state <- function(x) {
  x %>%
    tolower() %>%
    gsub("_", " ", .) %>%
    trimws()
}

clh_pairs <- clh_pairs %>%
  mutate(
    county_norm = normalize_county(countyEd),
    state_norm  = normalize_state(stateProvinceEd)
  )

# Also normalize the canonical county names the same way
counties_canon <- counties_canon %>%
  mutate(county_norm = normalize_county(county_norm))


#==============================================================================
# STEP 3: FUZZY MATCH WITHIN STATE
#==============================================================================
cat("\nFuzzy matching CLH counties to canonical list...\n")
cat("  Jaro-Winkler threshold:", JW_THRESHOLD, "\n")

# Build a lookup: for each canonical county, find best CLH match within state
# Strategy: group canonical counties by state, match CLH pairs within state

# Get unique state names from both sides for state matching
# First match CLH state names to canonical state names
canon_states <- counties_canon %>%
  select(state_norm, STATE_NAME, STATEFP) %>%
  distinct()

clh_states <- clh_pairs %>%
  select(stateProvinceEd, state_norm) %>%
  distinct()

# Match CLH state names to canonical state names
cat("  Matching state names...\n")

clh_states$canon_state_norm <- NA_character_
clh_states$state_jw <- NA_real_

for (i in seq_len(nrow(clh_states))) {
  dists <- stringdist(clh_states$state_norm[i],
                      canon_states$state_norm,
                      method = "jw")
  best  <- which.min(dists)
  clh_states$canon_state_norm[i] <- canon_states$state_norm[best]
  clh_states$state_jw[i]         <- dists[best]
}

# Flag poor state matches
poor_state_matches <- clh_states %>% filter(state_jw > 0.05)
if (nrow(poor_state_matches) > 0) {
  cat("  WARNING: poor state matches (jw > 0.05):\n")
  print(poor_state_matches)
}

# Join canonical state back to CLH pairs
clh_pairs <- clh_pairs %>%
  left_join(clh_states %>%
              select(state_norm, canon_state_norm, state_jw),
            by = "state_norm")


#==============================================================================
# STEP 4: MATCH EACH CANONICAL COUNTY TO CLH
#==============================================================================
cat("\nMatching canonical counties to CLH records...\n")

# For each canonical county, find the best matching CLH county within same state
results <- counties_canon %>%
  mutate(
    best_clh_county  = NA_character_,
    best_clh_county_raw = NA_character_,
    best_jw          = NA_real_,
    match_status     = NA_character_
  )

# Get CLH pairs grouped by matched canonical state
clh_by_state <- clh_pairs %>%
  filter(!is.na(canon_state_norm)) %>%
  group_by(canon_state_norm) %>%
  group_split()

clh_state_keys <- clh_pairs %>%
  filter(!is.na(canon_state_norm)) %>%
  pull(canon_state_norm) %>%
  unique()

names(clh_by_state) <- sapply(clh_by_state, function(x) x$canon_state_norm[1])

n_total <- nrow(results)
cat("  Processing", n_total, "canonical counties...\n")

for (i in seq_len(nrow(results))) {
  s <- results$state_norm[i]
  c <- results$county_norm[i]

  # Get CLH counties for this state
  if (!s %in% names(clh_by_state)) {
    results$match_status[i] <- "clh_absent"
    next
  }

  state_clh <- clh_by_state[[s]]

  if (nrow(state_clh) == 0) {
    results$match_status[i] <- "clh_absent"
    next
  }

  # Fuzzy match county name within state
  dists <- stringdist(c, state_clh$county_norm, method = "jw")
  best  <- which.min(dists)
  best_dist <- dists[best]

  results$best_clh_county[i]     <- state_clh$county_norm[best]
  results$best_clh_county_raw[i] <- state_clh$countyEd[best]
  results$best_jw[i]             <- best_dist

  if (best_dist <= JW_THRESHOLD) {
    results$match_status[i] <- "clh_present"
  } else {
    results$match_status[i] <- "match_uncertain"
  }

  if (i %% 500 == 0) cat("  ...", i, "of", n_total, "\n")
}

cat("  Done.\n")


#==============================================================================
# STEP 5: SUMMARY AND OUTPUT
#==============================================================================
cat("\n========================================\n")
cat("COUNTY COVERAGE SUMMARY\n")
cat("========================================\n")

summary_counts <- results %>%
  count(match_status) %>%
  arrange(match_status)

total_canon <- nrow(results)
n_present   <- sum(results$match_status == "clh_present",   na.rm = TRUE)
n_absent    <- sum(results$match_status == "clh_absent",    na.rm = TRUE)
n_uncertain <- sum(results$match_status == "match_uncertain", na.rm = TRUE)

cat("Total canonical counties (excl. Alaska + territories):", total_canon, "\n")
cat("  CLH present (>=1 record matched):  ", n_present,
    sprintf("(%.1f%%)", 100 * n_present / total_canon), "\n")
cat("  CLH absent (no match found):       ", n_absent,
    sprintf("(%.1f%%)", 100 * n_absent / total_canon), "\n")
cat("  Match uncertain (review needed):   ", n_uncertain,
    sprintf("(%.1f%%)", 100 * n_uncertain / total_canon), "\n")

cat("\n")
cat("IMPORTANT CAVEAT:\n")
cat("  Zero CLH records does not equal zero lichen collections.\n")
cat("  Counties classed as 'absent' may have:\n")
cat("    - Collections in herbaria not contributing to CLH\n")
cat("    - Collections predating databasing efforts\n")
cat("    - Records in CLH under unmatched county name variants\n")
cat("  This analysis measures CLH database coverage, not lichen\n")
cat("  presence or absence in the landscape.\n")
cat("========================================\n")

# Write summary to file
summary_text <- capture.output({
  cat("COUNTY COVERAGE SUMMARY\n")
  cat("Generated:", format(Sys.time(), "%Y.%m.%d %H:%M"), "\n")
  cat("Database: clh_2025_11.db, table: narrow\n")
  cat("Canonical source: tigris counties(), year=2022, excl. Alaska + territories\n")
  cat("Jaro-Winkler threshold:", JW_THRESHOLD, "\n\n")
  cat("Total canonical counties:", total_canon, "\n")
  cat("  CLH present:    ", n_present,
      sprintf("(%.1f%%)", 100 * n_present / total_canon), "\n")
  cat("  CLH absent:     ", n_absent,
      sprintf("(%.1f%%)", 100 * n_absent / total_canon), "\n")
  cat("  Match uncertain:", n_uncertain,
      sprintf("(%.1f%%)", 100 * n_uncertain / total_canon), "\n\n")
  cat("CAVEAT: Zero CLH records != zero lichen collections.\n")
  cat("Counties classed as absent may have collections in herbaria\n")
  cat("not contributing to CLH, or records under unmatched name variants.\n")
  cat("This measures CLH database coverage, not lichen presence/absence.\n")
})
writeLines(summary_text,
           file.path(out_dir, "county_coverage_summary.txt"))

# Write full table
write.csv(results,
          file.path(out_dir, "county_coverage_full.csv"),
          row.names = FALSE)

# Write absent counties
absent <- results %>%
  filter(match_status == "clh_absent") %>%
  select(STATE_NAME, NAME, NAMELSAD, GEOID, county_norm) %>%
  arrange(STATE_NAME, NAME)

write.csv(absent,
          file.path(out_dir, "county_clh_absent.csv"),
          row.names = FALSE)

# Write uncertain matches for manual review
uncertain <- results %>%
  filter(match_status == "match_uncertain") %>%
  select(STATE_NAME, NAME, county_norm,
         best_clh_county, best_clh_county_raw, best_jw) %>%
  arrange(best_jw)

write.csv(uncertain,
          file.path(out_dir, "county_match_uncertain.csv"),
          row.names = FALSE)

cat("\nOutputs written to:", out_dir, "\n")
cat("  county_coverage_summary.txt\n")
cat("  county_coverage_full.csv\n")
cat("  county_clh_absent.csv\n")
cat("  county_match_uncertain.csv\n")
