#=========================================
# THE LETHARIA VOID: DISTANCE FROM THE KNOWN
# Western states plot
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

# Western states to include
west_states <- c("Washington", "Oregon", "California", "Idaho", "Montana",
                 "Wyoming", "Utah", "Colorado", "Nevada", "Arizona",
                 "New Mexico")

#=========================================
# LOAD PRE-CALCULATED DISTANCES
#=========================================
cat("THE LETHARIA VOID: DISTANCE FROM THE KNOWN\n")
cat(rep("=", 50), "\n\n", sep = "")

cat("Loading results...\n")
results    <- readRDS(data_file)
empty_land <- results$empty_land_with_distances
ignocenter <- results$ignocenter

cat("Empty cells with distances:", format(nrow(empty_land), big.mark = ","), "\n")
cat("Ignocenter (CONUS): (", round(ignocenter$lat, 4), ",",
    round(ignocenter$lon, 4), ")\n")
cat("Maximum isolation:", round(ignocenter$dist_to_nearest_km, 1), "km\n\n")

#=========================================
# LOAD AND FILTER STATE BOUNDARIES
#=========================================
cat("Loading state boundaries...\n")
us_states    <- states(cb = TRUE)
all_conus    <- us_states[!us_states$STUSPS %in%
                           c("AK", "HI", "PR", "VI", "GU", "MP", "AS"), ]
west_sf      <- us_states[us_states$NAME %in% west_states, ]

all_conus <- st_transform(all_conus, st_crs(empty_land))
west_sf   <- st_transform(west_sf,   st_crs(empty_land))

#=========================================
# CLIP EMPTY CELLS TO WESTERN STATES
#=========================================
cat("Clipping to western states...\n")
west_union  <- st_union(west_sf)
empty_west  <- empty_land[st_intersects(empty_land, west_union,
                                         sparse = FALSE)[, 1], ]
cat("  Empty western cells:", format(nrow(empty_west), big.mark = ","), "\n")

#=========================================
# FIND WESTERN IGNOCENTER
#=========================================
max_idx    <- which.max(empty_west$dist_to_nearest_km)
igno_west  <- empty_west[max_idx, ]
igno_ll    <- st_transform(st_centroid(igno_west), 4326)
igno_xy    <- st_coordinates(igno_ll)

cat("Western ignocenter: (", round(igno_xy[1,"Y"], 4), ",",
    round(igno_xy[1,"X"], 4), ")\n")
cat("Maximum western isolation:",
    round(igno_west$dist_to_nearest_km, 1), "km\n\n")

# Project ignocenter for plotting
igno_proj <- st_transform(st_centroid(igno_west), st_crs(empty_land))
igno_plot <- st_coordinates(igno_proj)

#=========================================
# PREPARE CENTROIDS FOR PLOTTING
#=========================================
cat("Preparing centroids...\n")
empty_centroids <- st_centroid(empty_west)
empty_coords    <- st_coordinates(empty_centroids)

empty_df <- data.frame(
  x       = empty_coords[, "X"],
  y       = empty_coords[, "Y"],
  dist_km = empty_west$dist_to_nearest_km
)
empty_df <- empty_df[!is.na(empty_df$dist_km), ]

cat("Distance distribution (km):\n")
print(summary(empty_df$dist_km))

#=========================================
# V1: CONTINUOUS
#=========================================
cat("\nCreating continuous version (v1)...\n")

