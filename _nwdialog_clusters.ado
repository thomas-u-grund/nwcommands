capture program drop _nwdialog_clusters
program _nwdialog_clusters
	// BUGFIX: nwdendrogram is the one dialog whose leading argument is
	// a Stata *cluster* name (from nwhierarchy's own results), not a
	// loaded network - the generic dialog generator's own "anything()
	// positional means pick a network" assumption doesn't hold here.
	// This mirrors _nwdialog.ado exactly, but populates from `cluster
	// dir' (Stata's own native command) instead of `nwset'.
	syntax anything(name=dialogname)
	qui cluster dir
	local clusterlist = "`r(names)'"
	if "`clusterlist'" != "" {
		.`dialogname'_dlg.clusterlist.Arrdropall
	}
	.`dialogname'_dlg.clusterlist.Arrpush " "
	foreach onecluster of local clusterlist {
		.`dialogname'_dlg.clusterlist.Arrpush "`onecluster'"
	}
end
