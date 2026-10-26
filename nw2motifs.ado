capture program drop nw2motifs
program nw2motifs, rclass
	version 12
	// Alias of nwmotifs on a two-mode network (the two-mode form is nwmotifs' default there); same options as always.
	syntax [anything(name=netname)] [, SIXnode GENerate(string) replace MATrix(string) NORMalise POSNorm(string) silent]

	_nwsyntax `netname', max(1)
	if "`is2mode'" != "true" {
		di "{err}nw2motifs requires a two-mode network; {bf:`netname'} is one-mode. See {help nwmotifs} for one-mode networks, or {help nw2set}."
		error 198
	}
	nwmotifs `netname', `sixnode' generate(`generate') `replace' matrix(`matrix') `normalise' posnorm(`posnorm') `silent'
	return add
	capture confirm number 1
end
