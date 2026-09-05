* Tutorial 6: Manipulating Networks
* Run from a directory with nwcommands net-installed (not a dev checkout).

* Subsetting: keep only the nodes satisfying a condition on an attribute
nwwebuse florentine, nwclear
nwsummarize flomarriage
nwsubset flomarriage if wealth > 50
nwsummarize flomarriage_sub

* Collapsing: merge nodes together - the collapsed node inherits every
* tie either of the original nodes had
nwrandom 8, prob(.3) name(mynet)
nwsummarize mynet
gen att = _n
replace att = 1 in 2
nwcollapse mynet, by(att) generate(mynet_collapsed)
nwsummarize mynet_collapsed

* Symmetrizing: turn a directed network into an undirected one
nwwebuse glasgow, nwclear
nwsummarize glasgow1
nwsymmetrize glasgow1, generate(glasgow1_sym)
nwsummarize glasgow1_sym
nwsym glasgow1_sym, check

* Recoding: remap dyad values according to arbitrary rules
clear
mata: M = (0,1,3 \ 2,0,1 \ 0,2,0)
nwset, mat(M) name(scores) directed labs(A,B,C)
nwsummarize scores, mat
nwrecode scores (1=10) (2=20) (3=30), generate(scores_recoded)
nwsummarize scores_recoded, mat

* Dichotomizing: the common special case of recoding at a single cutoff
clear
mata: M = (0,150,40 \ 90,0,220 \ 60,30,0)
nwset, mat(M) name(trade) directed labs(A,B,C)
nwsummarize trade, mat
nwdichotomize trade, threshold(100) generate(trade_binary)
nwsummarize trade_binary, mat
