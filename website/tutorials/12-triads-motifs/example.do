* nwcommands tutorial 12: dyads, triads and motifs
* Requires the core nwcommands.
nwwebuse sampson, nwclear
nwsummarize samplike

* 1. The dyad census
nwdyads samplike

* 2. The triad census
nwtriads samplike

* 3. Clustering and transitivity
nwclustering samplike, generate(clu)
summarize clu

* 4. Motifs
nwmotifs samplike

* 5. Signed networks: structural balance
nwset, mat((0,1,1,-1\1,0,1,-1\1,1,0,1\-1,-1,1,0)) undirected labs(A,B,C,D) name(signed)
nwbalance signed
