cscript
do unw_core.do

nwclear
nwset, mat((1,1,1\0,0,0\1,0,0))
nwdegree

assert reldif( r(outdg_central)  , .75               ) <  1E-8
assert         r(indg_central)  == 0



nwclear
nwset, mat((0,1,0\0,0,0\1,0,0)) undirected
nwdegree

assert         r(dg_central) == 1


assert _degree[1] == 2
assert _degree[2] == 1
assert _degree[3] == 1


nwuse florentine, nwclear
nwdegree flomarriage, isolates
assert _isolate[12] == 1 

nwdegree flomarriage, isolates generate(myisolate)


* --- netlist (multi-network) support: harmonisation-phase fix. This
* command's own doc has always described this behavior ("In case
* degree centrality is calculated for z networks at the same time...
* the command generates the variables _outdegree_z and _indegree_z for
* each network"), but the code never actually implemented it - fixed
* here to do what it always claimed to do.
*
* Note: nw_datasync re-sorts the shared dataset to align "node i of
* whichever network was just synced" with "observation i" (its own
* documented behavior), so after processing two differently-ordered
* networks in one call, row numbers no longer correspond to a fixed
* node - look values up by _nwnode instead of assuming a row position.
nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) undirected name(net1) labs(A,B,C)
nwset, mat((0,1,0\1,0,1\0,1,0)) undirected name(net2) labs(X,Y,Z)

nwdegree net1 net2, silent
* multi-network default output naming: basevar_<netname>
confirm variable _degree_net1
confirm variable _degree_net2

gen __row = _n
sum __row if _nwnode == "A"
local rowA = r(mean)
sum __row if _nwnode == "X"
local rowX = r(mean)
assert _degree_net1[`rowA'] == 2
assert _degree_net2[`rowX'] == 1
drop __row

* single-network call remains completely unaffected: default names
* have no suffix
nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) undirected name(net1) labs(A,B,C)
nwdegree net1, silent
assert _degree[1] == 2

* replace guard still works for the multi-network case
nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) undirected name(net1) labs(A,B,C)
nwset, mat((0,1,0\1,0,1\0,1,0)) undirected name(net2) labs(X,Y,Z)
nwdegree net1 net2, silent
capture nwdegree net1 net2, silent
assert _rc != 0
nwdegree net1 net2, silent replace
assert _rc == 0

