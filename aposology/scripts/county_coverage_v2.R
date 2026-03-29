################################################################################
# county_coverage.R  (v2)
#
# How many US counties (CONUS + DC, excl. Alaska + Hawaii + territories)
# have any lichen records in the CLH (narrow table)?
#
# CRITICAL DESIGN PRINCIPLE:
#   County names are ONLY meaningful within a confirmed state context.
#   "Washington Co." exists in 31 states. Fuzzy county matching MUST be
#   anchored to a strict state match first. State matching uses an explicit
#   lookup table -- NOT fuzzy logic -- because state orthography in the CLH
#   uses underscores and abbreviations that must be resolved unambiguously
#   before county-level comparison is attempted.
#
#   The hierarchy is mandatory: country -> state -> county.
#   Each level must be independently validated before the next level
#   is meaningful.
#
# METHOD:
#   1. Canonical county list from tigris (CONUS + DC, excl. AK, HI, territories)
#   2. Explicit CLH state name -> canonical state lookup table
#   3. Distinct stateProvinceEd + countyEd pairs from CLH narrow (US only)
#   4. Join CLH pairs to canonical state via lookup table (strict, no fuzzy)
#   5. Within confirmed state, fuzzy-match county names (Jaro-Winkler)
#   6. Classify each canonical county:
#        "clh_present"     -- matched to >=1 CLH record
#        "clh_absent"      -- no CLH record found in this county
#        "match_uncertain" -- best fuzzy match below confidence threshold
#        "state_unmatched" -- CLH state name not in lookup table (needs review)
#   7. Report summary + write TSVs for inspection
#
# IMPORTANT CAVEAT:
#   Zero CLH records != zero lichen collections. A county classed as absent
#   may have collections in herbaria not contributing to CLH, collections
#   predating databasing, or records under unmatched county name variants.
#   This analysis measures CLH database coverage, not lichen presence/absence
#   in the landscape.
#
# OUTPUTS (all TSV, no CSV):
#   county_coverage_summary.txt     -- headline counts
#   county_clh_absent.tsv           -- counties with no CLH records
#   county_match_uncertain.tsv      -- counties where match was ambiguous
#   county_state_unmatched.tsv      -- CLH state names not in lookup
#   county_coverage_full.tsv        -- full table for inspection
#
# DEPENDENCIES: tigris, dplyr, stringdist, DBI, RSQLite
#
# 2026.03.15
################################################################################

library(tigris)
library(dplyr)
library(stringdist)
library(DBI)
library(RSQLite)

options(tigris_use_cache = TRUE)

db_path <- "c:/Lichen/SQL/clh_2025_11.db"
out_dir <- "C:/Lichen/Letharia_aposology/output/"

# Jaro-Winkler threshold for county name match
# 0 = identical, 1 = completely different; 0.12 is fairly strict
JW_THRESHOLD <- 0.12


#==============================================================================
# STEP 1: EXPLICIT STATE LOOKUP TABLE
#
# Maps CLH stateProvinceEd values (with underscores) to canonical state names
# as used by tigris. This is the critical anchor -- no fuzzy logic here.
# Add rows as needed when state_unmatched output reveals gaps.
#==============================================================================

state_lookup <- data.frame(
  clh_state = c(
    "Alabama", "Arizona", "Arkansas", "California", "Colorado",
    "Connecticut", "Delaware", "District_of_Columbia", "Florida", "Georgia",
    "Idaho", "Illinois", "Indiana", "Iowa", "Kansas",
    "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts",
    "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana",
    "Nebraska", "Nevada", "New_Hampshire", "New_Jersey", "New_Mexico",
    "New_York", "North_Carolina", "North_Dakota", "Ohio", "Oklahoma",
    "Oregon", "Pennsylvania", "Rhode_Island", "South_Carolina", "South_Dakota",
    "Tennessee", "Texas", "Utah", "Vermont", "Virginia",
    "Washington", "West_Virginia", "Wisconsin", "Wyoming",
    # Common variants that may appear in CLH
    "District of Columbia", "North Carolina", "South Carolina",
    "New Hampshire", "New Jersey", "New Mexico", "New York",
    "North Dakota", "South Dakota", "West Virginia", "Rhode Island"
  ),
  canon_state = c(
    "Alabama", "Arizona", "Arkansas", "California", "Colorado",
    "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia",
    "Idaho", "Illinois", "Indiana", "Iowa", "Kansas",
    "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts",
    "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana",
    "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico",
    "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma",
    "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota",
    "Tennessee", "Texas", "Utah", "Vermont", "Virginia",
    "Washington", "West Virginia", "Wisconsin", "Wyoming",
    # Canonical forms for the variants above
    "District of Columbia", "North Carolina", "South Carolina",
    "New Hampshire", "New Jersey", "New Mexico", "New York",
    "North Dakota", "South Dakota", "West Virginia", "Rhode Island"
  ),
  stringsAsFactors = FALSE
)


