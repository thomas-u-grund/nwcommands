* nwsbm tutorial 1: a stochastic block model for the karate club
* Requires the core nwcommands and the package nwsbm. The data (Zachary 1977) are loaded from the nwcommands website.
set linesize 80

nwwebuse zachary, nwclear
nwsummarize zachary_bin

* --- fit block models with one to five blocks and select the number of blocks by the ICL ---
nwsbm zachary_bin, maxblocks(5) seed(20261120) generate(block) replace

* --- the model selection table again, and the blocks ---
estat icl
estat blocks

* --- plots: blocked adjacency matrix, block graph, ICL curve, memberships ---
nwsbmplot, type(matrix) shade export(nwsbm1_matrix.png)
nwsbmplot, type(blocks) export(nwsbm1_blocks.png)
nwsbmplot, type(icl) export(nwsbm1_icl.png)
nwsbmplot, type(membership) export(nwsbm1_membership.png)

* --- how do the blocks relate to the two factions of the club? ---
tabulate block group

* --- force three blocks ---
nwsbm zachary_bin, blocks(3) seed(20261120) generate(block3) replace
tabulate block3 group
