capture program drop nwpermute	
program nwpermute
	version 9.0
	syntax [anything(name=netname)], [ xvars replace nwreplace generate(string) SWAP SWAPS(integer -1)]
	if "`replace'" == "" & "`generate'" == "" {
		// Error-code coherence pass: was `999' (this package's own
		// convention for "loading would discard unsaved data" - an
		// unrelated situation this option-requirement check had
		// nothing to do with, reused here only by coincidence).
		// A missing required option is exactly what Stata's own 198
		// already means package-wide.
		di "{err}Either option {bf:replace} or {bf:generate} required."
		error 198
	}
	_nwsyntax `netname', max(1)
	// a two-mode network is permuted within its modes (the labels of the mode-1 nodes among themselves, the mode-2
	// labels among themselves); swap instead exchanges the partners of two ties at random (Maslov-Sneppen) and keeps
	// both degree sequences (R: bipartite::swap.web, tnet::rg_reshuffling_tm)
	if "`swaps'" != "-1" & "`swap'" == "" local swap swap
	if "`swap'" != "" & "`is2mode'" != "true" {
		di "{err}Option {bf:swap} needs a two-mode network."
		error 198
	}
	if "`swap'" != "" {
		if `swaps' == -1 {
			mata: st_local("swaps", strofreal(10 * sum(`netobj'->edgelist()[., 3] :!= 0) / 2))
		}
		if `swaps' < 1 {
			di "{err}Option {bf:swaps()} must be at least 1."
			error 198
		}
	}
	if "`generate'" == "" & "`replace'" != "" {
		if "`swap'" != "" {
			mata: `netobj'->permute_swap(`swaps')
		}
		else {
			mata: `netobj'->permute()
		}
	}
	if "`generate'" != "" {
		capture _nwsyntax `generate', other(_chk)
		if _rc == 0 & "`nwreplace'" == "" & "`replace'" == "" {
			di "{err}Network {bf:`generate'} already exists; use {bf:nwreplace} or specify another name in {bf:generate()}"
			error 99
		}
		capture nwdrop `generate'
		nwduplicate `netname', name(`generate')
		_nwsyntax `generate'
		if "`swap'" != "" {
			mata: `netobj'->permute_swap(`swaps')
		}
		else {
			mata: `netobj'->permute()
		}
	}
	if "`xvars'" != "" {
		nwload `netname'
	}
end
