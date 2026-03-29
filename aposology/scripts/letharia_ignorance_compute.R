#=========================================
# LETHARIA IGNORANCE MAP - DISTANCE COMPUTATION
# Distance from nearest Letharia record (10 km grid)
# Produces ignocenter_results.rds for plotting script
# 2026.03.11
# Alan + Claude
#=========================================

library(sf)
library(RSQLite)
library(DBI)

#=========================================
# CONFIG
#=========================================

db_path   <- "C:/Lichen/SQL/clh_2025_11.db"
grid_path <- "C:/Lichen/Grid_Analysis/data/grid_010km_counts.rds"
out_dir   <- "C:/Lichen/Letharia_aposology/data"
out_file  <- file.path(out_dir, "ignocenter_results.rds")

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

#=========================================
# STEP 1: EXTRACT LETHARIA RECORDS
#=========================================
cat("Connecting to database...\n")
con <- dbConnect(SQLite(), db_path)

sql <- "
SELECT id,
       CAST(COALESCE(decimalLatitudeEd,  decimalLatitude)  AS REAL) AS lat,
       CAST(COALESCE(decimalLongitudeEd, decimalLongitude) AS REAL) AS lon
FROM narrow
WHERE scientificName LIKE '%Letharia%'
  AND countryEd = 'United States'
  AND CAST(COALESCE(decimalLatitudeEd,  decimalLatitude)  AS REAL) IS NOT NULL
  AND CAST(COALESCE(decimalLongitudeEd, decimalLongitude) AS REAL) IS NOT NULL
"

cat("Querying Letharia records...\n")
leth <- dbGetQuery(con, sql)
dbDisconnect(con)
cat("  Records retrieved:", nrow(leth), "\n")

# Belt-and-suspenders: drop any remaining NAs or non-numeric
leth$lat <- as.numeric(leth$lat)
leth$lon <- as.numeric(leth$lon)
leth <- leth[!is.na(leth$lat) & !is.na(leth$lon), ]
cat("  Records after NA filter:", nrow(leth), "\n")

#=========================================
# STEP 2: LOAD GRID
#=========================================
cat("\nLoading 10km grid...\n")
grid <- readRDS(grid_path)
cat("  Total cells:", nrow(grid), "\n")
cat("  CRS:", st_crs(grid)$input, "\n")

#=========================================
# STEP 3: PROJECT LETHARIA POINTS TO GRID CRS
#=========================================
cat("\nProjecting Letharia points to grid CRS...\n")
leth_sf <- st_as_sf(leth, coords = c("lon", "lat"), crs = 4326)
leth_sf  <- st_transform(leth_sf, st_crs(grid))

#=========================================
# STEP 4: ASSIGN RECORDS TO GRID CELLS
#=========================================
cat("Joining Letharia points to grid cells...\n")
joined <- st_join(leth_sf, grid[, "cell_id"], join = st_within)
leth_cells <- unique(joined$cell_id)
leth_cells <- leth_cells[!is.na(leth_cells)]
cat("  Cells with Letharia:", length(leth_cells), "\n")

#=========================================
# STEP 5: SPLIT GRID INTO OCCUPIED / EMPTY
#=========================================
grid$letharia_present <- grid$cell_id %in% leth_cells

occupied <- grid[grid$letharia_present, ]
empty    <- grid[!grid$letharia_present, ]

cat("  Occupied cells:", nrow(occupied), "\n")
cat("  Empty cells:   ", nrow(empty), "\n")

#=========================================
# STEP 6: CALCULATE DISTANCES
# Chunked st_distance() - no extra dependencies
#=========================================
cat("Computing nearest-neighbor distances (chunked st_distance)...\n")
cat("  This may take a few minutes...\n")
t0 <- Sys.time()

occ_centroids_sf   <- st_centroid(occupied)
empty_centroids_sf <- st_centroid(empty)

# Process in chunks to keep memory manageable
chunk_size <- 2000
n_empty    <- nrow(empty_centroids_sf)
n_chunks   <- ceiling(n_empty / chunk_size)
min_dists  <- numeric(n_empty)

for (i in seq_len(n_chunks)) {
  idx_start <- (i - 1) * chunk_size + 1
  idx_end   <- min(i * chunk_size, n_empty)
  chunk     <- empty_centroids_sf[idx_start:idx_end, ]
  d         <- st_distance(chunk, occ_centroids_sf)
  min_dists[idx_start:idx_end] <- apply(d, 1, min)
  if (i %% 10 == 0)
    cat("  Chunk", i, "of", n_chunks, "\n")
}

elapsed <- round(difftime(Sys.time(), t0, units = "secs"), 1)
cat("  Done in", elapsed, "seconds.\n")

# Convert from meters to km
empty$dist_to_nearest_km <- as.numeric(min_dists) / 1000

cat("\nDistance summary (km):\n")
print(summary(empty$dist_to_nearest_km))

#=========================================
# STEP 7: FIND IGNOCENTER
# Cell with maximum distance to nearest Letharia record
#=========================================
cat("\nFinding ignocenter...\n")
max_idx   <- which.max(empty$dist_to_nearest_km)
igno_cell <- empty[max_idx, ]

# Back-transform to lat/lon for reporting
igno_ll     <- st_transform(st_centroid(igno_cell), 4326)
igno_latlon <- st_coordinates(igno_ll)

ignocenter <- list(
  lon                = igno_latlon[1, "X"],
  lat                = igno_latlon[1, "Y"],
  dist_to_nearest_km = igno_cell$dist_to_nearest_km
)

cat("  Ignocenter: (", round(ignocenter$lat, 4), ",",
    round(ignocenter$lon, 4), ")\n")
cat("  Maximum isolation:", round(ignocenter$dist_to_nearest_km, 1), "km\n")

#=========================================
# STEP 8: SAVE RESULTS
# Matching structure expected by plotting script
#=========================================
cat("\nSaving results to:", out_file, "\n")

results <- list(
  empty_land_with_distances = empty,
  ignocenter                = ignocenter
)

saveRDS(results, out_file)
cat("Done.\n")
