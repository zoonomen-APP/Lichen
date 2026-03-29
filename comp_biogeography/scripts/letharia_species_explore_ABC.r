## letharia_species_explore.r
## 2026.03.27
##
## Fuss-around exploration: Letharia genus and species in WA/OR.
##
##   Plot 0. Letharia presence-only (dark background, no absence surface)
##   Plot 1. Letharia presence + absence surface (genus, void plot)
##   Plots 2-4. Species level -- pending DB query
##
## Reads: letharia_void_WAOR_results.rds  (existing)
## Writes: PNGs to C:/Lichen/comp_biogeography/output/
##
## Alan / Claude  2026.03.27

library(dggridR)
library(sf)
library(ggplot2)
library(viridis)
library(tigris)

options(tigris_use_cache = TRUE)

## ---- CONFIG ----------------------------------------------------------------

rds_path      <- "C:/Lichen/hex_grids/output/letharia_void_WAOR_results.rds"
out_dir       <- "C:/Lichen/comp_biogeography/output"
HEX_RES       <- 11
TARGET_STATES <- c("WA", "OR")

## Species colors for the two-species plot
COL_COLUMBIANA <- "#00FFFF"   # cyan
COL_VULPINA    <- "#00FFFF"   # cyan -- same as columbiana for individual plots
                               # gold (#FFD700) reserved for two-species plot only

## ---- LOAD ------------------------------------------------------------------

cat("========================================\n")
cat("Letharia Species Exploration -- WA/OR\n")
cat("========================================\n\n")

results         <- readRDS(rds_path)
empty_hex       <- results$empty_hex_with_distances
occ_counts_waor <- results$occ_counts_waor
epitome         <- results$epitome
meta            <- results$meta

cat("Taxon in RDS:", meta$taxon, "\n")
cat("CONUS records:", format(meta$n_conus_records, big.mark = ","), "\n")
cat("WA/OR records:", format(meta$n_waor_records,  big.mark = ","), "\n\n")

## Quick look at structure -- report column names and first few rows
cat("occ_counts_waor columns:", paste(names(occ_counts_waor), collapse = ", "), "\n")
cat("Dimensions:", nrow(occ_counts_waor), "rows x", ncol(occ_counts_waor), "cols\n")
cat("First few rows:\n")
print(head(occ_counts_waor))
cat("\n")

## ---- SHARED INFRASTRUCTURE -------------------------------------------------

cat("Building shared spatial infrastructure...\n")

dggs    <- dgconstruct(projection = "ISEA", aperture = 3,
                       topology = "HEXAGON", res = HEX_RES)
id_col  <- names(empty_hex)[1]
hex_ids <- empty_hex[[id_col]]
polys   <- dgcellstogrid(dggs, hex_ids)
if (is.na(st_crs(polys))) st_crs(polys) <- 4326
poly_id_col <- names(polys)[1]
cat("  dggridR polygon id column:", poly_id_col, "\n")
cat("  RDS hex id column:", names(empty_hex)[1], "\n")
## Align column names with dggridR's poly_id_col
names(empty_hex)[1]       <- poly_id_col
names(occ_counts_waor)[1] <- poly_id_col

