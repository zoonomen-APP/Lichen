# Comparative Biogeography / Aposologic Hex Vectors
# Lab Notes
# Alan Peterson + Claude

---

## 2026.03.27 — Session 1: The Void Plot and What It Prompted

### What we did
- Reviewed the PROJECT_HANDOFF document (comparative biogeography via aposologic
  hex vectors, WA/OR focus, Letharia as first taxon).
- Reviewed the presentation "Lichen Collections in the Contiguous United States:
  What We See, What We Miss, and What Might Be Wrong" (given 2026.03.26).
- Got the existing `letharia_void_WAOR_results.rds` plotting cleanly via
  `letharia_species_explore.r` → `letharia_01_genus.png`.

### The intellectual arc so far
The project grew from a progression:
1. **Geography of ignorance** — 10x10km square grid over CONUS48, each cell
   scored by record count or distance to nearest occupied cell. Produced
   a striking absence surface with analyzable features (epitome, centroid
   of absence).
2. **Presence as counterpoint** — realized presence density (log specimen count)
   could be overlaid, first as background highlight, then as a signal in its
   own right.
3. **The response surface illusion** — the two variables (absence depth,
   presence density) are structurally independent but when plotted together
   produce the *appearance* of a coherent response surface. This is not
   coincidental: both are measuring the same latent variable (local sampling
   intensity) from opposite sides.
4. **Letharia: The Void** — first taxon-specific dual-layer plot. Genus-level
   for WA/OR. Immediately interpretable and thought-provoking.

### Key observation: the two variables are almost one
- Empty hexes: distance to nearest occupied hex = proxy for sampling intensity
  (far = deeply unsampled)
- Occupied hexes: specimen count = proxy for sampling intensity
  (high = intensively sampled)
- Both windows onto the same latent variable. A unified single surface may
  be worth trying: one continuous knowledge-density score across all hexes,
  calibrated so occupied and empty meet at the boundary.

### The epitome
- Letharia epitome (point of maximum absence depth) falls near
  Aberdeen/Hoquiam/Grays Harbor, WA.
- This is an *informed* absence: wet, low-elevation, heavily logged coast —
  wrong habitat for Letharia. Region is collected (other taxa present),
  by collectors capable of finding Letharia. The absence is meaningful.
- Contrast with eastern Oregon voids: those may reflect genuine terra incognita
  rather than confirmed absence.

### The herbarium data model problem
Herbaria record *detection events* — physical specimens. There is no
infrastructure for recording expert negative observations: "lichenologist X
visited region Y, searched explicitly for Letharia, found none."
This is a fundamental limitation of biodiversity informatics.

The aposologic approach sidesteps this: instead of recording new negative data,
*infer* absence confidence from positive context already in the record —
collector identity, collection effort, taxonomic breadth, substrate coverage
in nearby hexes.

### Ideas deferred / to investigate

**1. Species-level plots**
The RDS collapses all Letharia to genus level. To compare L. columbiana vs
L. vulpina we need species-level hex counts from the CLH database.
Next step: write a DB query and data-prep script to build species-level
occ_counts for WA/OR, then add plots 2-4 to the explore script.

**2. The productive uncertainty zone**
There are hexes where absence confidence is *medium* — not terra incognita,
not confirmed absence, but somewhere in between. These are the maximally
informative areas for future fieldwork: visiting them would most change
the picture.
Visualizing this: probably the purple-to-dark-cyan transition on the void
plot. Needs a formal definition (e.g. cells with moderate collector history
but no Letharia record).
This is also an interesting application in its own right — a tool for
prioritizing fieldwork effort.

**3. The unified knowledge-density surface**
Instead of two layers (absence fill + presence alpha), compute a single
continuous score across all hexes:
- Occupied: f(log specimen count) → high = dense knowledge
- Empty: g(distance to nearest record), inverted → near = higher, far = lower
- Calibrate so both scales meet at zero at the occupied/empty boundary
Would produce a single-scale choropleth. Worth comparing to the dual-layer
to see which communicates better.

**4. Resolution investigation**
dggridR res=11 hexes (used in Letharia void work) are ~25-30km across.
The comparative biogeography project specifies 33km named-grid files.
Unclear if these are compatible or separate frameworks. Needs one diagnostic
session before scaling up.

**5. Interactive hex querying**
The best way to explore the void plots is interactively — click a hex,
get its stats (specimen count, distance score, collector list, taxa present).
Could be done in R with leaflet or shiny. Worth building once the basic
plots are stable.

