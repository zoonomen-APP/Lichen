## letharia_species_dataprep.r
## 2026.03.28
##
## Query CLH database for L. columbiana and L. vulpina records in WA/OR,
## assign dggridR res=11 hex IDs, compute per-species per-hex counts,
## save as RDS for use by letharia_species_explore.r.
##
## Joins: narrow (names) + conus_coords (coordinates) on id
## Filters: stateProvinceEd IN ('Washington', 'Oregon')
##          scientificNameRegularized IN target species
##
## Output: C:/Lichen/comp_biogeography/output/letharia_species_WAOR.rds
##
## Alan / Claude  2026.03.28

library(RSQLite)
library(dggridR)

## ---- CONFIG ----------------------------------------------------------------

db_path   <- "C:/Lichen/SQL/clh_2025_11.db"
out_dir   <- "C:/Lichen/comp_biogeography/output"
out_rds   <- file.path(out_dir, "letharia_species_WAOR.rds")
HEX_RES   <- 11

TARGET_SPECIES <- c("Letharia columbiana", "Letharia vulpina")
TARGET_STATES  <- c("Washington", "Oregon")

## ---- QUERY -----------------------------------------------------------------

cat("========================================\n")
cat("Letharia Species Data Prep -- WA/OR\n")
cat("========================================\n\n")

cat("Connecting to database...\n")
con <- dbConnect(SQLite(), db_path)

sql <- sprintf("
  SELECT
    n.scientificNameRegularized AS taxon,
    c.decimalLatitude           AS lat,
    c.decimalLongitude          AS lon,
    c.stateProvinceEd           AS state
  FROM narrow n
  JOIN conus_coords c ON n.id = c.id
  WHERE n.scientificNameRegularized IN (%s)
    AND c.stateProvinceEd           IN (%s)
    AND c.decimalLatitude  IS NOT NULL
    AND c.decimalLongitude IS NOT NULL
",
  paste(sprintf("'%s'", TARGET_SPECIES), collapse = ", "),
  paste(sprintf("'%s'", TARGET_STATES),  collapse = ", ")
)

cat("Querying...\n")
recs <- dbGetQuery(con, sql)
dbDisconnect(con)

cat("  Records returned:", nrow(recs), "\n")
cat("  By species:\n")
print(table(recs$taxon))
cat("\n")

if (nrow(recs) == 0) {
  stop("No records returned -- check species names and state filter.")
}

## ---- HEX ASSIGNMENT --------------------------------------------------------

cat("Assigning hex IDs (res =", HEX_RES, ")...\n")

dggs <- dgconstruct(projection = "ISEA", aperture = 3,
                    topology = "HEXAGON", res = HEX_RES)

recs$hex_id <- dgGEO_to_SEQNUM(dggs,
                                in_lon_deg = recs$lon,
                                in_lat_deg = recs$lat)$seqnum

cat("  Hex assignment complete\n")
cat("  Unique hexes occupied:", length(unique(recs$hex_id)), "\n\n")

## ---- COUNT PER SPECIES PER HEX ---------------------------------------------

cat("Computing per-species per-hex counts...\n")

counts <- aggregate(lat ~ taxon + hex_id,
                    data = recs, FUN = length)
names(counts)[3] <- "n_specimens"
counts$log_n <- log10(counts$n_specimens + 1)

## Split by species for convenience
sp_list <- split(counts, counts$taxon)

cat("  Per-species hex counts:\n")
for (sp in names(sp_list)) {
  cat(sprintf("    %-25s  %d hexes  %d total specimens\n",
              sp,
              nrow(sp_list[[sp]]),
              sum(sp_list[[sp]]$n_specimens)))
}
cat("\n")

## ---- SAVE ------------------------------------------------------------------

cat("Saving RDS...\n")

result <- list(
  counts     = counts,     ## all species combined: taxon, hex_id, n_specimens, log_n
  sp_list    = sp_list,    ## named list, one df per species
  meta = list(
    species        = TARGET_SPECIES,
    states         = TARGET_STATES,
    hex_res        = HEX_RES,
    n_total        = nrow(recs),
    created        = Sys.time()
  )
)

saveRDS(result, out_rds)
cat("  Saved:", out_rds, "\n\n")

cat("========================================\n")
cat("Done.\n")
cat("========================================\n")
