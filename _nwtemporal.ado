*! Helper of nwsave, nwuse, nwtoedge, nwduplicate and nwdropnodes: moves the temporal data of a network (event list, times of
*! the ties of a snapshot network, intervals) between a network and Mata globals or a data set. Subcommands:
*!   stash netname [, half]        network -> Mata globals __nwt_*   (labels of the nodes, so that node numbers may change)
*!   put netname [, filter]        Mata globals -> network           (filter: events with a node that is not in the network are dropped)
*!   pack netname, ego() alter() t1() [t2() value() tnet() half]   network -> data set in memory (replaces the data)
*!   take, tnet(#) type() tvars()               rows of the data set (variables _nw_t*) -> Mata globals
*!   drop                          removes the Mata globals
*! The temporal type and the names of the time variables travel in the globals __nwt_ty and __nwt_vars.
capture program drop _nwtemporal
program _nwtemporal
	gettoken sub 0 : 0, parse(" ,")
	if "`sub'" == "stash" _nwtemporal_stash `0'
	else if "`sub'" == "put" _nwtemporal_put `0'
	else if "`sub'" == "pack" _nwtemporal_pack `0'
	else if "`sub'" == "take" _nwtemporal_take `0'
	else if "`sub'" == "drop" _nwtemporal_drop
	else {
		di "{err}_nwtemporal: unknown subcommand `sub'"
		exit 198
	}
end

capture program drop _nwtemporal_drop
program _nwtemporal_drop
	capture mata: mata drop __nwt_ty __nwt_vars __nwt_l1 __nwt_l2 __nwt_t1 __nwt_t2 __nwt_v __nwt_nn __nwt_E __nwt_S __nwt_k
	// a failed capture leaves _rc standing, and nwuse reads _rc at the end of its loop
	capture confirm number 0
end

capture program drop _nwtemporal_stash
program _nwtemporal_stash
	syntax anything(name=netname) [, half]
	_nwtemporal_drop
	_nwsyntax `netname'
	mata: __nwt_ty = `netobj'->get_temporal_type()
	mata: __nwt_vars = `netobj'->get_timevar() + "|" + `netobj'->get_startvar() + "|" + `netobj'->get_endvar() + "|" + `netobj'->get_eventtimevar()
	mata: __nwt_nn = (`netobj'->get_nodenames())'
	if "`temporaltype'" == "event" {
		mata: __nwt_E = *`netobj'->get_eventlist()
		mata: __nwt_k = J(rows(__nwt_E), 1, 1)
		mata: __nwt_t1 = __nwt_E[., 3]
		mata: __nwt_t2 = J(rows(__nwt_E), 1, .)
		mata: __nwt_v = __nwt_E[., 4]
	}
	else if "`temporaltype'" == "snapshot" {
		mata: __nwt_E = *`netobj'->get_edge_time()
		mata: __nwt_t1 = __nwt_E[., 3]
		mata: __nwt_t2 = J(rows(__nwt_E), 1, .)
		mata: __nwt_v = J(rows(__nwt_E), 1, .)
	}
	else if "`temporaltype'" == "interval" {
		mata: __nwt_E = *`netobj'->get_edge_start()
		mata: __nwt_S = *`netobj'->get_edge_end()
		mata: __nwt_t1 = __nwt_E[., 3]
		mata: __nwt_t2 = __nwt_S[., 3]
		mata: __nwt_v = J(rows(__nwt_E), 1, .)
	}
	else {
		di "{err}network {bf:`netname'} is not temporal"
		exit 198
	}
	mata: __nwt_l1 = rows(__nwt_E) ? __nwt_nn[__nwt_E[., 1]] : J(0, 1, "")
	mata: __nwt_l2 = rows(__nwt_E) ? __nwt_nn[__nwt_E[., 2]] : J(0, 1, "")
	// an undirected snapshot/interval network lists each tie in both directions: half keeps one row per tie
	if "`half'" != "" & "`temporaltype'" != "event" {
		mata: st_local("__nwt_dir", strofreal(`netobj'->is_directed_boolean()))
		if `__nwt_dir' == 0 {
			mata: __nwt_k = (__nwt_E[., 1] :<= __nwt_E[., 2])
			mata: __nwt_l1 = select(__nwt_l1, __nwt_k)
			mata: __nwt_l2 = select(__nwt_l2, __nwt_k)
			mata: __nwt_t1 = select(__nwt_t1, __nwt_k)
			mata: __nwt_t2 = select(__nwt_t2, __nwt_k)
			mata: __nwt_v = select(__nwt_v, __nwt_k)
		}
	}
	mata: mata drop __nwt_E __nwt_nn
	capture mata: mata drop __nwt_S __nwt_k
	capture confirm number 0
end

capture program drop _nwtemporal_put
program _nwtemporal_put
	syntax anything(name=netname) [, filter]
	_nwsyntax `netname'
	if "`filter'" != "" {
		mata: __nwt_k = (nw_label_positions((`netobj'->get_nodenames()), __nwt_l1) :> 0) :& (nw_label_positions((`netobj'->get_nodenames()), __nwt_l2) :> 0)
		mata: __nwt_l1 = select(__nwt_l1, __nwt_k)
		mata: __nwt_l2 = select(__nwt_l2, __nwt_k)
		mata: __nwt_t1 = select(__nwt_t1, __nwt_k)
		mata: __nwt_t2 = select(__nwt_t2, __nwt_k)
		mata: __nwt_v = select(__nwt_v, __nwt_k)
	}
	mata: st_local("__nwt_ty", __nwt_ty)
	mata: st_local("__nwt_vars", __nwt_vars)
	if "`__nwt_ty'" == "event" {
		mata: `netobj'->set_eventlist(build_eventlist((`netobj'->get_nodenames()), __nwt_l1, __nwt_l2, __nwt_t1, __nwt_v))
	}
	else if "`__nwt_ty'" == "snapshot" {
		mata: nw_set_temporal_values(`netobj', __nwt_l1, __nwt_l2, __nwt_t1, J(0, 1, .), 0, 0)
	}
	else if "`__nwt_ty'" == "interval" {
		mata: nw_set_temporal_values(`netobj', __nwt_l1, __nwt_l2, __nwt_t1, __nwt_t2, 0, 1)
	}
	else {
		di "{err}unknown temporal type {bf:`__nwt_ty'}"
		exit 198
	}
	mata: `netobj'->set_temporal_type("`__nwt_ty'")
	local rest "`__nwt_vars'"
	forvalues k = 1/4 {
		local p = strpos("`rest'", "|")
		if `p' > 0 {
			local v`k' = substr("`rest'", 1, `p' - 1)
			local rest = substr("`rest'", `p' + 1, .)
		}
		else {
			local v`k' "`rest'"
			local rest ""
		}
	}
	mata: `netobj'->set_timevar("`v1'")
	mata: `netobj'->set_startvar("`v2'")
	mata: `netobj'->set_endvar("`v3'")
	mata: `netobj'->set_eventtimevar("`v4'")
	mata: `netobj'->set_temporal(1)
end

// the data set in memory is replaced by one row per event / observation of the network
capture program drop _nwtemporal_pack
program _nwtemporal_pack
	syntax anything(name=netname), ego(name) alter(name) t1(name) [t2(name) value(name) tnet(integer 0) half]
	_nwtemporal_stash `netname', `half'
	qui drop _all
	mata: st_local("__nwt_n", strofreal(rows(__nwt_l1)))
	qui set obs `__nwt_n'
	if `tnet' > 0 qui gen double _nw_tnet = `tnet'
	qui gen strL `ego' = ""
	qui gen strL `alter' = ""
	qui gen double `t1' = .
	mata: st_sstore(., "`ego'", __nwt_l1)
	mata: st_sstore(., "`alter'", __nwt_l2)
	mata: st_store(., "`t1'", __nwt_t1)
	if "`t2'" != "" {
		qui gen double `t2' = .
		mata: st_store(., "`t2'", __nwt_t2)
	}
	if "`value'" != "" {
		qui gen double `value' = .
		mata: st_store(., "`value'", __nwt_v)
	}
	qui compress `ego' `alter'
end

// rows of the variables _nw_tego _nw_talter _nw_tt1 _nw_tt2 _nw_tval whose _nw_tnet is tnet
capture program drop _nwtemporal_take
program _nwtemporal_take
	syntax , tnet(integer) type(string) tvars(string)
	_nwtemporal_drop
	mata: __nwt_ty = "`type'"
	mata: __nwt_vars = "`tvars'"
	mata: __nwt_k = selectindex(st_data(., "_nw_tnet") :== `tnet')
	mata: __nwt_l1 = rows(__nwt_k) ? st_sdata(__nwt_k, "_nw_tego") : J(0, 1, "")
	mata: __nwt_l2 = rows(__nwt_k) ? st_sdata(__nwt_k, "_nw_talter") : J(0, 1, "")
	mata: __nwt_t1 = rows(__nwt_k) ? st_data(__nwt_k, "_nw_tt1") : J(0, 1, .)
	mata: __nwt_t2 = rows(__nwt_k) ? st_data(__nwt_k, "_nw_tt2") : J(0, 1, .)
	mata: __nwt_v = rows(__nwt_k) ? st_data(__nwt_k, "_nw_tval") : J(0, 1, .)
	capture mata: mata drop __nwt_k
	capture confirm number 0
end
