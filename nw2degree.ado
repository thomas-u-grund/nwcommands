
capture program drop nw2degree
program nw2degree, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace silent alpha(string) BINary RAW]
	set more off

	_nwsyntax `netname', max(9999)
	if "`alpha'" != "" {
		capture confirm number `alpha'
		if _rc {
			di "{err}Option {bf:alpha()} must be a number."
			error 198
		}
		if "`binary'" != "" & real("`alpha'") != 0 {
			di "{err}Options {bf:binary} and {bf:alpha()} cannot be combined."
			error 198
		}
	}

	if `networks' > 1 {
		local k = 1
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'

		if "`is2mode'" != "true" {
			noi di "{err}nw2degree requires a two-mode network; `netname_temp' is one-mode. See {help nwdegree} instead."
			error 198
		}

		if "`generate'" == "" {
			noi di "{err}option {bf:generate()} required."
			error 198
		}
		local netgenerate "`generate'"

		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`k'} already exists; specify {bf:replace}"
			err 99
		}

		// BUGFIX: a bare "capture drop X" is subject to Stata's default
		// variable-name abbreviation (set varabbrev on) - if X does NOT
		// exist yet but a DIFFERENT, longer variable happens to have X
		// as a literal prefix (e.g. calling nwdegree on a netlist mixing
		// a two-mode network with a one-mode one: this redirect's own
		// unsuffixed base name is always a prefix of nwdegree's own
		// suffixed one-mode output, "basevar_netname"), this silently
		// dropped that unrelated, already-computed variable instead of
		// safely no-op'ing - confirmed directly while writing the Paths
		// & Ego Networks / centrality tutorials' own test coverage.
		// Guarding the drop behind the same exact-match confirm already
		// used for the "already exists" check above eliminates the
		// ambiguity entirely: skip the drop when the exact name doesn't
		// exist (nothing to safely drop), and once it's confirmed to
		// exist, Stata always resolves an exact literal match over an
		// abbreviation candidate, so the drop can no longer go astray.
		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 {
			drop `netgenerate'`k'
		}
		gen `=cond("`valued'" == "true", "double", "")' `netgenerate'`k' = .
		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		// align row i of the data set with node i of this network before the
		// positional st_store() below (a data set that was sorted or reordered, or
		// synced to another network such as a two-mode projection, would otherwise
		// receive the values on the wrong rows)
		_nwsyncrows `netname_temp'
		mata: st_rclear()
		_nwsyntax `netname_temp'
		// tie values: the strength on a valued network (as nwdegree), the number of ties with binary or alpha(0)
		local __alpha 0
		if "`alpha'" != "" {
			local __alpha = real("`alpha'")
		}
		else if "`valued'" == "true" & "`binary'" == "" {
			local __alpha 1
		}
		if "`raw'" != "" {
			// the degree itself (tnet::degree_tm, igraph::degree), without the division by the size of the other mode
			mata: st_store((1::`nodes'), "`netgenerate'`k'", `netobj'->calculate_2mode_degree(`__alpha') :* ((strtoreal(`netobj'->get_modes()) :== 1)' :* `netobj'->get_nodes_mode2() :+ (strtoreal(`netobj'->get_modes()) :== 2)' :* `netobj'->get_nodes_mode1()))
		}
		else {
			mata: st_store((1::`nodes'), "`netgenerate'`k'", `netobj'->calculate_2mode_degree(`__alpha'))
		}

		// see nwbrokerage.ado's own header comment for why this is
		// needed: quietly/mata:-only commands above do not refresh _rc
		// on their own, so the "already exists" probe's own stale rc
		// would otherwise leak out as this command's own exit code.
		capture confirm variable `netgenerate'`k', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			if "`raw'" != "" noi di "{txt}  (raw degree: not divided by the size of the other mode)"
			if "`valued'" == "true" {
				if `__alpha' == 0 noi di "{txt}  (valued network, tie values not used: degree is the number of ties)"
				else if `__alpha' == 1 noi di "{txt}  (valued network: degree is the strength, the sum of the tie values; {bf:binary} gives the number of ties)"
				else noi di "{txt}  (valued network: degree is k (s/k)^alpha, alpha = `__alpha')"
			}
			noi sum `netgenerate'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
