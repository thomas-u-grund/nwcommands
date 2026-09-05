* Tutorial 3: Importing & Exporting
* Run from a directory with nwcommands net-installed (not a dev checkout).

* Import a plain edgelist straight from a URL - no local download needed
nwimport "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master/data/edgelist_example.txt", type(edgelist)
nwsummarize

* Export to Pajek and UCINET formats
nwwebuse florentine, nwclear
nwexport flomarriage, type(ucinet) replace
nwexport flobusiness, type(pajek) replace

* Round-trip: turn an existing network into a plain edgelist dataset...
nwwebuse glasgow, nwclear
nwtoedge glasgow1
describe
list in 1/5

* ...keep only the real ties (nwtoedge lists every possible pair, not
* just the ones that are actually connected)...
keep if glasgow1 == 1

* ...and turn that back into a network object again
nwfromedge _ego _alter, name(rebuilt)
nwsummarize rebuilt
