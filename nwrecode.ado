capture program drop nwrecode
program nwrecode
	version 9
	syntax anything(name=arg) [, into(string) generate(string) prefix(string) *]

	if "`arg'" == "" {
		exit
	}
	
	if "`into'" != "" {
		local generate "`into'"
	}
	
	local ruleStart = strpos("`arg'", "(")
	local netname = substr("`arg'",1, `=`ruleStart'-1')
	local rules = substr("`arg'",`ruleStart',.)

	// was "_nwsyntax_other `netname', max(9999)" - _nwsyntax_other is
	// incompatible with the modern network storage architecture (it
	// references a legacy nw_mata<id> Mata global that no longer
	// exists - the same bug already found and fixed in nwcloseness
	// this session). nw_syntax's own other() option gives the exact
	// same othernetname/othernodes/otherid/otherdirected naming
	// convention _nwsyntax_other used, so it's a direct drop-in.
	nw_syntax `netname', max(9999) other(other)

	preserve
	tokenize `generate'
	local i = 1
	foreach onenet in `othernetname' {
		// was "_nwsyntax `onenet'" - the deprecated _nwsyntax wrapper
		// never re-exports `directed' at all (only netobj/id/netname/
		// networks), so this local was always empty; nw_syntax
		// exports it directly.
		nw_syntax `onenet'
		local onedirected `directed'
		// was "forcedirected" - nwtoedge has no such option; the
		// option that actually forces both (i,j) and (j,i) into the
		// edgelist (so an undirected network's recode applies
		// symmetrically, not just to the upper triangle) is "full".
		nwtoedge `onenet', full
		recode `onenet' `rules', `options'		
		// was "_fromid _toid" - nwtoedge's actual default output
		// variable names are _ego/_alter (see nwtoedge.ado's own
		// ego()/alter() option defaults); _fromid/_toid never existed.
		qui nwfromedge _ego _alter `onenet', name(__temp_network)
		nwtomata __temp_network, mat(recodeNet)
		if "`generate'" == "" & "`prefix'" == "" {
			nwreplacemat `onenet', newmat(recodeNet)
		}
		else {
			if "`prefix'" != "" {
				nwduplicate `onenet', name(`prefix'`onenet')
				nwreplacemat `prefix'`onenet', newmat(recodeNet)
			}
			if "`generate'" != "" {
				if "``i''" != "" {
					nwduplicate `onenet', name(``i'')
					nwreplacemat ``i'', newmat(recodeNet)	
				}
				else {
					nwreplacemat `onenet', newmat(recodeNet)
				}
			}
		}
		capture nwdrop __temp_network
		mata: mata drop recodeNet
		local i = `i' + 1
		nwname `onenet', newdirected(`onedirected')
	}
	restore
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
