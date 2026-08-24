/***
{smcl}
{* *! 21dec2017 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwrestore {hline 2}}Restore network data previously preserved{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:nwrestore}


{marker description}{...}
{title:Description}

{pstd}
{cmd:nwrestore} restores network data (including all normal Stata variables) previously saved by
{help nwpreserve:nwpreserve} - the network-aware counterpart of Stata's own {help preserve:preserve}/
{help restore:restore} pair. If nothing was preserved (or it was already restored once), {cmd:nwrestore}
reports "Nothing to restore" and does nothing further.

{pstd}
The temporary file {cmd:nwrestore} reads from is deleted once restored, so a given {help nwpreserve:nwpreserve}
call can only be restored once - exactly like Stata's own {help preserve:preserve}/{help restore:restore}.



{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes. Signed: yes. Two-mode: yes - restores the full working state saved by {help nwpreserve}, independent of any of these properties.

{title:Also see}

   {help nwpreserve}, {help restore}, {help preserve}

***/

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
