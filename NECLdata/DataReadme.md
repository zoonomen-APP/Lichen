## Fields of data derived from downloaded CLH data sets that are used in our study. 2024.11.23

1. "id"  



	The "id" field is reproduced from the CLH dataset, with one exception: "pseudo id's" have been added to the dataset 
	for the 398 Maine records added to the dataset for this analysis. These added records can be recognized as eleven 
	digit numbers starting with the digits 11012. Apart from the added records the id's enable direct access to CLH 
	records for verification and comparison (see below). Only the "id" field is suitable for retrieval of individual 
	CLH records, but unfortunately, the "id" value does not show up in the output of Portal queries.  Fields like 
	"catalogNumber" (which *does* allow value entries for searching via the Portal) are not universally present 
	in all specimen records ( they are present in only about half), so can not be relied upon for retrieving records.

	The "id" value CAN be used for CLH record retrieval by simply appending the "id" number
	to the stem URL: "https://lichenportal.org/portal/collections/individual/index.php?occid="
	for example: given the "id" 480727 the record can be retrieved with
	https://lichenportal.org/portal/collections/individual/index.php?occid=480727

2. County. ("countyAPP")

	In our version of the dataset, the county names are regularized in spelling and orthography.
	Underbar is used in the place of space, both within the county name and between the county name
	and the "Co." designator. Example: Grand_Isle_Co. This allows recognition of a county name 
	that is unambiguous as to county and is a single string.

3. State ("stateProvinceAPP")

	In our version of the dataset, the state names are regularized in spelling and orthography.
	They are listed as: Maine, New_Hampshire, Vermont, Massachusetts, Connecticut, Rhode_Island.
	In names of states and counties the underbar is used in the place of "space" to render the name
	as an unambiguous state name in a single string.

4. scientificName ("scientificNameJWHAPPed")

	No genus only records are included. The names in this field have been evaluated by the senior author,
	and either accpeted as is, or replaced with a currently acceptable name when possible.

5. collecorName ("recordedByAPPed")

	Our goal was regularization and disambiguation of collector names. This was mostly, but only partially achieved.
	Some ambiguations remain and may never be resolvable. The orthographic standard we attempted to apply was
	Surname,Initial1.Initial2.,Modifier_if_present; e.g., Howe,R.H.,Jr. A "space semicolon space" ( ; ) is used 
	for separation of individual names if multiple collectors are listed.
	
6. eventDate ("eventDateAndPseudodateAPPed")

	Our dates are rendered as Year.Mo.Da (e.g. 2024.11.23).
	Three kinds of distinguishable "dates" are present.
		a. A date like 1988.07.15 means the date was either transferred directly from the record
			OR, with the date missing, the record was similar enough to another record (locality, collector) 
			that the date was assumed to be the same.
		b. A date rendered as Year.00.00 (e.g. 1910.00.00) means that only 1910 was present in the record.
		c. A date rendered as Year (e.g. 1910) means that this is a "pseudodate" which we generated to fill in large numbers 
			of missing dates, when there was enough constraint (collector, same state, same region) to resample existing
			dates to produce a larger sample to demonstrate the pattern.

		It is useful to re-emphasize what the "event" in "eventDate" is.  It is generally held to be the
		date of specimen collection, however in some instances this demonstrably is not the case. It can 
		represent the date a collection was sold or donated, or the date assigned to a large collection where
		the individual samples do not have individual dates, or such dates being present were not recovered.

7. locality ("localityAPPed")

	The goal here was regularization and appropriate aggregation. In some instances the locality was 
	inferred when absent. This was done if the same collector and date were present uniformly
	in other records.  Deciding on appropriate aggregation was an interesting and challenging task. 
	Many localities could have been aggregated to "White_Mountains" but were not, and no doubt, some localities were 
	thus aggregated when it may have been better to keep them distinct.

2024.12.19
