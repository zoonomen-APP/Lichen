# A Note on Absence Data and What It Might Be Good For
## Alan Peterson → Bruce McCune
## 2026.03.28

---

Bruce,

I teased you with some results of this work a while ago, and you asked
"why did you choose absence?"  I try to answer that here.

This is either interesting or crazy, and you're the right person to tell 
me which. It is probably both.

The short version: I've been treating absence data from the CLH as a
positive signal rather than a gap to be filled, and the results are
surprising enough that I wanted to walk you through the whole thing step
by step and get your reaction.

I'm calling the general framework "aposology" — the systematic study of
absences. That sounds more grand than I intend. What it really means is:
I think the pattern of what is NOT in the herbarium record tells you
something real, and I've been trying to figure out what.

---

## The Basic Idea

Here's the thing that got me started. Herbarium records have a profound
presence bias built into them at every level — ontological, methodological,
incentive, archival. A specimen exists, therefore it can be recorded.
Absence has no physical form, no accession number, no natural cartographic
home. Nobody names a new absence after themselves.

But here's what I kept thinking: a lichenologist walking through a forest
is not a passive recorder. They are an active filter. And the main activity
on a collecting trip is *NOT* collecting — they walk past thousands of lichens
and pick up a tiny fraction. That structured exclusion is not random. It is
patterned by training, expectation, prior literature, and the social
structure of the discipline.

If the exclusion is patterned, the absences are patterned. And if the
absences are patterned, they contain information.

That's the whole idea. Everything else is working out what that information
is and whether it's recoverable.

---

## Not All Absences Are Equal

Before getting into the method, it's worth distinguishing types of absence,
because they're not all the same thing.

**Absolute absences** carry no information — absence of lichen specimens
from the moon, for example. No expectation, no signal.

**Contingent absences** are the interesting ones. These are absences that
exist in the shadow of a reasonable expectation. If a highly common,
ecologically well-characterized lichen is absent from a record covering
apparently suitable, well-collected habitat — that absence is nearly
screaming. It has informational density proportional to how strong the
expectation was.

**Invisible absences** are things that couldn't have been recorded because
the category didn't yet exist. A taxonomic split retroactively creates
invisible absences in the historical record.

And then there's what I'm calling **aposological compounding** — which is
perhaps the most insidious. A taxon not considered interesting or not 
recognized as distinct in 1890 is absent from the record. 
That absence shapes the 1920 collector's
expectations — who has no reason to look for it. Which generates another
absence. The shadow deepens not because the taxon isn't there but because
the expectation system has progressively less room for it. The inverse also
operates: a taxon collected early, described by a famous lichenologist,
becomes "expected" — and therefore found more often — partly because the
expectation system is tuned to it.

---

## The Asymmetry of Presence and Absence

There's a fundamental asymmetry I keep coming back to. Determining presence
requires finding a summit — a point, a local maximum, unambiguously itself.
Determining absence requires solving a boundary problem. The mountain does
not end — it grades into foothills, into plain, without a formal stopping
point. Presence localizes. Absence diffuses.

This asymmetry is not a weakness of the absence data. It's a structural
feature that shapes what kinds of questions absence can answer. Perhaps it answers
large-scale questions well — the ones where the signal is spatially
autocorrelated across many taxa and many locations simultaneously.

---

## The Method: What I Actually Did

I started with the CLH database ~1 million CONUS48 lichen records.

**Step 1: Identify knowledge centers.**
I selected counties with at least 3,000 species-level records — places
where lichenologists have been active and systematic. I ended up with 84
such counties. These are the "centers of knowledge" — not random samples
of the continent, but places where we actually know something.

**Step 2: Find the top taxa in each center.**
For each of those 84 counties, I identified the 10 most frequently recorded
taxa. These are the locally dominant, well-characterized species — the ones
that define the local lichen flora for that county.

**Step 3: Ask where those taxa are absent.**
For each of the top 10 taxa in each center county, I asked: which of the
48 CONUS states does this taxon NOT appear in? This produces, for each
county, an absence profile — a list of states that are missing each of
its characteristic taxa.

**Step 4: Build the absence matrix.**
I assembled this into an 84 × 48 matrix. Rows are knowledge-center
counties. Columns are CONUS states. Each cell contains the number of that
county's top 10 taxa that are absent from that state (values 0–10).
So when I cluster the states, each state's profile is a vector of 84 such 
counts — one per knowledge center — reflecting how absent each center's 
characteristic fauna is from that state

This matrix is the heart of the analysis. It is a representation of the
continent's lichen flora as seen through the lens of absence — not where
things are, but where the things that might be there, aren't.

