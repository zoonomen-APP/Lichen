#=========================================
# LETHARIA VOID: SPECIMEN DENSITY
# Collecting effort surface - western states
# Companion map to letharia_distance_to_record_west.R
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

grid_path  <- "C:/Lichen/Grid_Analysis/data/grid_010km_counts.rds"
output_dir <- "C:/Lichen/Letharia_aposology/output"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

west_states <- c("Washington", "Oregon", "California", "Idaho", "Montana",
                 "Wyoming", "Utah", "Colorado", "Nevada", "Arizona",
                 "New Mexico")

#=========================================
# LOAD GRID AND STATE BOUNDARIES
#=========================================
cat("Loading 10km grid...\n")
grid <- readRDS(grid_path)
cat("  Total cells:", nrow(grid), "\n")

cat("Loading state boundaries...\n")
us_states <- states(cb = TRUE)
all_conus <- us_states[!us_states$STUSPS %in%
                        c("AK", "HI", "PR", "VI", "GU", "MP", "AS"), ]
west_sf   <- us_states[us_states$NAME %in% west_states, ]

all_conus <- st_transform(all_conus, st_crs(grid))
west_sf   <- st_transform(west_sf,   st_crs(grid))

#=========================================
# CLIP GRID TO WESTERN STATES
#=========================================
cat("Clipping to western states...\n")
west_union <- st_union(west_sf)
grid_west  <- grid[st_intersects(grid, west_union, sparse = FALSE)[, 1], ]
cat("  Western cells:", format(nrow(grid_west), big.mark = ","), "\n")
cat("  Cells with specimens:", sum(grid_west$n_specimens > 0), "\n")
cat("  Cells with zero specimens:", sum(grid_west$n_specimens == 0), "\n")

cat("\nSpecimen count distribution:\n")
print(summary(grid_west$n_specimens))

#=========================================
# PREPARE CENTROIDS
#=========================================
cat("\nPreparing centroids...\n")
centroids      <- st_centroid(grid_west)
centroid_coords <- st_coordinates(centroids)

grid_df <- data.frame(
  x          = centroid_coords[, "X"],
  y          = centroid_coords[, "Y"],
  n_specimens = grid_west$n_specimens
)

# Log scale for continuous version
grid_df$log_n <- log10(grid_df$n_specimens + 1)

#=========================================
# V1: CONTINUOUS LOG SCALE
# All cells including zeros
#=========================================
cat("Creating continuous log-scale version (v1)...\n")

p1 <- ggplot() +
  geom_sf(data = all_conus,
          fill = "gray90", color = "gray70", linewidth = 0.2) +
  geom_sf(data = west_sf,
          fill = "gray98", color = "gray70", linewidth = 0.2) +
  geom_tile(data = grid_df,
            aes(x = x, y = y, fill = log_n),
            width = 10000, height = 10000) +
  scale_fill_viridis(
    name   = "Specimens\n(log10 scale)",
    option = "mako",
    breaks = log10(c(1, 2, 6, 21, 101) + 1) ,
    labels = c("0", "1", "5", "20", "100+"),
    limits = c(0, NA)
  ) +
  geom_sf(data = west_sf,
          fill = NA, color = "gray40", linewidth = 0.3) +
  geom_sf(data = all_conus,
          fill = NA, color = "gray60", linewidth = 0.2) +
  labs(
    title    = "Collecting Effort: All Lichen Specimens",
    subtitle = "10 km grid cells, western states | log10(n+1) scale"
  ) +
  coord_sf(crs    = st_crs(grid),
           xlim   = st_bbox(west_sf)[c("xmin", "xmax")],
           ylim   = st_bbox(west_sf)[c("ymin", "ymax")]) +
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

ggsave(file.path(output_dir, "letharia_effort_west_v1_continuous.png"),
       plot = p1, width = 10, height = 10, dpi = 300)
cat("  Saved v1 (continuous log)\n")

#=========================================
# V2: DISCRETE BINS
# Matching visual language of distance map
#=========================================
cat("Creating discrete-bin version (v2)...\n")

grid_df$effort_bin <- cut(grid_df$n_specimens,
                           breaks = c(-1, 0, 5, 20, 100, Inf),
                           labels = c("0", "1-5", "6-20", "21-100", ">100"),
                           include.lowest = TRUE)

# Use a sequential palette that pairs well with inferno
effort_colors <- c(
  "0"      = "gray85",
  "1-5"    = "#C7E9B4",
  "6-20"   = "#41B6C4",
  "21-100" = "#2C7FB8",
  ">100"   = "#253494"
)

p2 <- ggplot() +
  geom_sf(data = all_conus,
          fill = "gray90", color = "gray70", linewidth = 0.2) +
  geom_sf(data = west_sf,
          fill = "gray98", color = "gray70", linewidth = 0.2) +
  geom_tile(data = grid_df,
            aes(x = x, y = y, fill = effort_bin),
            width = 10000, height = 10000) +
  scale_fill_manual(
    name   = "Lichen specimens\nper 10km cell",
    values = effort_colors
  ) +
  geom_sf(data = west_sf,
          fill = NA, color = "gray40", linewidth = 0.3) +
  geom_sf(data = all_conus,
          fill = NA, color = "gray60", linewidth = 0.2) +
  labs(
    title    = "Collecting Effort: All Lichen Specimens",
    subtitle = "10 km grid cells, western states"
  ) +
  coord_sf(crs    = st_crs(grid),
           xlim   = st_bbox(west_sf)[c("xmin", "xmax")],
           ylim   = st_bbox(west_sf)[c("ymin", "ymax")]) +
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

ggsave(file.path(output_dir, "letharia_effort_west_v2_discrete.png"),
       plot = p2, width = 10, height = 10, dpi = 300)
cat("  Saved v2 (discrete bins)\n")

cat("\nDone. Outputs in:", output_dir, "\n")