#==============================================================================
# STEP 2: CANONICAL COUNTY LIST FROM TIGRIS
#==============================================================================
cat("Loading canonical county list from tigris...\n")

counties_raw <- counties(cb = TRUE, resolution = "20m", year = 2022)

counties_canon <- counties_raw %>%
  filter(!STATEFP %in% c(
    "02",   # Alaska
    "15",   # Hawaii
    "60",   # American Samoa
    "66",   # Guam
    "69",   # Northern Mariana Islands
    "72",   # Puerto Rico
    "78"    # US Virgin Islands
  )) %>%
  as.data.frame() %>%
  select(STATEFP, COUNTYFP, GEOID, NAME, NAMELSAD, STATE_NAME) %>%
  mutate(
    county_norm = NAME %>%
      tolower() %>%
      gsub("[[:punct:]]", "", .) %>%
      gsub("\\s+", " ", .) %>%
      trimws()
  )

cat("  Canonical counties:", nrow(counties_canon), "\n")
cat("  States/DC:", n_distinct(counties_canon$STATE_NAME), "\n")


#==============================================================================
# STEP 3: CLH COUNTY PAIRS
#==============================================================================
cat("\nQuerying CLH for distinct state/county pairs (US only)...\n")

con <- dbConnect(SQLite(), db_path)

sql <- "
SELECT DISTINCT
  stateProvinceEd,
  countyEd
FROM narrow
WHERE countryEd = 'United States'
  AND countyEd  IS NOT NULL
  AND countyEd  != ''
  AND stateProvinceEd IS NOT NULL
  AND stateProvinceEd != ''
ORDER BY stateProvinceEd, countyEd
"

clh_pairs <- dbGetQuery(con, sql)
dbDisconnect(con)

cat("  Distinct state/county pairs:", nrow(clh_pairs), "\n")

# Normalize county names: underscore -> space, strip "Co.", punctuation
normalize_county <- function(x) {
  x %>%
    tolower() %>%
    gsub("_", " ", .) %>%
    gsub("[[:punct:]]", "", .) %>%
    gsub("\\bcounty\\b", "", .) %>%
    gsub("\\bco\\b",     "", .) %>%
    gsub("\\bparish\\b", "", .) %>%
    gsub("\\bborough\\b","", .) %>%
    gsub("\\s+", " ", .) %>%
    trimws()
}

clh_pairs <- clh_pairs %>%
  mutate(county_norm = normalize_county(countyEd))

# Strict state join via lookup table
clh_pairs <- clh_pairs %>%
  left_join(state_lookup, by = c("stateProvinceEd" = "clh_state"))

n_unmatched_state <- sum(is.na(clh_pairs$canon_state))
cat("  CLH pairs with unmatched state name:", n_unmatched_state, "\n")
if (n_unmatched_state > 0) {
  cat("  (see county_state_unmatched.tsv for details)\n")
}

# Split CLH pairs by canonical state for efficient lookup
clh_matched <- clh_pairs %>% filter(!is.na(canon_state))
clh_by_state <- split(clh_matched, clh_matched$canon_state)


#==============================================================================
# STEP 4: MATCH EACH CANONICAL COUNTY TO CLH
#==============================================================================
cat("\nMatching canonical counties to CLH...\n")
cat("  Jaro-Winkler threshold:", JW_THRESHOLD, "\n")

results <- counties_canon %>%
  mutate(
    best_clh_county_norm = NA_character_,
    best_clh_county_raw  = NA_character_,
    best_jw              = NA_real_,
    match_status         = NA_character_
  )

n_total <- nrow(results)

