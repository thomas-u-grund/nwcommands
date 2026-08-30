
capture program drop nwpreserve
program nwpreserve
	unw_defs
	// BUGFIX: was unconditional - calling nwpreserve a second time
	// before an intervening nwrestore silently overwrote the previously
	// preserved snapshot with no warning, permanently losing it -
	// unlike Stata's own preserve, which errors "already preserved",
	// despite nwrestore.sthlp explicitly claiming this pair works
	// "exactly like Stata's own preserve/restore pair".
	capture confirm file `nw_tempfile'.nwdta
	if _rc == 0 {
		di "{err}Already preserved; nwrestore first."
		error 621
	}
	capture nwsave `nw_tempfile', replace
	if _rc != 0 {
		di "{err}Cannot write to working directory.{txt}"
	}
end
