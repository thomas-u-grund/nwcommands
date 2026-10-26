capture program drop nw2clustering
program nw2clustering
	// Alias of nwclustering on a two-mode network (the two-mode form is nwclustering's default there); same options as always.
	syntax [anything(name=netname)][, measure(string) level(int 1) GENerate(string) replace RA]

	_nwsyntax `netname'
	if "`is2mode'" != "true" {
		di "{err}nw2clustering requires a two-mode network; see {help nwclustering} for one-mode networks."
		error 198
	}
	nwclustering `netname', measure(`measure') level(`level') generate(`generate') `replace' `ra'
	capture confirm number 1
end