dist_df <- data.frame(
  hex_id  = empty_hex[[id_col]],
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

## ---- HELPER: build occupied sf for a subset --------------------------------

make_occ_sf <- function(occ_subset) {
  occ_polys <- dgcellstogrid(dggs, occ_subset[[poly_id_col]])
  if (is.na(st_crs(occ_polys))) st_crs(occ_polys) <- 4326
  merge(occ_polys, occ_subset, by = poly_id_col, all.x = TRUE)
}

## ---- HELPER: base void plot ------------------------------------------------

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
      plot.title        = element_text(size = 18, face = "bold", color = "white"),
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

## ---- HELPER: presence-only base plot (no absence surface) -----------------

base_plot_dark <- function(title_str) {
  ggplot() +
    geom_sf(data = waor_states,
            fill = "gray10", color = NA) +
    geom_sf(data = waor_counties,
            fill = NA, color = "white", linewidth = 0.15) +
    geom_sf(data = waor_states,
            fill = NA, color = "white", linewidth = 0.5) +
    geom_sf(data = interstates,
            color = "#FF4444", linewidth = 1.2) +
    labs(title = title_str) +
    theme_minimal() +
    theme(
      plot.title        = element_text(size = 18, face = "bold", color = "white"),
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

## ---- PLOT 0: Letharia presence-only ----------------------------------------

cat("Plot 0: Letharia presence-only...\n")

occ_sf_genus <- make_occ_sf(occ_counts_waor)

p0 <- base_plot_dark("Letharia: Presence Only") +
  geom_sf(data = occ_sf_genus,
          aes(alpha = log_n),
          fill = COL_COLUMBIANA, color = NA) +
  scale_alpha_continuous(
    name   = "Letharia\nspecimens\n(log10)",
    range  = c(0.15, 0.95),
    breaks = c(0, 1, 2, 3),
    labels = c("1", "10", "100", "1k")
  )

ggsave(file.path(out_dir, "letharia_00_presence_only.png"),
       plot = p0, width = 12, height = 8, dpi = 300)
cat("  Saved: letharia_00_presence_only.png\n\n")

## ---- PLOT 1: All Letharia (genus void) -------------------------------------

cat("Plot 1: All Letharia...\n")
cat("  occ_counts_waor columns now:", paste(names(occ_counts_waor), collapse=", "), "\n")
cat("  poly_id_col:", poly_id_col, "\n")
cat("  first few seqnums:", head(occ_counts_waor[[poly_id_col]]), "\n")

## occ_counts_waor already has n_specimens, log_n -- use directly
occ_sf_genus <- make_occ_sf(occ_counts_waor)

p1 <- base_plot("Letharia: The Void  (all species)") +
  geom_sf(data = occ_sf_genus,
          aes(alpha = log_n),
          fill = COL_COLUMBIANA, color = NA) +
  scale_alpha_continuous(
    name   = "Letharia\nspecimens\n(log10)",
    range  = c(0.0, 0.95),
    breaks = c(0, 1, 2, 3),
    labels = c("1", "10", "100", "1k")
  )

ggsave(file.path(out_dir, "letharia_01_genus.png"),
       plot = p1, width = 12, height = 8, dpi = 300)
cat("  Saved: letharia_01_genus.png\n\n")

## ---- LOAD SPECIES DATA -----------------------------------------------------

sp_rds_path <- "C:/Lichen/comp_biogeography/output/letharia_species_WAOR.rds"
sp_results  <- readRDS(sp_rds_path)
sp_list     <- sp_results$sp_list

cat("Species data loaded:\n")
for (sp in names(sp_list)) {
  cat(sprintf("  %-25s  %d hexes  %d specimens\n",
              sp,
              nrow(sp_list[[sp]]),
              sum(sp_list[[sp]]$n_specimens)))
}
cat("\n")

## ---- PLOT 2: L. columbiana presence + absence ------------------------------

cat("Plot 2: L. columbiana void...\n")

col_df <- sp_list[["Letharia columbiana"]]

if (is.null(col_df) || nrow(col_df) == 0) {
  cat("  WARNING: no columbiana data -- check species RDS\n\n")
} else {
  names(col_df)[names(col_df) == "hex_id"] <- poly_id_col
  occ_sf_col <- make_occ_sf(col_df)

  p2 <- base_plot("Letharia columbiana: The Void") +
    geom_sf(data = occ_sf_col,
            aes(alpha = log_n),
            fill = COL_COLUMBIANA, color = NA) +
    scale_alpha_continuous(
      name   = "L. columbiana\nspecimens\n(log10)",
      range  = c(0.15, 0.95),
      breaks = c(0, 1, 2, 3),
      labels = c("1", "10", "100", "1k")
    )

  ggsave(file.path(out_dir, "letharia_02_columbiana_void.png"),
         plot = p2, width = 12, height = 8, dpi = 300)
  cat("  Saved: letharia_02_columbiana_void.png\n\n")
}

## ---- PLOT 3: L. vulpina presence + absence ---------------------------------

cat("Plot 3: L. vulpina void...\n")

vul_df <- sp_list[["Letharia vulpina"]]

if (is.null(vul_df) || nrow(vul_df) == 0) {
  cat("  WARNING: no vulpina data -- check species RDS\n\n")
} else {
  names(vul_df)[names(vul_df) == "hex_id"] <- poly_id_col
  occ_sf_vul <- make_occ_sf(vul_df)

  p3 <- base_plot("Letharia vulpina: The Void") +
    geom_sf(data = occ_sf_vul,
            aes(alpha = log_n),
            fill = COL_VULPINA, color = NA) +
    scale_alpha_continuous(
      name   = "L. vulpina\nspecimens\n(log10)",
      range  = c(0.15, 0.95),
      breaks = c(0, 1, 2, 3),
      labels = c("1", "10", "100", "1k")
    )

  ggsave(file.path(out_dir, "letharia_03_vulpina_void.png"),
         plot = p3, width = 12, height = 8, dpi = 300)
  cat("  Saved: letharia_03_vulpina_void.png\n\n")
}

## ---- DONE ------------------------------------------------------------------

cat("========================================\n")
cat("All plots complete.\n")
cat("Output directory:", out_dir, "\n")
cat("========================================\n")