**6. The county-based absence work (prior proof)**
Alan previously demonstrated absence signal using a county-based approach:
selected ~40-60 high-record counties as "knowledge centers," identified the
10 most frequent taxa in each, then characterized surrounding counties by
the pattern of absences of those taxa. Distance matrix → heatmap → tree
regression (pruned to 5 levels) → state characterization map showed strong
geographic coherence despite the algorithm knowing nothing about spatial
adjacency.
This is a *different* proof than the hex void approach — statistical rather
than visual. The two are complementary. Worth keeping the county method
documented as prior validation.

**8. Numerical map distance — comparing hex vectors directly**
Each taxon's distribution can be encoded as a numeric vector across hex cells:
- Presence-only: binary (0/1), distance via Jaccard or Sørensen
- Presence+absence: continuous (0 = deep ignorance → 1 = present), distance
  via weighted Jaccard or custom metric

Key insight: the numerical distance liberates you from the visual comparison.
Visual is for understanding and communication. Numerical is for discovery at
scale — compare hundreds of taxon pairs systematically, find the interesting
ones, *then* look at the maps.

"Inside-out community structure": instead of asking what species co-occur at
sites, ask what sites have similar species knowledge profiles. Community
structure falls out of that inversion without being imposed from outside.

The numerical and visual distances should agree — if two maps look similar,
their vectors should be close. If absence-weighted distances better predict
known ecological/taxonomic relationships than presence-only distances,
that's the quantitative result to go with Figure 1.

**9. The common-species undercollection problem — critical caveat**
Frequent taxa are often NOT collected because they are common. Collectors
walk past a thousand Bryoria fremontii to collect the one interesting thing
they haven't seen before.

Example: Klamath County has 455 B. fremontii records. Crater Lake NP
(inside Klamath Co.) has 5. Crater Lake is heavily visited. Those 5 records
almost certainly mean "nobody bothered" not "it isn't there."

This creates asymmetric reliability in absence data:
- Absence of a rare or sought-after taxon in a well-collected hex
  → fairly reliable signal
- Absence of a common taxon in a well-collected hex
  → ambiguous: genuine absence OR collector indifference

Practical consequence: taxon selection for the analysis matters enormously.
Common species are poor candidates for absence-based comparison unless
collector behavior can be characterized and corrected for.
Letharia is a reasonable choice: distinctive, sought-after, not so common
that collectors ignore it.

**However** — the original motivating hypothesis cuts against this pessimism:
absence patterns may partially rescue the signal that underreporting suppresses
in presence data. If a common taxon gets 5 records in Crater Lake NP instead
of 500, the presence count is noisy and unreliable. But if its *absence* from
surrounding lowland hexes is consistent and patterned, the absence structure
may carry the biogeographic signal that presence counts alone cannot reveal.

Underreporting compresses the dynamic range of presence data.
Absence patterns may restore it.

This is testable: does adding absence data improve biogeographic signal
specifically for common/underreported taxa more than for rare/sought-after ones?
If yes, that's a strong and non-obvious result.
The current void plot conflates two distinct things:
- Letharia-specific absence (the taxon isn't there)
- General sampling poverty (nobody has been there, for anything)

The SE Oregon void south of Tri-Cities is mostly the second — terra incognita,
not informed absence. The meaningful aposologic signal is where sampling
intensity is reasonable but Letharia still isn't found (e.g. Aberdeen/Hoquiam:
well-sampled, wrong habitat, genuine informed absence).

Some correction for general sampling intensity would sharpen the signal.
Options considered:
- Ratio: Letharia records / total lichen records per hex
- Residual: model expected Letharia from total effort, plot residual
- Threshold: only treat absences as informed if total hex count > minimum

**Caution on ratios and log transforms**: ratio (Letharia / total) is a
proportion bounded [0,1] with its own pathologies:
- 1/1 looks identical to 100/100 — same ratio, wildly different information
- Zeros in numerator (meaningful absence) vs zeros in denominator (no data)
  are fundamentally different things
- Ratio conflates relative frequency with absolute abundance

Better approach: keep effort and Letharia counts *separate*, use effort as
a covariate or filter rather than a divisor. Condition on effort, don't divide.

**McCune adaptive log transform** (noted for future use when log-transforming
sparse count data):
- c = Int(log(Min(x))) where Min(x) is smallest nonzero value
- d = 10^c
- Transform: log(x + d) - c
- Result: zeros stay zero, scale adapts to actual data range, order of
  magnitude preserved. More principled than arbitrary constants (e.g. log(x+1)).

---

### Plots produced this session

