capture program drop _nwdialog
program _nwdialog
	syntax anything(name=dialogname)
    qui nwset
	// BUGFIX: was `r(names)' - nwset's own bare call returns the
	// loaded-network list as `r(nets)', not `r(names)' (confirmed
	// directly: `qui nwset' / `return list' shows only `r(nets)' and
	// `r(networks)', no `r(names)' at all) - this local was always
	// empty, so every dialog's network dropdown only ever got the
	// single blank placeholder entry pushed below, never any actual
	// network name. A pre-existing bug affecting every dialog in the
	// package, not introduced by this pass - found while live-testing
	// the rebuilt dialogs.
	local netlist = "`r(nets)'"
	if "`netlist'" != "" {
		.`dialogname'_dlg.netlist.Arrdropall
	}
	.`dialogname'_dlg.netlist.Arrpush " "
	foreach onenet of local netlist {
		.`dialogname'_dlg.netlist.Arrpush "`onenet'"
	}
end


capture program drop _nwdialog_append
program _nwdialog_append
	syntax anything(name=dialogname)
    qui nwset
	// BUGFIX: same `r(names)' -> `r(nets)' fix as _nwdialog above.
	local netlist = "`r(nets)'"
	if "`netlist'" != "" {
		.`dialogname'_dlg.netlist_append.Arrdropall
	}
	.`dialogname'_dlg.netlist.Arrpush " "
	foreach onenet of local netlist {
		.`dialogname'_dlg.netlist_append.Arrpush "main.cb_net.append `onenet'"
	}
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