**Step 5: Cluster the states.**
I transposed the matrix — now each state has an 84-dimensional profile
describing how absent it is from each knowledge center's perspective — and
ran hierarchical clustering (Ward's method, Euclidean distance). I cut the
dendrogram at k=5 to get five zones.

I am not sure that Ward's method is the best (or even appropriate),
I squinted at your book to try to see if I was making a horrible error.
You will let me know if I did.

**Step 6: Map the result.**
Plot the five zones on a CONUS map. The algorithm has seen nothing but
numbers. It knows nothing about geography, climate, elevation, or
biogeography.

---

## The Result That Surprised Me

The five zones are almost entirely geographically contiguous.

That's the thing. An algorithm that saw only the matrix, with no
geographic information whatsoever, recovered something that looks
remarkably like a biogeographic regionalization of North America.

The zones roughly correspond to:
- A western/mountain arc
- A Great Plains/void zone (characterized by shared absence — both
  ecological and collector-based)
- A mid-latitude transitional band through the Midwest and Appalachians
- A boreal/Great Lakes northeastern zone
- A Deep South zone

---

## The Anomalies 

Every anomaly in the clustering tells a story about the data — and the
stories are interpretable.

**South Dakota clusters with the western states, not the Plains.**
Every naive geographic or climatic regionalization puts South Dakota with
North Dakota. The absence clustering puts it with Colorado and the Mountain
West. It's right — the Black Hills are a genuine Rocky Mountain outlier,
The absence profiles for South Dakota reflect real biogeographic structure, 
not just geographic proximity.

**Georgia clusters as mixed mid-latitude transitional, rather than as pure 
southern . I speculate that this is due to the Appalachian 
transitional zone making it into N. Georgia pulling the profile more
towards the Appalachian zone.**

**Delaware sits as an outlier.**
This one is not biology — it's data. Delaware has a total absence score of
604, the highest of any state. It's severely under-collected. The algorithm
can't distinguish "subtropical flora" from "nobody went there."

These anomalies are the most informative part of the
result. Every interpretable anomaly is evidence that the signal is real —
because if it were noise, the anomalies would be random and uninterpretable.

---

## The Thing I Was Worried About

I'll be honest about the worry that kept me up: collectors avoid common
taxa. They walk past a thousand Bryoria fremontii to collect the one
interesting thing they haven't seen before. So the absence matrix might be
measuring human preference gradients rather than ecology.

But the signal survived. Coherent zones, geographic
contiguity, interpretable anomalies. Why?

Collector avoidance is not random. It is structured. Collectors avoid
common taxa within ecological context — they still record them sometimes,
more often where they are truly dominant, and their choices still reflect
habitat structure. The bias is low-frequency, not white noise. And
low-frequency bias preserves large-scale structure. Ward's method doesn't
need perfection — it needs relative differences. The zones emerged from
relative differences in absence patterns.

What the matrix is actually measuring is:

    absence = f(ecology, history, effort)

That's information. The zonation maps the joint field
of biogeography and knowledge production simultaneously.

---

## What I Haven't Done Yet

This could very well still be a "so what?" result, if for example
the output is no different from a similar presence based analysis.

**Permutation control.** If I shuffle the state labels randomly and recluster,
does geographic contiguity survive? If yes, the result is artifact. If no,
the signal is real. I haven't run this yet and I should.

**Sensitivity analysis.** Does the zonation hold if I use 5 taxa per county
instead of 10? 15? Does it hold at the 4000-record threshold? 5000?
Different distance metrics? The results are suggestive but robustness is
unproven.

**The critical test.** Does the absence clustering ADD information not
recoverable from presence data alone? If you ran the same clustering on
presence data — which states share which taxa — would you get similar or
different zones? If absence and presence give the same answer, absence is
redundant (though perhaps computationally convenient). If they diverge,
absence is adding something.

**Trying at a different scale** I am eager to try this on WA/OR and 
see if it recognizes anything other than "Eastern" vs "Western" as we saw 
before.


---

## Where This Could Go

Even if the absence clustering turns out to be largely redundant with
presence data, I think there's a practical application that stands on its
own: identifying where future collecting would be most informative.

The zones have boundaries. Counties that sit on cluster boundaries — that
would shift from one zone to another with modest changes in their taxon
profile — are the places where a targeted collecting trip could most change
our understanding. That's a principled way to prioritize fieldwork.

And there's the bigger idea: the herbarium is not a sample of the world.
It's a sample of a historically and socially constructed version of the
world. All presence data is the visible tip of a structured iceberg of
absences. The tip cannot be properly interpreted without a theory of the
iceberg.

I'm not sure how far that idea goes if at all.
---

## My Questions for You

1. Does the general logic hold? Is there a reason the absence matrix
   should NOT produce structured geographic signal?

2. The anomalies — South Dakota, Georgia, Delaware — do they make sense
   to you lichenologically? Or do they suggest something is wrong with
   the data or the method?

3. Where would you expect this to fail? What perturbation would you
   try first?

4. Is there prior work I should know about? Has anyone used absence
   profiles this way in lichenology or adjacent fields?

5. I also wonder about combining the absence data with presence data
   for defining/delimiting a "region".

I've attached the zone maps and the heatmap. Happy to share the full
pipeline — it's SQL + R, reproducible, about 200 lines total.

Alan

---

*Attached: aposology_heatmap.png, aposology_state_zones.png,
aposology_zone_map.png, state_dendrogram.png*
