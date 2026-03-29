#=========================================
# LETHARIA PRESENCE MAP - WESTERN STATES
# vulpina and columbiana records
# 2026.03.11
# Alan + Claude
#=========================================

library(sf)
library(ggplot2)
library(tigris)
library(RSQLite)
library(DBI)

options(tigris_use_cache = TRUE)

#=========================================
# CONFIG
#=========================================

db_path    <- "C:/Lichen/SQL/clh_2025_11.db"
output_dir <- "C:/Lichen/Letharia_aposology/output"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

west_states <- c("Washington", "Oregon", "California", "Idaho", "Montana",
                 "Wyoming", "Utah", "Colorado", "Nevada", "Arizona",
                 "New Mexico")

#=========================================
# EXTRACT RECORDS
#=========================================
cat("Connecting to database...\n")
con <- dbConnect(SQLite(), db_path)

sql <- "
SELECT id,
       UPPER(scientificName) AS species_upper,
       CAST(COALESCE(decimalLatitudeEd,  decimalLatitude)  AS REAL) AS lat,
       CAST(COALESCE(decimalLongitudeEd, decimalLongitude) AS REAL) AS lon
FROM narrow
WHERE UPPER(scientificName) IN ('LETHARIA VULPINA', 'LETHARIA COLUMBIANA')
  AND countryEd = 'United States'
  AND CAST(COALESCE(decimalLatitudeEd,  decimalLatitude)  AS REAL) IS NOT NULL
  AND CAST(COALESCE(decimalLongitudeEd, decimalLongitude) AS REAL) IS NOT NULL
"

cat("Querying records...\n")
leth <- dbGetQuery(con, sql)
dbDisconnect(con)

leth$lat <- as.numeric(leth$lat)
leth$lon <- as.numeric(leth$lon)
leth <- leth[!is.na(leth$lat) & !is.na(leth$lon), ]

leth$species <- ifelse(leth$species_upper == "LETHARIA VULPINA",
                        "L. vulpina", "L. columbiana")

cat("  L. vulpina:    ", sum(leth$species == "L. vulpina"), "\n")
cat("  L. columbiana: ", sum(leth$species == "L. columbiana"), "\n")

#=========================================
# PROJECT TO ALBERS
#=========================================
cat("Projecting points...\n")
leth_sf <- st_as_sf(leth, coords = c("lon", "lat"), crs = 4326)
albers   <- st_crs("EPSG:5070")
leth_sf  <- st_transform(leth_sf, albers)

#=========================================
# STATE BOUNDARIES
#=========================================
cat("Loading state boundaries...\n")
us_states <- states(cb = TRUE)
all_conus <- us_states[!us_states$STUSPS %in%
                        c("AK", "HI", "PR", "VI", "GU", "MP", "AS"), ]
west_sf   <- us_states[us_states$NAME %in% west_states, ]

all_conus <- st_transform(all_conus, albers)
west_sf   <- st_transform(west_sf,   albers)

# Clip points to western states
west_union <- st_union(west_sf)
leth_west  <- leth_sf[st_intersects(leth_sf, west_union,
                                     sparse = FALSE)[, 1], ]

cat("  Western records:", nrow(leth_west), "\n")
cat("  L. vulpina:    ", sum(leth_west$species == "L. vulpina"), "\n")
cat("  L. columbiana: ", sum(leth_west$species == "L. columbiana"), "\n")

#=========================================
# V1: BOTH SPECIES, COLORED
#=========================================
cat("\nCreating two-species map (v1)...\n")

species_colors <- c(
  "L. vulpina"    = "#E69F00",   # amber
  "L. columbiana" = "#0072B2"    # blue
)

# Plot columbiana on top (smaller dataset, don't want it buried)
leth_plot <- leth_west[order(leth_west$species,
                              decreasing = TRUE), ]

p1 <- ggplot() +
  geom_sf(data = all_conus,
          fill = "gray90", color = "gray70", linewidth = 0.2) +
  geom_sf(data = west_sf,
          fill = "gray98", color = "gray70", linewidth = 0.2) +
  geom_sf(data = leth_plot,
          aes(color = species),
          size = 0.8, alpha = 0.6, shape = 16) +
  scale_color_manual(
    name   = NULL,
    values = species_colors
  ) +
  geom_sf(data = west_sf,
          fill = NA, color = "gray40", linewidth = 0.3) +
  geom_sf(data = all_conus,
          fill = NA, color = "gray60", linewidth = 0.2) +
  labs(
    title    = "Letharia Records: Western United States",
    subtitle = "L. vulpina and L. columbiana | CLH database"
  ) +
  coord_sf(crs  = albers,
           xlim = st_bbox(west_sf)[c("xmin", "xmax")],
           ylim = st_bbox(west_sf)[c("ymin", "ymax")]) +
  theme_minimal() +
  theme(
    plot.title      = element_text(size = 18, face = "bold"),
    plot.subtitle   = element_text(size = 12, color = "gray40"),
    axis.text       = element_blank(),
    axis.title      = element_blank(),
    panel.grid      = element_blank(),
    legend.position = "right",
    legend.text     = element_text(size = 11, face = "italic"),
    legend.key.size = unit(0.8, "lines")
  ) +
  guides(color = guide_legend(override.aes = list(size = 3, alpha = 1)))

ggsave(file.path(output_dir, "letharia_presence_west_v1_combined.png"),
       plot = p1, width = 10, height = 10, dpi = 300)
cat("  Saved v1 (combined)\n")

#=========================================
# V2: FACETED BY SPECIES
#=========================================
cat("Creating faceted map (v2)...\n")

p2 <- ggplot() +
  geom_sf(data = all_conus,
          fill = "gray90", color = "gray70", linewidth = 0.2) +
  geom_sf(data = west_sf,
          fill = "gray98", color = "gray70", linewidth = 0.2) +
  geom_sf(data = leth_west,
          aes(color = species),
          size = 0.6, alpha = 0.6, shape = 16) +
  scale_color_manual(values = species_colors) +
  geom_sf(data = west_sf,
          fill = NA, color = "gray40", linewidth = 0.3) +
  facet_wrap(~species) +
  labs(
    title    = "Letharia Records: Western United States",
    subtitle = "CLH database"
  ) +
  coord_sf(crs  = albers,
           xlim = st_bbox(west_sf)[c("xmin", "xmax")],
           ylim = st_bbox(west_sf)[c("ymin", "ymax")]) +
  theme_minimal() +
  theme(
    plot.title      = element_text(size = 16, face = "bold"),
    plot.subtitle   = element_text(size = 11, color = "gray40"),
    axis.text       = element_blank(),
    axis.title      = element_blank(),
    panel.grid      = element_blank(),
    legend.position = "none",
    strip.text      = element_text(size = 11, face = "italic")
  )

ggsave(file.path(output_dir, "letharia_presence_west_v2_faceted.png"),
       plot = p2, width = 16, height = 10, dpi = 300)
cat("  Saved v2 (faceted)\n")

cat("\nDone. Outputs in:", output_dir, "\n")