for (i in seq_len(n_total)) {
  s <- results$STATE_NAME[i]
  c <- results$county_norm[i]

  state_clh <- clh_by_state[[s]]

  if (is.null(state_clh) || nrow(state_clh) == 0) {
    results$match_status[i] <- "clh_absent"
    next
  }

  dists <- stringdist(c, state_clh$county_norm, method = "jw")
  best  <- which.min(dists)
  best_dist <- dists[best]

  results$best_clh_county_norm[i] <- state_clh$county_norm[best]
  results$best_clh_county_raw[i]  <- state_clh$countyEd[best]
  results$best_jw[i]              <- best_dist

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
cat("CLH COUNTY COVERAGE SUMMARY\n")
cat("========================================\n")

total   <- nrow(results)
present <- sum(results$match_status == "clh_present",     na.rm = TRUE)
absent  <- sum(results$match_status == "clh_absent",      na.rm = TRUE)
uncert  <- sum(results$match_status == "match_uncertain",  na.rm = TRUE)

pct <- function(n) sprintf("%.1f%%", 100 * n / total)

cat("Canonical counties (CONUS + DC, excl. AK + HI):", total, "\n")
cat("  CLH present:     ", present, "(", pct(present), ")\n")
cat("  CLH absent:      ", absent,  "(", pct(absent),  ")\n")
cat("  Match uncertain: ", uncert,  "(", pct(uncert),  ")\n")
cat("\n")
cat("CAVEAT: CLH absent != no collections exist.\n")
cat("  Absent counties may have herbarium collections not yet\n")
cat("  contributing to CLH, or records under unmatched name variants.\n")
cat("  This measures CLH database coverage only.\n")
cat("========================================\n")

# Helper: write TSV
write_tsv <- function(df, path) {
  write.table(df, path, sep = "\t", row.names = FALSE, quote = FALSE)
}

# Summary text file
summary_lines <- c(
  "CLH COUNTY COVERAGE SUMMARY",
  paste("Generated:", format(Sys.time(), "%Y.%m.%d %H:%M")),
  paste("Database:  clh_2025_11.db, table: narrow"),
  paste("Reference: tigris counties(), year=2022, CONUS + DC, excl. AK + HI"),
  paste("JW threshold:", JW_THRESHOLD),
  "",
  paste("Canonical counties:", total),
  paste("  CLH present:    ", present, "(", pct(present), ")"),
  paste("  CLH absent:     ", absent,  "(", pct(absent),  ")"),
  paste("  Match uncertain:", uncert,  "(", pct(uncert),  ")"),
  "",
  "CAVEAT: CLH absent != no collections exist.",
  "  Counties classed as absent may have collections in herbaria",
  "  not contributing to CLH, or records under unmatched name variants.",
  "  This measures CLH database coverage, not lichen presence/absence."
)
writeLines(summary_lines,
           file.path(out_dir, "county_coverage_summary.txt"))

# Full table
write_tsv(results,
          file.path(out_dir, "county_coverage_full.tsv"))

# Absent counties
absent_df <- results %>%
  filter(match_status == "clh_absent") %>%
  select(STATE_NAME, NAME, NAMELSAD, GEOID) %>%
  arrange(STATE_NAME, NAME)
write_tsv(absent_df,
          file.path(out_dir, "county_clh_absent.tsv"))

# Uncertain matches -- sorted by JW distance for easy review
uncert_df <- results %>%
  filter(match_status == "match_uncertain") %>%
  select(STATE_NAME, NAME, county_norm,
         best_clh_county_norm, best_clh_county_raw, best_jw) %>%
  arrange(best_jw)
write_tsv(uncert_df,
          file.path(out_dir, "county_match_uncertain.tsv"))

# Unmatched state names -- for lookup table expansion
if (n_unmatched_state > 0) {
  unmatched_states <- clh_pairs %>%
    filter(is.na(canon_state)) %>%
    count(stateProvinceEd, sort = TRUE)
  write_tsv(unmatched_states,
            file.path(out_dir, "county_state_unmatched.tsv"))
}

cat("\nOutputs written to", out_dir, "\n")
cat("  county_coverage_summary.txt\n")
cat("  county_coverage_full.tsv\n")
cat("  county_clh_absent.tsv\n")
cat("  county_match_uncertain.tsv\n")
if (n_unmatched_state > 0)
  cat("  county_state_unmatched.tsv  <-- review and expand lookup table\n")
