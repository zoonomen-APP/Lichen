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

---

*Next session: species-level DB query for L. columbiana and L. vulpina,
then plots 2-4.*
