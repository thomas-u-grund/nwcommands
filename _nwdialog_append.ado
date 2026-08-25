capture program drop _nwdialog_append
program _nwdialog_append
	syntax anything(name=dialogname)
    qui nwset
	// BUGFIX: was `r(names)' - nwset's own bare call returns the
	// loaded-network list as `r(nets)', not `r(names)' (confirmed
	// directly via `qui nwset' / `return list') - this local was
	// always empty, so this program never actually appended anything.
	// A pre-existing bug affecting every dialog using it, not
	// introduced by this pass - found while live-testing the rebuilt
	// dialogs. This file's own copy (not the identically-named one
	// also defined inside _nwdialog.ado) is the one Stata's ado
	// lookup actually finds for `_nwdialog_append', since its
	// filename matches the program name.
	local netlist = "`r(nets)'"
	local netlist_rev ""
	local c : word count `netlist'
	forvalues i = 1 / `c' {
		local z = `c' - `i' + 1
		local next : word `z' of `netlist'
		local netlist_rev "`netlist_rev' `next'" 
	}

	.`dialogname'_dlg.netlist_append.Arrpush "main.cb_net.smartinsert"
	foreach onenet of local netlist {
		.`dialogname'_dlg.netlist_append.Arrpush "main.ed_net.smartinsert `onenet'"
	}

end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
