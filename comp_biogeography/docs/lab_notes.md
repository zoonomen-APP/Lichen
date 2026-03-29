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

---

### 2026.03.28 — Session 3: Three-zone delta plot

**Plot 5 — Three-Zone Delta**
![Three-zone delta](../output/letharia_05_delta.png)

Three zones:
- Cyan = L. columbiana only
- Gold = L. vulpina only
- White→gold/cyan = co-occurrence, colored by fourth-root delta
  (vulpina^0.25 - columbiana^0.25), fully opaque over void surface

Fourth-root transform chosen for co-occurrence delta: defined at zero,
no arbitrary constants needed, closely approximates log for larger values.

Legend handled via `ggtext` colored subtitle — cleaner than annotate blocks
which kept landing on map content.
Required packages added: `ggnewscale`, `ggtext`.

**SE Oregon cluster observation:**
Multiple tight clusters of all three zone types in deep void territory
(SE Oregon, likely Steens Mountain / Warner Mountains area). Pattern is
structured, not random noise — raises two hypotheses:

1. Real isolated mountain-island populations with genuine species interaction
   zone — ecologically plausible given elevation and conifer habitat
2. Determination uncertainty concentrated in a region worked by few collectors
   — consistent misidentification habits could produce structured-looking signal

Distinguishing these requires: who collected those records, how many specimens,
what institutions hold them. A targeted determination review for SE Oregon
Letharia records is warranted before treating those clusters as biogeographic
signal.

