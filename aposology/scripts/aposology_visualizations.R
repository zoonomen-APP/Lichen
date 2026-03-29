#=========================================
# APOSOLOGY VISUALIZATIONS
# 36 high-density CONUS counties
# Species-level records only
# 2026.02.07
#=========================================

library(ggplot2)
library(sf)
library(tigris)

options(tigris_use_cache = TRUE)

output_dir <- "c:/Lichen/aposology/output"

#=========================================
# READ DATA
#=========================================

# Main aposology data
d <- read.delim("c:/Lichen/aposology/output/top36_counties_aposology_species.tsv",
                header = FALSE, sep = "\t",
                col.names = c("state", "county", "taxon", "county_n",
                              "n_states_present", "absent_from"))

# County coordinates
coords <- read.delim("c:/Lichen/aposology/output/county_coords.tsv",
                      header = FALSE, sep = "\t",
                      col.names = c("state", "county", "lat", "lon"))

cat("Records:", nrow(d), "\n")
cat("Counties:", length(unique(paste(d$state, d$county))), "\n")
cat("Unique taxa:", length(unique(d$taxon)), "\n")

#=========================================
# 1. SUMMARY TABLE (already made, but print it)
#=========================================
cat("\n=== COUNTY BREADTH SUMMARY ===\n")

breadth <- aggregate(n_states_present ~ state + county, d, function(x) {
  c(min = min(x), median = median(x), mean = round(mean(x), 1), max = max(x))
})
breadth <- cbind(breadth[, 1:2], as.data.frame(breadth$n_states_present))
breadth <- breadth[order(breadth$median), ]
print(breadth, row.names = FALSE)

#=========================================
# 2. HEATMAP: Counties x States absence
#=========================================
cat("\n=== BUILDING HEATMAP ===\n")

# 48 CONUS states
conus_states <- c("Alabama","Arizona","Arkansas","California","Colorado",
                  "Connecticut","Delaware","Florida","Georgia","Idaho",
                  "Illinois","Indiana","Iowa","Kansas","Kentucky",
                  "Louisiana","Maine","Maryland","Massachusetts","Michigan",
                  "Minnesota","Mississippi","Missouri","Montana","Nebraska",
                  "Nevada","New_Hampshire","New_Jersey","New_Mexico","New_York",
                  "North_Carolina","North_Dakota","Ohio","Oklahoma","Oregon",
                  "Pennsylvania","Rhode_Island","South_Carolina","South_Dakota",
                  "Tennessee","Texas","Utah","Vermont","Virginia",
                  "Washington","West_Virginia","Wisconsin","Wyoming")

# Build absence matrix
county_labels <- unique(paste0(d$county, " (", d$state, ")"))

# For each county-state pair: how many of the 10 taxa are absent
heat_list <- list()
for (i in 1:nrow(d)) {
  county_lab <- paste0(d$county[i], " (", d$state[i], ")")
  if (!is.na(d$absent_from[i]) && d$absent_from[i] != "") {
    abs_states <- trimws(unlist(strsplit(as.character(d$absent_from[i]), ";")))
    for (s in abs_states) {
      key <- paste(county_lab, s, sep = "|")
      if (is.null(heat_list[[key]])) heat_list[[key]] <- 0
      heat_list[[key]] <- heat_list[[key]] + 1
    }
  }
}

# Convert to data frame
heat_df <- data.frame(
  pair = names(heat_list),
  absences = unlist(heat_list),
  stringsAsFactors = FALSE
)
parts <- strsplit(heat_df$pair, "\\|")
heat_df$county_lab <- sapply(parts, `[`, 1)
heat_df$absent_state <- sapply(parts, `[`, 2)

# Add zero entries for county-state pairs with no absences
all_county_labs <- unique(heat_df$county_lab)
full_grid <- expand.grid(county_lab = all_county_labs,
                         absent_state = conus_states,
                         stringsAsFactors = FALSE)
heat_full <- merge(full_grid, heat_df[, c("county_lab", "absent_state", "absences")],
                   all.x = TRUE)
heat_full$absences[is.na(heat_full$absences)] <- 0

# Order counties by median breadth (most regional at top)
county_order <- breadth$county
county_lab_order <- paste0(breadth$county, " (", breadth$state, ")")
heat_full$county_lab <- factor(heat_full$county_lab, levels = rev(county_lab_order))

# Order states by total absences (most absent at right)
state_totals <- aggregate(absences ~ absent_state, heat_full, sum)
state_totals <- state_totals[order(-state_totals$absences), ]
heat_full$absent_state <- factor(heat_full$absent_state, levels = state_totals$absent_state)

p_heat <- ggplot(heat_full, aes(x = absent_state, y = county_lab, fill = absences)) +
  geom_tile(color = "white", linewidth = 0.2) +
  scale_fill_gradient2(low = "white", mid = "#FDAE61", high = "#D73027",
                       midpoint = 5, limits = c(0, 10),
                       name = "Taxa absent\n(of 10)") +
  labs(title = "Aposological Heatmap: Which states lack each county's top taxa?",
       subtitle = "36 high-density counties (>=5000 species-level records) | Counties ordered by median taxon breadth",
       x = NULL, y = NULL) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 7),
    axis.text.y = element_text(size = 7),
    legend.position = "right",
    plot.title = element_text(size = 11, face = "bold"),
    plot.subtitle = element_text(size = 8)
  )

ggsave(file.path(output_dir, "aposology_heatmap.png"),
       p_heat, width = 16, height = 10, dpi = 150)
cat("Heatmap saved.\n")

#=========================================
# 3. MAP: Counties colored by median breadth
#=========================================
cat("\n=== BUILDING MAP ===\n")

us_states_sf <- states(cb = TRUE, year = 2022)
conus_sf <- us_states_sf[!us_states_sf$STUSPS %in%
                           c("AK", "HI", "PR", "VI", "GU", "MP", "AS"), ]
conus_sf <- st_transform(conus_sf, crs = 5070)  # Albers

# Merge breadth with coordinates
map_data <- merge(breadth, coords, by = c("state", "county"))
map_sf <- st_as_sf(map_data, coords = c("lon", "lat"), crs = 4326)
map_sf <- st_transform(map_sf, crs = 5070)

# Labels
map_data_proj <- cbind(map_data, st_coordinates(map_sf))
map_data_proj$label <- gsub("_Co\\.", "", map_data_proj$county)
map_data_proj$label <- gsub("_", " ", map_data_proj$label)

p_map <- ggplot() +
  geom_sf(data = conus_sf, fill = "grey95", color = "grey60", linewidth = 0.3) +
  geom_point(data = map_data_proj,
             aes(x = X, y = Y, color = median, size = median),
             alpha = 0.8) +
  geom_text(data = map_data_proj,
            aes(x = X, y = Y, label = label),
            size = 2, nudge_y = 40000, check_overlap = TRUE) +
  scale_color_gradient2(low = "#D73027", mid = "#FDAE61", high = "#1A9850",
                        midpoint = 24, name = "Median states\npresent") +
  scale_size_continuous(range = c(2, 6), guide = "none") +
  labs(title = "Aposological Breadth of High-Density Counties",
       subtitle = "Color = median # of CONUS states where top-10 taxa are present | Red = regional, Green = cosmopolitan") +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank(),
    plot.title = element_text(size = 12, face = "bold"),
    plot.subtitle = element_text(size = 9)
  )

ggsave(file.path(output_dir, "aposology_breadth_map.png"),
       p_map, width = 14, height = 9, dpi = 150)
cat("Map saved.\n")

cat("\nDone. Outputs in:", output_dir, "\n")
