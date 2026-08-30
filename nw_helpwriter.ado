*! nw_helpwriter: stamps a command's already-existing, separately-maintained
*! `.sthlp' file with a "last certified : DATE" trailer once its own
*! cscripts/test_<cmd>.do suite passes - the successor to this file's own
*! former behavior of first OVERWRITING the .sthlp from a `/*** {smcl} ...
*! ***/' comment block embedded at the top of `<cmd>.ado', which this
*! package no longer maintains (help files are authored and edited
*! directly as their own standalone .sthlp files - the embedded copies had
*! already drifted out of sync with real edits in practice, e.g.
*! nwergm.ado's own embedded copy vs. the real, actively-maintained
*! nwergm.sthlp differed by dozens of lines - and running the old
*! extract-and-overwrite step would have silently discarded every direct
*! .sthlp edit made since the embedded copy was last touched). See
*! nw_deployfile.ado's own git history for the sibling tool this same
*! change retires outright (unused elsewhere in this package, same
*! extract-and-overwrite mechanism, no callers to update).
capture program drop nw_helpwriter
program nw_helpwriter
	syntax [anything(name=cmd)]

	capture confirm file "`cmd'.sthlp"
	if _rc {
		di as error "nw_helpwriter: `cmd'.sthlp not found. Help files are maintained directly now, not generated from `cmd'.ado - create `cmd'.sthlp by hand first, then re-run this to certify it."
		exit 601
	}

	capture noisily do cscripts/test_`cmd'.do
	if _rc == 0 {
		mata: _nw_helpwriter_stampcertified("`cmd'.sthlp", c("current_date"))
	}
end

// Rewrites `fn' with any existing trailing "last certified : ..." line(s)
// removed, then appends one fresh stamp - so re-running certification
// refreshes the stamp in place instead of stacking a new one under every
// old one.
capture mata: mata drop _nw_helpwriter_stampcertified()
mata:
void function _nw_helpwriter_stampcertified(string scalar fn, string scalar cdate)
{
	string scalar line
	string rowvector lines
	real scalar fh, n

	fh = fopen(fn, "r")
	lines = J(1,0,"")
	line = fget(fh)
	while (line != J(0,0,"")) {
		lines = lines, line
		line = fget(fh)
	}
	fclose(fh)

	n = cols(lines)
	while (n > 0 & strpos(lines[n], "last certified :") == 1) {
		n = n - 1
	}
	if (n > 0) lines = lines[1..n]
	else lines = J(1,0,"")

	// Mata's fopen(fn,"w") errors ("file already exists") rather than
	// truncating an existing file the way Stata's own "write replace"
	// does - unlink() first so re-stamping an already-stamped file works
	unlink(fn)
	fh = fopen(fn, "w")
	for (n=1; n<=cols(lines); n++) {
		fput(fh, lines[n])
	}
	fput(fh, "last certified : " + cdate)
	fclose(fh)
}
end
