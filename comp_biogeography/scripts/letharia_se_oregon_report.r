## letharia_se_oregon_report.r
## 2026.03.28
##
## Generate HTML report of SE Oregon Letharia records for Bruce McCune.
## Includes the three-zone delta plot and a voucher table with clickable links.
##
## Assumes se_recs is already in memory from the interactive query session.
## If not, re-run the DB query at the bottom of this script.
##
## Output: C:/Lichen/comp_biogeography/output/letharia_se_oregon.html
##
## Alan / Claude  2026.03.28

library(RSQLite)

out_dir  <- "C:/Lichen/comp_biogeography/output"
out_html <- file.path(out_dir, "letharia_se_oregon.html")
img_path <- file.path(out_dir, "letharia_05_delta.png")

## ---- RE-QUERY IF NEEDED ----------------------------------------------------
## Uncomment if se_recs is not in memory:
#
# con <- dbConnect(SQLite(), "C:/Lichen/SQL/clh_2025_11.db")
# sql <- "
#   SELECT
#     n.id,
#     n.scientificNameRegularized  AS species,
#     n.institutionCode            AS institution,
#     n.[references]               AS ref,
#     c.decimalLatitude            AS lat,
#     c.decimalLongitude           AS lon,
#     c.stateProvinceEd            AS state,
#     c.countyEd                   AS county,
#     c.eventDateEd                AS date,
#     n.recordedByEd               AS collector
#   FROM narrow n
#   JOIN conus_coords c ON n.id = c.id
#   WHERE n.scientificNameRegularized IN ('Letharia columbiana', 'Letharia vulpina')
#     AND c.stateProvinceEd = 'Oregon'
#     AND c.decimalLatitude  < 43.0
#     AND c.decimalLatitude  > 41.9
#     AND c.decimalLongitude > -120.5
#     AND c.decimalLongitude < -117.5
# "
# se_recs <- dbGetQuery(con, sql)
# dbDisconnect(con)

## ---- BUILD TABLE ROWS ------------------------------------------------------

## Sort by county, species, date
se_sorted <- se_recs[order(se_recs$county, se_recs$species, se_recs$date), ]

## Build HTML rows, with county header rows
build_rows <- function(df) {
  rows  <- character(0)
  counties <- unique(df$county)

  for (co in counties) {
    sub <- df[df$county == co, ]

    ## County header row
    rows <- c(rows, sprintf(
      '<tr class="county-header"><td colspan="5">%s</td></tr>',
      gsub("_", " ", co)
    ))

    ## Record rows
    for (i in seq_len(nrow(sub))) {
      r <- sub[i, ]
      rows <- c(rows, sprintf(
        '<tr class="%s">
          <td>%s</td>
          <td><em>%s</em></td>
          <td>%s</td>
          <td>%s</td>
          <td><a href="%s" target="_blank">%s</a></td>
        </tr>',
        ifelse(i %% 2 == 0, "even", "odd"),
        r$collector,
        r$species,
        r$institution,
        r$date,
        r$ref,
        r$id
      ))
    }
  }
  paste(rows, collapse = "\n")
}

table_rows <- build_rows(se_sorted)

## ---- ENCODE IMAGE AS BASE64 ------------------------------------------------
## Embed the plot directly so the HTML is self-contained

img_b64 <- base64enc::base64encode(img_path)
img_tag  <- sprintf('<img src="data:image/png;base64,%s" style="max-width:100%%;">', img_b64)

## ---- WRITE HTML ------------------------------------------------------------

html <- sprintf('<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>SE Oregon Letharia Records</title>
  <style>
    body {
      font-family: Georgia, serif;
      max-width: 900px;
      margin: 40px auto;
      padding: 0 20px;
      background: #f9f9f9;
      color: #222;
    }
    h1 { font-size: 1.6em; color: #2c3e50; }
    h2 { font-size: 1.2em; color: #2c3e50; margin-top: 2em; }
    p  { line-height: 1.6; }
    .plot-container { margin: 2em 0; }
    table {
      width: 100%%;
      border-collapse: collapse;
      font-size: 0.92em;
      margin-top: 1em;
    }
    th {
      background: #2c3e50;
      color: white;
      padding: 8px 10px;
      text-align: left;
    }
    td { padding: 6px 10px; }
    tr.odd  { background: #ffffff; }
    tr.even { background: #eef2f5; }
    tr.county-header {
      background: #c8d8e8;
      font-weight: bold;
      font-size: 1.0em;
      padding: 6px 10px;
    }
    a { color: #2980b9; }
    .caption {
      font-size: 0.85em;
      color: #555;
      margin-top: 0.5em;
      font-style: italic;
    }
  </style>
</head>
<body>

<h1>SE Oregon <em>Letharia</em> Records: Harney &amp; Lake Counties</h1>

<p>
The plot below shows the three-zone delta for <em>Letharia columbiana</em>
and <em>L. vulpina</em> across Washington and Oregon, against a background
absence surface (ignorance depth in km). Cyan hexes = <em>L. columbiana</em>
only; gold = <em>L. vulpina</em> only; white-to-cyan/gold = co-occurrence,
colored by fourth-root delta (vulpina &minus; columbiana).
</p>

<p>
The isolated clusters in SE Oregon (Harney and Lake Counties) are visible
in the lower right of the plot. These are well-separated from the main
Cascade range population and sit in a region of high ignorance depth —
making them both biogeographically interesting and worth a closer look
at the underlying records.
</p>

<div class="plot-container">
%s
<p class="caption">Figure 1. Letharia three-zone delta, WA/OR.
SE Oregon clusters visible lower right.</p>
</div>

<h2>Voucher Records</h2>

<p>12 records from 6 hexes. Grouped by county.</p>

<table>
  <thead>
    <tr>
      <th>Collector</th>
      <th>Species</th>
      <th>Institution</th>
      <th>Date</th>
      <th>Record</th>
    </tr>
  </thead>
  <tbody>
%s
  </tbody>
</table>

<p class="caption">
Records from CLH database (clh_2025_11.db). Links go to Lichen Portal
individual specimen pages.
</p>

</body>
</html>',
img_tag,
table_rows
)

writeLines(html, out_html)
cat("Saved:", out_html, "\n")
