* Tutorial 8: Paths & Ego Networks
* Run from a directory with nwcommands net-installed (not a dev checkout).

nwwebuse florentine, nwclear

* Geodesics: shortest-path distance between every pair of nodes
nwgeodesic flomarriage, name(flodist) generate(ecc)
return list
nwsummarize flodist, mat

* Eccentricity: the longest shortest path FROM each node
gsort -ecc
list _nwnode ecc in 1/5

* Reachability: which nodes can reach which others at all (ignoring
* distance) - useful when a network has disconnected components
nwreach flomarriage, sym name(floreach)
nwsummarize floreach, mat

* Ego networks: for each node, how many alters does it have, and how
* interconnected are those alters with each other
nwego flomarriage, sizevar(egosize) densvar(egodensity)
gsort -egosize
list _nwnode egosize egodensity in 1/5