p1 <- ggplot() +
  geom_sf(data = all_conus,
          fill = "gray90", color = "gray70", linewidth = 0.2) +
  geom_sf(data = west_sf,
          fill = "white", color = "gray70", linewidth = 0.2) +
  geom_tile(data = empty_df,
            aes(x = x, y = y, fill = dist_km),
            width = 10000, height = 10000) +
  scale_fill_viridis(
    name      = "Distance to\nnearest record (km)",
    option    = "inferno",
    direction = -1,
    limits    = c(0, 125),
    breaks    = seq(0, 120, by = 20)
  ) +
  geom_sf(data = west_sf,
          fill = NA, color = "gray40", linewidth = 0.3) +
  geom_sf(data = all_conus,
          fill = NA, color = "gray60", linewidth = 0.2) +
  geom_point(aes(x = igno_plot[1, "X"], y = igno_plot[1, "Y"]),
             shape = 23, size = 4, fill = "white",
             color = "black", stroke = 1.5) +
  labs(
    title    = "The Letharia Void: Distance from the Known",
    subtitle = "Distance from nearest Letharia record (10 km grid cells)"
  ) +
  coord_sf(crs = st_crs(empty_land),
           xlim = st_bbox(west_sf)[c("xmin","xmax")],
           ylim = st_bbox(west_sf)[c("ymin","ymax")]) +
  theme_minimal() +
  theme(
    plot.title      = element_text(size = 18, face = "bold"),
    plot.subtitle   = element_text(size = 12, color = "gray40"),
    axis.text       = element_blank(),
    axis.title      = element_blank(),
    panel.grid      = element_blank(),
    legend.position = "right",
    legend.title    = element_text(size = 10),
    legend.text     = element_text(size = 9)
  )

ggsave(file.path(output_dir, "letharia_void_west_v1_continuous.png"),
       plot = p1, width = 10, height = 10, dpi = 300)
cat("  Saved v1 (continuous)\n")

#=========================================
# V2: DISCRETE BINS
#=========================================
cat("Creating discrete-bin version (v2)...\n")

empty_df$dist_bin <- cut(empty_df$dist_km,
                          breaks = c(0, 20, 40, 60, 80, 100, 120, Inf),
                          labels = c("0-20", "20-40", "40-60",
                                     "60-80", "80-100", "100-120", ">120"),
                          include.lowest = TRUE)

p2 <- ggplot() +
  geom_sf(data = all_conus,
          fill = "gray90", color = "gray70", linewidth = 0.2) +
  geom_sf(data = west_sf,
          fill = "white", color = "gray70", linewidth = 0.2) +
  geom_tile(data = empty_df,
            aes(x = x, y = y, fill = dist_bin),
            width = 10000, height = 10000) +
  scale_fill_viridis_d(
    name      = "Distance to\nnearest record (km)",
    option    = "inferno",
    direction = -1
  ) +
  geom_sf(data = west_sf,
          fill = NA, color = "gray40", linewidth = 0.3) +
  geom_sf(data = all_conus,
          fill = NA, color = "gray60", linewidth = 0.2) +
  geom_point(aes(x = igno_plot[1, "X"], y = igno_plot[1, "Y"]),
             shape = 23, size = 4, fill = "white",
             color = "black", stroke = 1.5) +
  labs(
    title    = "The Letharia Void: Distance from the Known",
    subtitle = "Distance from nearest Letharia record (10 km grid cells)"
  ) +
  coord_sf(crs = st_crs(empty_land),
           xlim = st_bbox(west_sf)[c("xmin","xmax")],
           ylim = st_bbox(west_sf)[c("ymin","ymax")]) +
  theme_minimal() +
  theme(
    plot.title      = element_text(size = 18, face = "bold"),
    plot.subtitle   = element_text(size = 12, color = "gray40"),
    axis.text       = element_blank(),
    axis.title      = element_blank(),
    panel.grid      = element_blank(),
    legend.position = "right",
    legend.title    = element_text(size = 10),
    legend.text     = element_text(size = 9)
  )

ggsave(file.path(output_dir, "letharia_void_west_v2_discrete.png"),
       plot = p2, width = 10, height = 10, dpi = 300)
cat("  Saved v2 (discrete bins)\n")

cat("\nDone. Outputs in:", output_dir, "\n")
cat("\n\"Distance from the known is the measure of manifold ignorance.\"\n")
