* nwcommands tutorial 13: positions and structural equivalence
* Requires the core nwcommands.
set graphics off
nwwebuse sampson, nwclear
nwsummarize samplike

* 1. How different are two nodes' tie profiles?
nwdissimilar samplike, type(euclidean) name(dist)
nwdissimilar samplike, type(jaccard) name(jdist)
nwsimilar samplike, name(sim)
nwsummarize sim

* 2. Hierarchical clustering of the nodes
nwhierarchy samplike, type(jaccard) linkage(averagelinkage) groups(3) equivgen(equiv)
tabulate equiv faction
nwdendrogram _nwhierarchy_role, label(_nwnode)
graph export "dendrogram_sampson.svg", replace

* 3. Blocks with CONCOR
nwconcor samplike, generate(block) splits(2)
tabulate block faction

* 4. Spectral partition
nwspectral samplike, generate(fiedler) bipartition
tabulate fiedlersign faction
