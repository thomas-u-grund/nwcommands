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

* ...before filtering, capture every node label that appears in the
* full pairs list - this is the only place an isolate's label survives...
levelsof _ego, local(alllabels) clean

* ...now keep only the real ties (nwtoedge lists every possible pair, not
* just the ones that are actually connected)...
keep if glasgow1 == 1

* ...work out which labels from the full set never appear in the filtered
* edgelist at all - these are the isolates nwfromedge is about to drop...
levelsof _ego, local(remaininglabels) clean
levelsof _alter, local(alterlabels) clean
local remaininglabels : list remaininglabels | alterlabels
local isolatelabels : list alllabels - remaininglabels
display "`isolatelabels'"

* ...and turn what's left back into a network object again
nwfromedge _ego _alter, name(rebuilt)
nwsummarize rebuilt

* nwfromedge can only create nodes that appear in at least one tie, so the
* isolates identified above are missing from `rebuilt` - add them back
* explicitly with the labels the display above just gave us.
nwaddnodes rebuilt, nodenames(n13, n20, n50)
nwsummarize rebuilt
