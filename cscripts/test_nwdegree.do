cscript
do unw_core.do

nwclear
nwset, mat((1,1,1\0,0,0\1,0,0))
* generate() is required (suite-wide generate()-required style decision,
* 2026-09-05) - nwdegree's whole purpose is producing this variable, so
* there is no default name to silently fall back to anymore, matching
* Stata's own egen/predict convention.
nwdegree, generate(_outdegree _indegree)

assert reldif( r(outdg_central)  , .75               ) <  1E-8
assert         r(indg_central)  == 0

* --- real, severe bug found and fixed: the DEFAULT (no explicit
* generate()) directed-network output variables used to be silently
* swapped - the variable named "_indegree" actually held outdegree
* values, and vice versa. The centralization r()-results above were
* always correct (computed straight from the underlying Mata vectors,
* never routed through these Stata variable names), which is exactly
* why this went undetected - nothing in this file ever checked the
* actual per-node _indegree/_outdegree variable values on a directed
* network before now. Node 1 here has out-ties to nodes 2 and 3
* (outdegree 2) and one in-tie from node 3 (indegree 1, self-loop
* diagonal not counted) - hand-computable directly from the matrix.
assert _indegree[1] == 1
assert _outdegree[1] == 2
assert _indegree[2] == 1
assert _outdegree[2] == 0
assert _indegree[3] == 1
assert _outdegree[3] == 1



nwclear
nwset, mat((0,1,0\0,0,0\1,0,0)) undirected
nwdegree, generate(_degree)

assert         r(dg_central) == 1


assert _degree[1] == 2
assert _degree[2] == 1
assert _degree[3] == 1


nwwebuse florentine, nwclear
nwdegree flomarriage, generate(_degree) isolates
assert _isolate[12] == 1

* isolates + a partial generate() (1 word, undirected needs 2 slots:
* degree, isolate) now correctly gives isolate its own genuine
* variable rather than aliasing the single given name to both the
* degree computation and the isolate flag (which used to silently
* overwrite the degree values with the isolate indicator right after
* computing them) - see nwdegree.ado's own bugfix comment. That
* variable defaults to the same "_isolates" name the bare "isolates"
* call above already created, so this needs replace, exactly like any
* other nwdegree call that would otherwise collide with an existing
* variable.
nwdegree flomarriage, isolates generate(myisolate) replace

* --- isolates on a DIRECTED network without an explicit generate()
* used to crash hard: "isolates" alone (no generate()) replaced the
* whole output-name list with the single word "_isolates" regardless
* of directedness, leaving `_indegree' empty and `_outdegree' aliased
* to "_isolates" - "capture generate `_indegree' = ." silently no-oped
* on the empty name, and the very next "mata: st_store(...,
* "`_indegree'", ...)" (not wrapped in capture) crashed passing
* st_store() an empty variable-name string. Confirmed via a direct
* probe before this fix (a 4-node directed star A->B,C,D): "nwdegree,
* isolates" crashed outright. Hand-computable: A has out-ties to
* B/C/D (isolates==0), B/C/D each have exactly one in-tie from A
* (isolates==0 too) - nobody is actually isolated in this network, so
* this also exercises the "no isolates found" path, not just "does it
* crash".
nwclear
nwset, mat((0,1,1,1\0,0,0,0\0,0,0,0\0,0,0,0)) directed labs(A,B,C,D)
nwdegree, generate(_outdegree _indegree) isolates
assert _rc == 0
assert _isolates[1] == 0
assert _isolates[2] == 0
assert _isolates[3] == 0
assert _isolates[4] == 0

* a genuine isolate (E, no ties at all) on a directed network - the
* same call must correctly flag it, not just avoid crashing.
nwclear
nwset, mat((0,1,1,1,0\0,0,0,0,0\0,0,0,0,0\0,0,0,0,0\0,0,0,0,0)) directed labs(A,B,C,D,E)
nwdegree, generate(_outdegree _indegree) isolates
assert _rc == 0
assert _isolates[5] == 1
assert _isolates[1] == 0

* the documented worked example (this file's own doc header) -
* generate() supplying ALL three names (out, in, isolate) explicitly
* alongside isolates on a directed network - used to silently corrupt
* the FIRST given name ("myout", meant to hold real outdegree
* centrality values) by overwriting it with the 0/1 isolate indicator
* right after computing it, and never actually created "mysiolate" at
* all (the isolate-name local resolved to word 1 unconditionally,
* aliasing it to whatever the outdegree name was). Checked directly:
* myout must hold real outdegree centrality, not an isolate flag, and
* mysiolate must exist and hold the actual isolate indicator.
nwclear
nwset, mat((0,1,1,1\0,0,0,0\0,0,0,0\0,0,0,0)) directed labs(A,B,C,D)
nwdegree, generate(myout myin mysiolate) isolates
assert _rc == 0
assert myout[1] == 3
assert myin[1] == 0
assert mysiolate[1] == 0
assert myout[2] == 0
assert myin[2] == 1
assert mysiolate[2] == 0


* --- netlist (multi-network) support: harmonisation-phase fix. This
* command's own doc has always described this behavior ("In case
* degree centrality is calculated for z networks at the same time...
* the command generates the variables _outdegree_z and _indegree_z for
* each network"), but the code never actually implemented it - fixed
* here to do what it always claimed to do.
*
* Note: _nwdatasync re-sorts the shared dataset to align "node i of
* whichever network was just synced" with "observation i" (its own
* documented behavior), so after processing two differently-ordered
* networks in one call, row numbers no longer correspond to a fixed
* node - look values up by _nwnode instead of assuming a row position.
nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) undirected name(net1) labs(A,B,C)
nwset, mat((0,1,0\1,0,1\0,1,0)) undirected name(net2) labs(X,Y,Z)

nwdegree net1 net2, generate(_degree) silent
* multi-network output naming: basevar_<netname>, applied to whatever
* base name generate() gives (generate() itself is now required)
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

* single-network call remains completely unaffected: names have no
* suffix when only one network is being processed
nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) undirected name(net1) labs(A,B,C)
nwdegree net1, generate(_degree) silent
assert _degree[1] == 2

* replace guard still works for the multi-network case
nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) undirected name(net1) labs(A,B,C)
nwset, mat((0,1,0\1,0,1\0,1,0)) undirected name(net2) labs(X,Y,Z)
nwdegree net1 net2, generate(_degree) silent
capture nwdegree net1 net2, generate(_degree) silent
assert _rc != 0
nwdegree net1 net2, generate(_degree) silent replace
assert _rc == 0

* missing_test finding, centrality group: 1- and 2-node networks were
* never exercised - degenerate edge cases that surfaced real crashes
* elsewhere in this same group (nwdropnodes, unit 6).
nwclear
nwset, mat((0)) name(single1) labs(A)
capture noisily nwdegree single1, generate(_outdegree _indegree) silent
assert _rc == 0

nwclear
nwset, mat((0,1\1,0)) name(two1) undirected labs(A,B)
capture noisily nwdegree two1, generate(_degree) silent
assert _rc == 0
assert _degree[1] == 1
assert _degree[2] == 1
di "=== 1-node/2-node edge case REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwdegree nonexistent, generate(_degree)
assert _rc == 482

* --- generate() is now required: omitting it errors cleanly (suite-wide
* generate()-required style decision, 2026-09-05), matching Stata's own
* egen/predict convention rather than silently falling back to a
* default-named variable.
nwclear
nwset, mat((0,1\1,0)) name(two2) undirected labs(A,B)
capture noisily nwdegree two2
assert _rc == 198
di "=== generate()-required REGRESSION VERIFIED ==="

