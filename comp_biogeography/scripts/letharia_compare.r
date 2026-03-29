## letharia_compare.r
## 2026.03.28
##
## Cross-taxon comparison plots: L. columbiana vs L. vulpina in WA/OR.
##
##   Plot 5. Three-zone delta
##             Zone A: columbiana-only hexes (cyan)
##             Zone B: vulpina-only hexes (gold)
##             Zone C: co-occurrence hexes, diverging by fourth-root delta
##                     delta = vulpina^0.25 - columbiana^0.25
##
## Reads:
##   C:/Lichen/hex_grids/output/letharia_void_WAOR_results.rds  (absence surface)
##   C:/Lichen/comp_biogeography/output/letharia_species_WAOR.rds  (species counts)
##
## Writes: PNGs to C:/Lichen/comp_biogeography/output/
##
## Alan / Claude  2026.03.28

library(dggridR)
library(sf)
library(ggplot2)
library(viridis)
library(tigris)
library(ggtext)

options(tigris_use_cache = TRUE)
## ---- CONFIG ----------------------------------------------------------------

void_rds_path <- "C:/Lichen/hex_grids/output/letharia_void_WAOR_results.rds"
sp_rds_path   <- "C:/Lichen/comp_biogeography/output/letharia_species_WAOR.rds"
out_dir       <- "C:/Lichen/comp_biogeography/output"
HEX_RES       <- 11
TARGET_STATES <- c("WA", "OR")

## ---- LOAD ------------------------------------------------------------------

cat("========================================\n")
cat("Letharia Compare -- WA/OR\n")
cat("========================================\n\n")

void_results    <- readRDS(void_rds_path)
empty_hex       <- void_results$empty_hex_with_distances
epitome         <- void_results$epitome

sp_results <- readRDS(sp_rds_path)
sp_list    <- sp_results$sp_list

cat("Species loaded:\n")
for (sp in names(sp_list)) {
  cat(sprintf("  %-25s  %d hexes  %d specimens\n",
              sp,
              nrow(sp_list[[sp]]),
              sum(sp_list[[sp]]$n_specimens)))
}
cat("\n")

col_df <- sp_list[["Letharia columbiana"]]
vul_df <- sp_list[["Letharia vulpina"]]

## ---- SHARED SPATIAL INFRASTRUCTURE -----------------------------------------

cat("Building spatial infrastructure...\n")

dggs <- dgconstruct(projection = "ISEA", aperture = 3,
                    topology = "HEXAGON", res = HEX_RES)

## Empty hex polygons for void surface
id_col      <- names(empty_hex)[1]
hex_ids     <- empty_hex[[id_col]]
polys       <- dgcellstogrid(dggs, hex_ids)
if (is.na(st_crs(polys))) st_crs(polys) <- 4326
poly_id_col <- names(polys)[1]

names(empty_hex)[1] <- poly_id_col

dist_df <- data.frame(
  id      = empty_hex[[poly_id_col]],
  dist_km = empty_hex$dist_km,
  stringsAsFactors = FALSE
)
names(dist_df)[1] <- poly_id_col
empty_sf <- merge(polys, dist_df, by = poly_id_col, all.x = TRUE)
dist_max_rounded <- ceiling(max(empty_sf$dist_km, na.rm = TRUE) / 10) * 10

## Boundaries
us_states     <- states(cb = TRUE)
waor_states   <- us_states[us_states$STUSPS %in% TARGET_STATES, ]
waor_states   <- st_transform(waor_states, crs = 4326)
waor_union    <- st_union(waor_states)
waor_counties <- counties(state = TARGET_STATES, cb = TRUE)
waor_counties <- st_transform(waor_counties, crs = 4326)
waor_bbox     <- st_bbox(waor_union)

highways    <- primary_roads()
highways    <- st_transform(highways, crs = 4326)
interstates <- highways[highways$RTTYP == "I", ]
waor_buf    <- st_buffer(waor_union, dist = 0.1)
interstates <- st_intersection(interstates, waor_buf)