**Plot 0 — Letharia presence-only**
Same dark background and hex grid, cyan Letharia, no plasma absence surface.
Baseline for comparison.

![Letharia presence only](../output/letharia_00_presence_only.png)

Immediate reaction on seeing plots 0 and 1 side by side:
Plot 0 is a cloud of knowing with no texture to the not-knowing.
Plot 1 gives the dark spaces meaning.
You know vastly more when the absence data is added.

**The visual case for absence data is closed.** No statistics required,
no methodology section needed. This is Figure 1 for the methods paper.

---

**Plot 1 — Letharia: The Void (all species, genus level)**
Plasma absence surface (ignorance depth in km) + cyan Letharia presence
(alpha = log10 specimens). Epitome marker (red diamond) near
Aberdeen/Hoquiam/Grays Harbor — an informed absence: wrong habitat,
well-collected region.

![Letharia genus void](../output/letharia_01_genus.png)

---

1. **Letharia presence-only plot** — same hex grid, just specimen density,
   no absence surface underneath. Establishes the visual baseline.
2. **L. columbiana presence+absence plot** — requires species-level DB query
3. **L. vulpina presence+absence plot** — same
4. Compare presence-only vs presence+absence for each: does the absence
   surface add interpretable information beyond the presence dots alone?
   This is the core visual test of the aposologic hypothesis.

*DB path confirmed current: C:/Lichen/SQL/clh_2025_11.db*

---

### 2026.03.28 — Session 2: Species-level plots

**Plot 2 — L. columbiana: The Void**
![L. columbiana void](../output/letharia_02_columbiana_void.png)

**Plot 3 — L. vulpina: The Void**
![L. vulpina void](../output/letharia_03_vulpina_void.png)

**Observations:**
- More similarity than difference between the two species at this scale.
  Substantial overlap expected — congeners sharing broadly similar conifer
  forest habitat. Data behaving sensibly.
- *L. vulpina* dramatically stronger around Hood River Gorge and the
  St. Helens blast/succession area. Possibly reflects tolerance for
  disturbed or transitional forest vs. *columbiana* preference for older,
  more stable stands. Speculation — needs Bruce's input.
- *L. vulpina* more widespread overall (525 hexes, 2379 specimens vs.
  330 hexes, 1124 specimens for *columbiana*).

**Determination reliability caveat:**
Letharia has had taxonomic instability. Some columbiana records may be
misidentified vulpina and vice versa, especially older collections.
Colocations in the same hex could reflect genuine sympatry OR
misidentification noise — indistinguishable at this scale.

Ironic implication: absence data may be *more* reliable than presence data
in this context. A confident absence in a well-collected hex is less
susceptible to misidentification noise than a single ambiguous presence record.

**Color note:** gold for vulpina individual plots was a mistake — too close
to plasma yellow, fighting the ignorance scale. Changed to cyan throughout
for individual species plots. Gold (#FFD700) reserved for the two-species
combined plot only where color distinction is essential.

**Plot 4 — Both species: The Void**
![Both species void](../output/letharia_04_both_void.png)

Cyan = L. columbiana (on top), Gold = L. vulpina (underneath).
Legend positioning still needs work — deferred to next session.

**Overlap problem:** Where both species occupy the same hex, cyan wins
entirely — gold is hidden. Options for next session:
- Split hex geometry: fill north half for one species, south for the other
  (doable via sf polygon splitting but non-trivial)
- Third color for overlap cells (white or green) — simpler, may communicate
  just as clearly
- Accept the layering and add an overlap count to the legend

---

### Next session

- Fix plot 4 legend position
- Resolve overlap display for two-species plot
- Git commit all scripts and lab notes
- Begin thinking about numerical distance between species hex vectors
  corrected/regularized versions of raw data. Start here unless a specific
  problem is found.
- **Key fields**: `scientificNameRegularized`, `decimalLatitudeEd`,
  `decimalLongitudeEd`, `stateProvinceEd`, `countyEd`
- **County lookups**: always use `stateProvinceEd` + `countyEd` pairs —
  never county alone. Too many Washington Co., Franklin Co., etc. across states.
- **Orthography**: spaces replaced by underbar in all `...Ed` fields.
  County format: `Name_Co.` e.g. `Walla_Walla_Co.`, `Klamath_Co.`
- **Hex assignments**: not in `narrow` directly — need to join another table.
  Tables available: `full`, `narrow`, `New_England`, `ed_import`, `ed_import_2`,
  `done_import`, `county_lookup`, `violation_ids`, `conus_coords`.
  `conus_coords` is the likely candidate — checking structure.
