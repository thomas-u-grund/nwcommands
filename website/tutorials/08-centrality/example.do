* Tutorial 7: Centrality
* Run from a directory with nwcommands net-installed (not a dev checkout).

nwwebuse florentine, nwclear

* Degree: how many ties does each node have
nwdegree flomarriage, generate(deg)

* Betweenness: how often does a node sit on the shortest path between others
nwbetween flomarriage, generate(btw)

* Closeness: how short are a node's paths to everyone else
nwcloseness flomarriage, generate(clo far near)

* Eigenvector: connections to well-connected nodes count more
nwevcent flomarriage, generate(evc)

* PageRank: stationary distribution of a random surfer following ties
nwpagerank flomarriage, generate(pgr)

* Katz: distance-decay reach, penalizing nodes that are further away
nwkatz flomarriage, generate(ktz)

* medici ranks near the top on betweenness and closeness despite a
* fairly ordinary degree - the different measures do not always agree
* on who the "most central" node is
gsort -btw
list _nwnode deg btw in 1/5

format clo evc pgr ktz %6.3f
list _nwnode deg btw clo evc pgr ktz if _nwnode == "medici"