epi_pt <- data.frame(x = epitome$lon, y = epitome$lat)

cat("  Infrastructure ready\n\n")

## ---- HELPER: build sf from hex data frame ----------------------------------

make_occ_sf <- function(df) {
  ## Expects poly_id_col as first column
  occ_polys <- dgcellstogrid(dggs, df[[poly_id_col]])
  if (is.na(st_crs(occ_polys))) st_crs(occ_polys) <- 4326
  merge(occ_polys, df, by = poly_id_col, all.x = TRUE)
}

## ---- HELPER: base plot (void surface + boundaries) -------------------------

base_plot <- function(title_str) {
  ggplot() +
    geom_sf(data = waor_states,
            fill = "gray10", color = NA) +
    geom_sf(data = empty_sf,
            aes(fill = dist_km),
            color = NA) +
    scale_fill_viridis(
      name      = "Ignorance depth (km)",
      option    = "plasma",
      direction =  1,
      na.value  = "gray15",
      limits    = c(0, dist_max_rounded),
      breaks    = seq(0, dist_max_rounded, by = 20)
    ) +
    geom_sf(data = waor_counties,
            fill = NA, color = "white", linewidth = 0.15) +
    geom_sf(data = waor_states,
            fill = NA, color = "white", linewidth = 0.5) +
    geom_sf(data = interstates,
            color = "#FF4444", linewidth = 1.2) +
    geom_point(data = epi_pt, aes(x = x, y = y),
               shape = 23, size = 5,
               fill = "#FF4444", color = "white", stroke = 1.5) +
    labs(title = title_str) +
    theme_minimal() +
    theme(
      plot.title        = element_text(size = 16, face = "bold", color = "white"),
      plot.subtitle     = element_markdown(size = 16, color = "white"),
      plot.background   = element_rect(fill = "gray10", color = NA),
      panel.background  = element_rect(fill = "gray10", color = NA),
      axis.text         = element_blank(),
      axis.title        = element_blank(),
      panel.grid        = element_blank(),
      legend.position   = "right",
      legend.background = element_rect(fill = "gray10", color = NA),
      legend.title      = element_text(size = 9,  color = "white"),
      legend.text       = element_text(size = 8,  color = "white")
    ) +
    coord_sf(crs  = 4326,
             xlim = c(waor_bbox["xmin"] - 0.5, waor_bbox["xmax"] + 0.5),
             ylim = c(waor_bbox["ymin"] - 0.3, waor_bbox["ymax"] + 0.3))
}

## ---- PLOT 5: Three-zone delta ----------------------------------------------

cat("Plot 5: Three-zone delta...\n")

## Align column names
col_base <- col_df
vul_base <- vul_df
names(col_base)[names(col_base) == "hex_id"] <- poly_id_col
names(vul_base)[names(vul_base) == "hex_id"] <- poly_id_col

col_ids <- col_base[[poly_id_col]]
vul_ids <- vul_base[[poly_id_col]]

only_col <- setdiff(col_ids, vul_ids)
only_vul <- setdiff(vul_ids, col_ids)
both_ids <- intersect(col_ids, vul_ids)

cat(sprintf("  Columbiana-only: %d hexes\n", length(only_col)))
cat(sprintf("  Vulpina-only:    %d hexes\n", length(only_vul)))
cat(sprintf("  Co-occurrence:   %d hexes\n", length(both_ids)))

## Build zone sf objects
zone_a_sf <- make_occ_sf(col_base[col_base[[poly_id_col]] %in% only_col, ])
zone_b_sf <- make_occ_sf(vul_base[vul_base[[poly_id_col]] %in% only_vul, ])

## Co-occurrence delta
col_co <- col_base[col_base[[poly_id_col]] %in% both_ids,
                   c(poly_id_col, "n_specimens")]
