capture program drop nwpermute	
program nwpermute
	version 9.0
	syntax [anything(name=netname)], [ xvars replace generate(string)]
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
	if "`generate'" == "" & "`replace'" != "" {
		mata: `netobj'->permute()
	}
	if "`generate'" != "" {
		capture nwdrop `generate'
		nwduplicate `netname', name(`generate')
		_nwsyntax `generate'
		mata: `netobj'->permute()
	}
	if "`xvars'" != "" {
		nwload `netname'
	}
end
