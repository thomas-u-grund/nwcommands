* Tutorial 2: Core Concepts
* Run from a directory with nwcommands net-installed (not a dev checkout).

* A dataset that already declares more than one network at once
nwwebuse florentine
nwset

* the "current network" - the one commands act on when no netname is given
nwcurrent
nwcurrent flobusiness
nwcurrent

* netlist wildcard syntax, on a three-wave dataset
nwwebuse glasgow, nwclear
nwset
nwsummarize glasgow1 glasgow2 glasgow3
nwsummarize glasgow1-glasgow3
nwsummarize glasg*
nwsummarize _all

* networks coexist with ordinary Stata variables
nwclear
nwwebuse florentine
gen note = "wealthiest families"
describe
list note in 1