vul_co <- vul_base[vul_base[[poly_id_col]] %in% both_ids,
                   c(poly_id_col, "n_specimens")]
names(col_co)[2] <- "n_col"
names(vul_co)[2] <- "n_vul"

co_df       <- merge(col_co, vul_co, by = poly_id_col)
co_df$delta <- co_df$n_vul^0.25 - co_df$n_col^0.25
delta_max   <- max(abs(co_df$delta), na.rm = TRUE)
cat(sprintf("  Delta range: %.3f to %.3f\n\n", -delta_max, delta_max))

zone_c_sf <- make_occ_sf(co_df)

## Plot -- zone C uses ggnewscale to add second fill scale over plasma void.
## If ggnewscale not available, zone C rendered with pre-mapped colors instead.

use_ggnewscale <- requireNamespace("ggnewscale", quietly = TRUE)

if (use_ggnewscale) {
  library(ggnewscale)
  p5 <- base_plot("Letharia: Three-Zone Delta  (columbiana | both | vulpina)") +
    ## Zone A and B: fixed fill, no scale needed
    geom_sf(data = zone_a_sf, fill = "#00FFFF", alpha = 0.80, color = NA) +
    geom_sf(data = zone_b_sf, fill = "#FFD700", alpha = 0.80, color = NA) +
    ## Zone C: new fill scale for delta
    new_scale_fill() +
    geom_sf(data = zone_c_sf, aes(fill = delta), alpha = 1.0, color = NA) +
    scale_fill_gradient2(
      name     = "Delta\n(vul - col)\nfourth root",
      low      = "#00FFFF",
      mid      = "white",
      high     = "#FFD700",
      midpoint = 0,
      limits   = c(-delta_max, delta_max)
    ) +
    labs(
      title    = "Letharia: Three-Zone Delta  (columbiana | both | vulpina)",
      subtitle = paste0(
        "<span style='background-color:#00FFFF; color:#00FFFF;'>&#9632;</span>",
        " <span style='color:white;'>L. columbiana only</span>",
        "&nbsp;&nbsp;&nbsp;",
        "<span style='background-color:#FFD700; color:#FFD700;'>&#9632;</span>",
        " <span style='color:white;'>L. vulpina only</span>",
        "&nbsp;&nbsp;&nbsp;",
        "<span style='background-color:white; color:white;'>&#9632;</span>",
        " <span style='color:white;'>Both (see delta scale)</span>"
      )
    ) +
    theme(plot.subtitle = element_markdown(size = 10))
} else {
  ## Fallback: pre-map delta to hex color string, render with scale_identity
  cat("  ggnewscale not found -- using color pre-mapping fallback\n")
  ramp <- colorRamp(c("#00FFFF", "white", "#FFD700"))
  norm <- (zone_c_sf$delta + delta_max) / (2 * delta_max)  ## 0 to 1
  rgb_mat <- ramp(norm)
  zone_c_sf$hex_color <- rgb(rgb_mat[,1], rgb_mat[,2], rgb_mat[,3],
                              maxColorValue = 255)
  p5 <- base_plot("Letharia: Three-Zone Delta  (columbiana | both | vulpina)") +
    geom_sf(data = zone_a_sf, fill = "#00FFFF", alpha = 0.80, color = NA) +
    geom_sf(data = zone_b_sf, fill = "#FFD700", alpha = 0.80, color = NA) +
    geom_sf(data = zone_c_sf, fill = zone_c_sf$hex_color, alpha = 0.90,
            color = NA)
}

ggsave(file.path(out_dir, "letharia_05_delta.png"),
       plot = p5, width = 12, height = 8, dpi = 300)
cat("  Saved: letharia_05_delta.png\n\n")

## ---- DONE ------------------------------------------------------------------

cat("========================================\n")
cat("All plots complete.\n")
cat("Output directory:", out_dir, "\n")
cat("========================================\n")
