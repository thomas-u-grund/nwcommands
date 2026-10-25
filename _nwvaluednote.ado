capture program drop _nwvaluednote
program _nwvaluednote, rclass
	// One run-time line for a command that is binary by definition (igraph and
	// sna have no weighted variant either) but was given a valued network:
	//   _nwvaluednote <net> [, quiet]
	// r(shown) is 1 when the line was printed. The caller keeps its own
	// "already shown" flag so that a call with several networks prints it once.
	syntax anything(name=netname) [, quiet]
	return scalar shown = 0
	if "`quiet'" != "" exit
	_nwsyntax `netname', max(1)
	if "`valued'" == "true" {
		// printed by the caller (noisily inside a quietly block does not show from here)
		return local msg "{txt}(note: tie values are ignored; this measure is binary)"
		return scalar shown = 1
	}
end
