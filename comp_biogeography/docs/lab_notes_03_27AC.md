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

**7. Sampling intensity correction — handle with care**
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
