#=========================================
# APOSOLOGICAL ZONATION
# Hierarchical clustering of 84 counties and 48 states
# Based on taxon absence profiles
# 2026.02.07
#=========================================

library(ggplot2)
library(sf)
library(tigris)

options(tigris_use_cache = TRUE)
output_dir <- "c:/Lichen/aposology/output"

#=========================================
# READ ABSENCE MATRIX
#=========================================
mat <- read.delim("c:/Lichen/aposology/output/absence_matrix_84x48.tsv",
                   row.names = 1, sep = "\t", check.names = FALSE)
cat("Matrix dimensions:", nrow(mat), "counties x", ncol(mat), "states\n")

#=========================================
# CLUSTER COUNTIES (rows)
# Which counties have similar absence profiles?
#=========================================
cat("\n=== CLUSTERING COUNTIES ===\n")

county_dist <- dist(mat, method = "euclidean")
county_hc <- hclust(county_dist, method = "ward.D2")

# Plot dendrogram
png(file.path(output_dir, "county_dendrogram.png"), width = 1800, height = 1000, res = 150)
par(mar = c(4, 2, 3, 12))
plot(as.dendrogram(county_hc), horiz = TRUE, main = "County Clustering by Taxon Absence Profile",
     xlab = "Distance (Ward's method)", cex = 0.5)
dev.off()
cat("County dendrogram saved.\n")

# Cut into zones - try 5 clusters as starting point
n_zones <- 5
county_zones <- cutree(county_hc, k = n_zones)

cat("\nCounty zones (k=5):\n")
for (z in 1:n_zones) {
  members <- names(county_zones[county_zones == z])
  cat(paste0("\n--- Zone ", z, " (", length(members), " counties) ---\n"))
  cat(paste(members, collapse = "\n"), "\n")
}

#=========================================
# CLUSTER STATES (columns)
# Which states have similar absence profiles?
#=========================================
cat("\n=== CLUSTERING STATES ===\n")

state_dist <- dist(t(mat), method = "euclidean")
state_hc <- hclust(state_dist, method = "ward.D2")

# Plot dendrogram
png(file.path(output_dir, "state_dendrogram.png"), width = 1400, height = 800, res = 150)
par(mar = c(8, 4, 3, 2))
plot(state_hc, main = "State Clustering by Taxon Absence Profile",
     xlab = "", ylab = "Distance (Ward's method)", cex = 0.7)
# Add rectangles for 5 clusters
rect.hclust(state_hc, k = 5, border = c("red", "blue", "green3", "purple", "orange"))
dev.off()
cat("State dendrogram saved.\n")

state_zones <- cutree(state_hc, k = 5)
cat("\nState zones (k=5):\n")
for (z in 1:5) {
  members <- names(state_zones[state_zones == z])
  cat(paste0("\n--- Zone ", z, " (", length(members), " states) ---\n"))
  cat(paste(members, collapse = ", "), "\n")
}

#=========================================
# MAP: Counties colored by cluster
#=========================================
cat("\n=== BUILDING ZONE MAP ===\n")

us_states_sf <- states(cb = TRUE, year = 2022)
conus_sf <- us_states_sf[!us_states_sf$STUSPS %in%
                           c("AK", "HI", "PR", "VI", "GU", "MP", "AS"), ]
conus_sf <- st_transform(conus_sf, crs = 5070)

# County coordinates - need to build for all 84
coords <- read.delim("c:/Lichen/aposology/output/county_coords_84.tsv",
                      header = FALSE, sep = "\t",
                      col.names = c("state", "county", "lat", "lon"))

# Build zone data
zone_df <- data.frame(
  county_label = names(county_zones),
  zone = county_zones,
  stringsAsFactors = FALSE
)

# Parse county label back to state + county
zone_df$county <- gsub(" \\(.*\\)", "", zone_df$county_label)
zone_df$state <- gsub(".*\\((.*)\\)", "\\1", zone_df$county_label)

# Merge with coordinates
zone_df <- merge(zone_df, coords, by = c("state", "county"))

zone_sf <- st_as_sf(zone_df, coords = c("lon", "lat"), crs = 4326)
zone_sf <- st_transform(zone_sf, crs = 5070)
zone_proj <- cbind(zone_df, st_coordinates(zone_sf))
zone_proj$label <- gsub("_Co\\.", "", zone_proj$county)
zone_proj$label <- gsub("_", " ", zone_proj$label)
zone_proj$zone <- factor(zone_proj$zone)

# Zone colors
zone_colors <- c("1" = "#E41A1C", "2" = "#377EB8", "3" = "#4DAF4A",
                  "4" = "#984EA3", "5" = "#FF7F00")

p_zones <- ggplot() +
  geom_sf(data = conus_sf, fill = "grey95", color = "grey60", linewidth = 0.3) +
  geom_point(data = zone_proj,
             aes(x = X, y = Y, color = zone),
             size = 3, alpha = 0.8) +
  geom_text(data = zone_proj,
            aes(x = X, y = Y, label = label),
            size = 1.8, nudge_y = 35000, check_overlap = TRUE) +
  scale_color_manual(values = zone_colors, name = "Zone") +
  labs(title = "Aposological Zones: Counties clustered by taxon absence profiles",
       subtitle = "84 counties (>=3000 species-level records) | Ward's hierarchical clustering, k=5") +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank(),
    plot.title = element_text(size = 11, face = "bold"),
    plot.subtitle = element_text(size = 8)
  )

ggsave(file.path(output_dir, "aposology_zone_map.png"),
       p_zones, width = 14, height = 9, dpi = 150)
cat("Zone map saved.\n")

#=========================================
# MAP: States colored by cluster
#=========================================
cat("\n=== BUILDING STATE ZONE MAP ===\n")

state_zone_df <- data.frame(
  state_name = names(state_zones),
  zone = factor(state_zones),
  stringsAsFactors = FALSE
)

# Match state names to CONUS shapefile
# Need to convert underscore names back
state_zone_df$NAME <- gsub("_", " ", state_zone_df$state_name)
conus_zones <- merge(conus_sf, state_zone_df, by = "NAME", all.x = TRUE)

p_state_zones <- ggplot() +
  geom_sf(data = conus_zones, aes(fill = zone), color = "white", linewidth = 0.3) +
  scale_fill_manual(values = zone_colors, name = "Zone", na.value = "grey90") +
  labs(title = "Aposological State Zones: States clustered by taxon absence profiles",
       subtitle = "States that lack similar sets of taxa cluster together | Ward's hierarchical clustering, k=5") +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank(),
    plot.title = element_text(size = 11, face = "bold"),
    plot.subtitle = element_text(size = 8)
  )

ggsave(file.path(output_dir, "aposology_state_zones.png"),
       p_state_zones, width = 14, height = 9, dpi = 150)
cat("State zone map saved.\n")

cat("\nDone. All outputs in:", output_dir, "\n")
