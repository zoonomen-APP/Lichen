#=========================================
# LETHARIA IGNORANCE MAP - PLOTTING
# Distance from nearest Letharia record (10 km grid)
# 2026.03.11
# Alan + Claude
#=========================================

library(sf)
library(ggplot2)
library(tigris)
library(viridis)

options(tigris_use_cache = TRUE)

#=========================================
# CONFIG
#=========================================

data_file  <- "C:/Lichen/Letharia_aposology/data/ignocenter_results.rds"
output_dir <- "C:/Lichen/Letharia_aposology/output"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

#=========================================
# LOAD PRE-CALCULATED DISTANCES
#=========================================
cat("LETHARIA IGNORANCE MAP\n")
cat(rep("=", 50), "\n\n", sep = "")

cat("Loading ignocenter results...\n")
results <- readRDS(data_file)

empty_land <- results$empty_land_with_distances
ignocenter <- results$ignocenter

cat("Empty land cells with distances:", format(nrow(empty_land), big.mark = ","), "\n")
cat("Ignocenter: (", round(ignocenter$lat, 4), ", ",
    round(ignocenter$lon, 4), ")\n", sep = "")
cat("Maximum isolation: ", round(ignocenter$dist_to_nearest_km, 1), " km\n\n", sep = "")

#=========================================
# LOAD STATE BOUNDARIES
#=========================================
cat("Loading state boundaries...\n")
us_states   <- states(cb = TRUE)
conus_states <- us_states[!us_states$STUSPS %in%
                            c("AK", "HI", "PR", "VI", "GU", "MP", "AS"), ]
conus_states <- st_transform(conus_states, st_crs(empty_land))

#=========================================
# PREPARE CELL CENTROIDS FOR PLOTTING
#=========================================
cat("Preparing cell centroids...\n")
empty_centroids <- st_centroid(empty_land)
empty_coords    <- st_coordinates(empty_centroids)

empty_df <- data.frame(
  x      = empty_coords[, "X"],
  y      = empty_coords[, "Y"],
  dist_km = empty_land$dist_to_nearest_km
)
empty_df <- empty_df[!is.na(empty_df$dist_km), ]
cat("Cells with valid distances:", format(nrow(empty_df), big.mark = ","), "\n")

cat("\nDistance distribution:\n")
print(summary(empty_df$dist_km))

#=========================================
# IGNOCENTER POINT
#=========================================
ignocenter_sf <- st_sfc(
  st_point(c(ignocenter$lon, ignocenter$lat)), crs = 4326)
ignocenter_sf     <- st_transform(ignocenter_sf, st_crs(empty_land))
ignocenter_coords <- st_coordinates(ignocenter_sf)

#=========================================
# V1: CONTINUOUS COLOR SCALE
#=========================================
cat("\nCreating continuous version (v1)...\n")

p1 <- ggplot() +
  geom_sf(data = conus_states,
          fill = "white", color = "gray70", linewidth = 0.2) +
  geom_tile(data = empty_df,
            aes(x = x, y = y, fill = dist_km),
            width = 10000, height = 10000) +
  scale_fill_viridis(
    name      = "Distance to\nnearest Letharia (km)",
    option    = "inferno",
    direction = -1,
    limits    = c(0, 125),
    breaks    = seq(0, 120, by = 20)
  ) +
  geom_sf(data = conus_states,
          fill = NA, color = "gray40", linewidth = 0.3) +
  geom_point(aes(x = ignocenter_coords[1, "X"],
                 y = ignocenter_coords[1, "Y"]),
             shape = 23, size = 4, fill = "white",
             color = "black", stroke = 1.5) +
  labs(
    title    = "The Letharia Void: Topography of Absence",
    subtitle = "Distance from nearest Letharia record (10 km grid cells)"
  ) +
  theme_minimal() +
  theme(
    plot.title    = element_text(size = 18, face = "bold"),
    plot.subtitle = element_text(size = 12, color = "gray40"),
    axis.text     = element_blank(),
    axis.title    = element_blank(),
    panel.grid    = element_blank(),
    legend.position = "right",
    legend.title  = element_text(size = 10),
    legend.text   = element_text(size = 9)
  ) +
  coord_sf(crs = st_crs(empty_land))

ggsave(file.path(output_dir, "letharia_void_v1_continuous.png"),
       plot = p1, width = 14, height = 9, dpi = 300)
cat("  Saved v1 (continuous)\n")

#=========================================
# V2: DISCRETE COLOR BINS
#=========================================
cat("Creating discrete-bin version (v2)...\n")

empty_df$dist_bin <- cut(empty_df$dist_km,
                          breaks = c(0, 20, 40, 60, 80, 100, 120, Inf),
                          labels = c("0-20", "20-40", "40-60",
                                     "60-80", "80-100", "100-120", ">120"),
                          include.lowest = TRUE)

p2 <- ggplot() +
  geom_sf(data = conus_states,
          fill = "white", color = "gray70", linewidth = 0.2) +
  geom_tile(data = empty_df,
            aes(x = x, y = y, fill = dist_bin),
            width = 10000, height = 10000) +
  scale_fill_viridis_d(
    name      = "Distance to\nnearest Letharia (km)",
    option    = "inferno",
    direction = -1
  ) +
  geom_sf(data = conus_states,
          fill = NA, color = "gray40", linewidth = 0.3) +
  geom_point(aes(x = ignocenter_coords[1, "X"],
                 y = ignocenter_coords[1, "Y"]),
             shape = 23, size = 4, fill = "white",
             color = "black", stroke = 1.5) +
  labs(
    title    = "The Letharia Void: Topography of Absence",
    subtitle = "Distance from nearest Letharia record (10 km grid cells)"
  ) +
  theme_minimal() +
  theme(
    plot.title    = element_text(size = 18, face = "bold"),
    plot.subtitle = element_text(size = 12, color = "gray40"),
    axis.text     = element_blank(),
    axis.title    = element_blank(),
    panel.grid    = element_blank(),
    legend.position = "right",
    legend.title  = element_text(size = 10),
    legend.text   = element_text(size = 9)
  ) +
  coord_sf(crs = st_crs(empty_land))

ggsave(file.path(output_dir, "letharia_void_v2_discrete.png"),
       plot = p2, width = 14, height = 9, dpi = 300)
cat("  Saved v2 (discrete bins)\n")

cat("\nDone. Outputs in:", output_dir, "\n")
cat("\n\"Where nobody looked, the genus never was.\"\n")
