
capture program drop nwrestore
program nwrestore
	unw_defs
	capture confirm file `nw_tempfile'.nwdta
	if _rc != 0 {
		di "{err}Nothing to restore"
		// BUGFIX: left a stale nonzero _rc (601, from the `confirm
		// file' check just above) after this documented no-op path,
		// even though it does not halt the calling do-file - a caller
		// checking _rc right after this command saw a leftover probe
		// result, not this command's own actual (successful, "nothing
		// to do") outcome. A harmless, always-succeeding `capture
		// confirm number' resets it explicitly, matching this
		// package's own established idiom for exactly this situation
		// (see nwaltergen.ado's/nwbrokerage.ado's own header comments).
		capture confirm number 1
		exit
	}
	// BUGFIX: was `clear' - nwuse.ado's own syntax line only recognizes
	// the option token `nwclear' (not plain Stata `clear') to authorize
	// discarding a currently in-memory network; the literal `clear'
	// token fell through nwuse's own catch-all `*' and never actually
	// suppressed its "data in memory would be lost" guard, so nwrestore
	// failed in exactly the canonical preserve/modify/restore workflow
	// (any network still registered at restore time - i.e. nwclear
	// wasn't manually called first) - the whole point of a
	// preserve/restore pair.
	nwuse `nw_tempfile', nwclear
	erase `nw_tempfile'.nwdta
end
