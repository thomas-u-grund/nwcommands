capture program drop _nwdirnote
program _nwdirnote
	// One printed line saying how a directed network was treated:
	//   _nwdirnote, directed(true|false) symdo(0|1) [text(string) indent(#)]
	// symdo = 1: option sym was given and the network is directed; directed(true) and symdo = 0: text() says what
	// the measure does with the direction; directed(false): "(undirected network)".
	syntax , directed(string) symdo(integer) [text(string) indent(integer 4)]
	if `symdo' {
		di "{txt}{p `indent' `indent' 2}(directed network symmetrized: the larger of the two directions of a tie){p_end}"
	}
	else if "`directed'" == "true" {
		di "{txt}{p `indent' `indent' 2}(`text'){p_end}"
	}
	else {
		di "{txt}{p `indent' `indent' 2}(undirected network){p_end}"
	}
end