This is a concrete example of the "productive uncertainty zone" concept —
these hexes are maximally interesting and maximally uncertain simultaneously.
Interactive hex querying (deferred idea #5 from session 1) would make this
investigation immediate rather than requiring a manual DB query.

**Script naming convention adopted:**
- `letharia_species_dataprep.r` — DB queries, data prep, RDS output
- `letharia_void_plots.r` — single-taxon presence and void plots (plots 0-3)
- `letharia_compare.r` — cross-taxon comparison plots (plots 4+)

---

### Next session

- Git commit all scripts and lab notes
- Query SE Oregon Letharia records: collector, institution, specimen count
- Consider presence-only version of three-zone delta for direct A/B comparison
  with absence-weighted version
- Begin numerical distance between species hex vectors

---

### 2026.03.28 — Theoretical observations (inter-session)

**10. Information value of a new record is location-dependent**

The spatial distribution of known records says something about the information
content of a newly found specimen. A new record in a well-sampled, densely
occupied hex adds almost nothing — expected, confirmed, unremarkable. The same
species found in a deep-void hex is a different kind of event: it either
confirms a real outlier population, or triggers recalibration of the zone.

This suggests a formal framework for assigning *information value* to new
finds — essentially the inverse of sampling density combined with the
prior expectation for that taxon in that location.

**11. The trophy find critique**

The lichen community places high value on "rare" taxa and trophy finds.
But an infrequently encountered taxon in an undersampled environment is
basically what one would expect. The excitement is epistemologically
unwarranted — "rare" is being conflated with "unlooked-for."

This was part of the original thinking underlying aposology. The absence
framework provides a way to distinguish genuine rarity from sampling artifact.

**12. The inversion: common taxa in zones of low expectation**

A common, usually-ignored taxon found in a zone-of-low-expectation may be
far more scientifically interesting than a "rare" taxon found where rarity
is simply an artifact of undersampling.

A new Letharia vulpina in the Cascade spine: unremarkable.
The same species in a deep-void Harney Basin hex: potentially astounding —
either confirming a real outlier population or forcing recalibration of the
zone boundary.

This is a direct challenge to how the lichen community assigns scientific
value to finds. Worth developing formally.

**13. Partitioning zones from presence AND absence (suggestion from Alan's son)**

Region/zone establishment should be based on BOTH presence and absence
signals — not presence alone. The three-zone delta plot is an embryonic
version of this: the zones that emerge aren't just "where things are" but
"where things are relative to where they could plausibly be given what we
know."

This connects to the broader aposological framework: zones defined by
knowledge structure rather than occurrence alone would be more ecologically
honest and potentially more predictive.

*[Further thoughts expected — space left for additions]*

---

### 2026.03.28 — County-based aposological classification (prior work recovered)

Three outputs recovered from prior analysis — R code lost but outputs preserved.
This is the original proof-of-concept that absence data carries biogeographic signal.

**Method (reconstructed):**
1. Identify 36 high-density counties (≥5000 species-level records) as
   "knowledge centers"
2. For each center county, identify the 10 most frequent taxa
3. For each state, count how many of each center's top 10 taxa are absent
4. Build a matrix: center counties × states, values = taxa absent (of 10)
5. Cluster states by absence profile using Ward's hierarchical clustering
   (hclust, ward.D2)
6. Cut dendrogram at k=5 zones, map results

**Tunable components:**
- Number of knowledge centers (threshold for "high density") — went low first,
  then bumped up to 36
- Number of top taxa per center (chose 10)
- Distance measure (Ward's)
- Number of zones k (chose 5)

**Output 1 — Aposological Heatmap:**
![Aposological heatmap](../output/aposology_heatmap.png)
36 center counties as rows, states as columns, colored by taxa absent (of 10).
Ordered by median taxon breadth — reveals block structure naturally.

**Output 2 — State Dendrogram:**
![State dendrogram](../output/state_dendrogram.png)
Ward's hierarchical clustering of states by taxon absence profile.
Five clean groups emerge.

**Output 3 — Aposological State Zones:**
![Aposological state zones](../output/aposology_state_zones.png)
Five zones mapped across CONUS48. Algorithm had NO geographic information —
only taxon absence profiles.

**The two stunning validations:**

*South Dakota with Colorado, not North Dakota:*
Every naive geographic or climatic regionalization puts SD with ND — adjacent,
similar climate, similar agriculture. The absence clustering puts SD with
Colorado. It is right: the Black Hills are a genuine Rocky Mountain outlier,
a sky island of montane conifer forest in the Great Plains. The lichen flora
reflects that. Wetmore collected there systematically — the absence profiles
for SD reflect real knowledge, not a void. The algorithm found a biogeographic
truth that geography alone would miss.

*Georgia not with the Deep South:*
Louisiana, Mississippi, Alabama, Florida cluster together — Gulf coastal plain,
humid subtropical. Georgia is pulled toward the Appalachian green zone instead.
Because the Blue Ridge extends into north Georgia, and that region's lichen
flora has more in common with Tennessee, North Carolina, Virginia than with
the coastal plain states to its west and south.

Both cases: absence data smarter than geography. Not seeing state boundaries
or latitude — seeing lichen community structure, which reflects real ecological
and biogeographic history.

**Abstract-level result:**
"States were clustered by taxon absence profiles without geographic information.
The resulting zones recovered known biogeographic discontinuities including
the Black Hills sky island and the southern Appalachian extension into Georgia."

**Output 4 — Aposological Zone Map (Knowledge Centers):**
![Aposological zone map](../output/aposology_zone_map.png)
84 high-density counties (≥3000 records) plotted as dots, colored by their
own zone assignment. Shows the spatial distribution of knowledge centers
and their zone coherence.

Notable features:
- Dense western coast cluster (green/purple) — heavily collected CA/OR/WA
- Great Lakes red cluster — Keweenaw, Bayfield, Cheboygan, Cook, Alger —
  northern hardwood/boreal zone
- Appalachian red spine — Yancey, Haywood NC — consistent with Georgia result
- Isolation cases validating the method:
  - Custer Co. (SD, red) — alone in Great Plains, Black Hills confirmed
  - Flathead Co. (MT, blue) — isolated northern Rockies
  - Brewster Co. (TX, purple) — Big Bend, ecological outlier
- East Baton Rouge (orange) — anomalous Louisiana county visible in heatmap,
  clusters consistently here as well
- Coherence between county-level and state-level zone maps is itself a
  validation — zones consistent across scales

This was the fourth output, recovered after the others.

**The continental void — a more nuanced interpretation:**
Initial interpretation: voids = collecting gaps (lichenologists don't go there).
This is partly correct but misses a more fundamental point.

The agricultural interior void is a compound signal:

1. **Genuine ecological poverty** — wrong habitat. Epiphytic macrolichens
   need trees: old bark, stable humidity, clean air. Iowa cornfields have
   none of that. Few trees, young, isolated, disturbed — supporting a
   depauperate flora of common, widespread species.

2. **Collector indifference** — what IS there is commonplace and unrewarding.
   Nobody collects Letharia-equivalent common taxa in marginal habitat.

3. **Collecting bias** — lichenologists go where interesting things are,
   which reinforces #1 and #2.

All three reinforce each other. The void is not simply "nobody went there"
— it is partly "there isn't much worth going for."

**The deeper implication for aposology:**
This makes the framework MORE interesting in void zones, not less.
A well-collected void hex — someone went, found only common things, didn't
collect much — is a fundamentally different void than an unvisited hex.
The absence profile of "only common taxa, nothing interesting found" is
itself biogeographic information.

Low specimen counts in void zones reflect:
- Genuine ecological poverty (few epiphytic macrolichens)
- Common taxa present but not collected (undercollection bias)
- Both simultaneously — and the two are currently indistinguishable
  without additional collector characterization data

Distinguishing ecological poverty from collector indifference is a core
challenge for the absence confidence weighting scheme.

---
The knowledge center map reveals two great diagonal voids that together
almost bisect the continent:

- **Northern void**: Pennsylvania/New York west through Ohio, Indiana,
  Illinois, Iowa to North Dakota — nearly no knowledge centers
- **Southern void**: mid-Atlantic coast through Carolina interior, Georgia
  inland, Alabama, Mississippi, across to Oklahoma, New Mexico

Between the voids: Great Lakes cluster and Appalachian spine.
Outside them: boreal/Great Lakes zone north, Gulf coastal plain south.

What's in the voids? Largely agricultural landscape — corn belt, wheat belt,
cotton belt. Not because lichens aren't there, but because lichenologists
don't go there. These are **collecting boundaries**, not biogeographic
boundaries.

This loops directly back to the trophy find critique: the most scientifically
valuable collecting would be systematic work in those void zones — not hunting
rarities in already well-known areas. The aposological framework makes that
argument formally. The void is not absence of lichens. It is absence of
knowledge.

**Full pipeline recovered — all files intact:**

Scripts (`/c/Lichen/aposology/scripts/`):
- `aposology_pipeline.sql` — 5000 threshold, 36 counties
- `aposology_pipeline_3000.sql` — 3000 threshold, 84 counties
- `aposology_visualizations.R` — reads TSV, builds heatmap and breadth map
- `aposology_zonation.R` — reads absence matrix, clusters, maps zones

Intermediate files (`/c/Lichen/aposology/output/`):
- `top36_counties_aposology_species.tsv` — SQL output, 5000 threshold
- `top84_counties_aposology_species.tsv` — SQL output, 3000 threshold
- `absence_matrix_84x48.tsv` — 84 counties × 48 states, values = n top taxa absent
- `county_coords.tsv` — coordinates for 36 knowledge centers
- `county_coords_84.tsv` — coordinates for 84 knowledge centers
- `county_breadth_summary.tsv` — median taxon breadth per county

Output plots (all present):
- `aposology_heatmap.png`
- `aposology_breadth_map.png`
- `aposology_zone_map.png`
- `aposology_state_zones.png`
- `county_dendrogram.png`
- `state_dendrogram.png`

**One gap**: the pivot from TSV → absence matrix is not in any recovered
script — was done interactively. Must be made explicit when porting to
hex grid. Logic is straightforward: for each county × state pair, count
how many of the top 10 taxa are absent.

**Pipeline structure:**
SQL → TSV (long format) → [pivot] → matrix (wide) → zonation.R → plots

---

**Next steps for this analysis:**
- Write explicit pivot script (TSV → absence matrix) to close the gap
- Port pipeline to hex grid — SQL needs hex_id instead of county
- Experiment with tunable components (n centers, n taxa, k zones)
- Compare presence-only vs absence-weighted versions directly
- This is the analysis to send to Bruce alongside the Letharia plots

---

**14. Rarity should be redefined**

The current reward structure of lichenology is miscalibrated. "Rare" taxa
found in well-known regions add a data point to a well-characterized
distribution — scientific information gain is small. Trophy bagging.

A common taxon confidently identified in a void zone is a genuine range
extension, a habitat characterization, a data point where none existed.
Information gain is large. The community doesn't celebrate it because
there's no trophy.

True rarities at this stage of knowledge are somewhat ho-hum scientifically.
The exciting finds — the ones that actually move the needle on understanding
— are common taxa turning up where they weren't expected, or void zones
turning out to have coherent floras that nobody had bothered to document.

The aposological framework provides a formal basis for this revaluation:
information value of a find = f(void depth, prior expectation, taxon
commonness in similar zones). A common taxon in a deep void may score
higher than a "rare" taxon in a well-sampled region.

**15. The iNaturalist component — documenting common taxa in voids**

iNaturalist has already solved the "common things are worth recording"
problem for birds and plants. Citizen scientists photograph house sparrows
and dandelions, and presence data for common species across void zones
turns out to be enormously valuable.

The lichen equivalent: confident documentation of common, readily identified
macrolichens from void zones. Requires higher bar than birds/plants
(identification confidence), but for distinctive macrolichens with clear
morphology it is not unreasonable.

This would require:
a) A cultural shift — celebrating void-filling over trophy-hunting
b) A platform component that explicitly rewards void-zone records
c) Identification confidence filtering — expert verification or
   restriction to confidently identified common taxa

**16. The NOT FOUND dataset — the hardest problem**

Creating a dataset that includes "visited but not found" records from
competent, experienced, motivated expert observers. This is the lichen
equivalent of a breeding bird atlas "visited but not detected" record.

Currently:
- Infrastructure doesn't exist in any herbarium or biodiversity database
- Culture doesn't support it — no mechanism to deposit a negative result
- No obvious repository for structured absence observations

This would be transformative for the aposological framework. Currently
absence confidence is *inferred* from positive context (who collected
nearby, how much, what else did they find). Direct expert negative
observations would replace inference with measurement.

Possible avenue: a structured field protocol where expert collectors
explicitly record "searched for X, not found" alongside their positive
collections. Even a small dataset of high-quality negative observations
would be enormously valuable for calibrating the confidence weighting
scheme.

Ask Bruce: has anything like this been attempted in lichenology?
The bryophyte community may have relevant experience.
