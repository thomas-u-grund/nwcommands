cscript

do unw_core.do

* nwdropnodes had zero test coverage and was completely non-functional
* before this harmonisation unit - fixed alongside nwreplacemat's
* size-changing path (see that file's own test coverage), nwkeepnodes,
* and nwcompressobs, all part of the same long-blocked chain (open
* since harmonisation units 9-13, see docs/CERTIFICATION.md's Pending
* table history). Three distinct bugs, found and fixed together:
*
* (1) `_nwsyntax` (the deprecated wrapper) only re-exports 4 locals
* (netobj/id/netname/networks), but this file also needs `nodes' (the
* node count) - switched to `nw_syntax`, which does export it. The
* option-supplied `nodes' local (the node list to drop) is already
* fully consumed into `nodelist' before this call runs, so the two
* uses of the name never actually conflict in practice.
*
* (2) The legacy pre-2016 $nw_<id>/$nwlabs_<id> globals this file used
* to read for the current network's variable names/labels are never
* populated by the modern netobj/NWdef architecture (confirmed empty
* by direct testing) - replaced with nwname's own r(vars)/r(labs),
* the modern equivalents.
*
* (3) r(labs) is comma-separated, but the label-filtering loop below
* builds its own `newlabs' as a space-separated list (matching the
* `: word `i' of `labs'' extraction it does internally) - which then
* gets passed straight through to nwreplacemat's own labs() option,
* which (via nwrandom) expects comma-separated input. A first attempt
* left `newlabs' space-separated for that final hand-off too - which
* nwrandom's own labs() option silently misreads as a *single* label
* for the first node, auto-generating default labels for the rest,
* rather than erroring. Fixed by building `newlabs' comma-separated
* specifically for that hand-off, while `labs' itself (used only for
* the internal word-extraction) stays space-separated.

* --- 4-node undirected chain A-B-C-D. Dropping node 2 (B) must leave
* exactly A, C, D with only the C-D tie surviving (A had its only tie
* to B, now gone).
nwclear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwdropnodes net1, nodes(2)
assert _rc == 0
nwname net1
assert r(nodes) == 3
assert `"`r(labs)'"' == `"A,C,D"'
nwtomata net1, mat(M)
mata: assert(M[1,2] == 0)
mata: assert(M[1,3] == 0)
mata: assert(M[2,3] == 1)

* --- dropping by node label (not just integer index) must work too.
nwclear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(net2) undirected labs(A,B,C,D)
nwdropnodes net2, nodes(B)
assert _rc == 0
nwname net2
assert `"`r(labs)'"' == `"A,C,D"'

* --- dropping multiple nodes at once, from a 5-node cycle
* A-B-C-D-E-A: dropping B and D leaves A, C, E. Of their pairwise
* ties, only A-E survives (it was a direct edge in the original
* cycle, not routed through B or D); A-C and C-E both ran only
* through a now-dropped node, so neither survives.
nwclear
nwset, mat((0,1,0,0,1\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\1,0,0,1,0)) name(net3) undirected labs(A,B,C,D,E)
nwdropnodes net3, nodes(2 4)
assert _rc == 0
nwname net3
assert r(nodes) == 3
assert `"`r(labs)'"' == `"A,C,E"'
nwtomata net3, mat(M2)
mata: assert(M2[1,2] == 0)
mata: assert(M2[1,3] == 1)
mata: assert(M2[2,3] == 0)

* --- directed networks: dropping the sole intermediary in a directed
* chain A->B->C->D must leave A completely isolated (its only tie
* was to B) while C->D survives, and the network must still be
* recognized as directed afterward.
nwclear
nwset, mat((0,1,0,0\0,0,1,0\0,0,0,1\0,0,0,0)) name(dnet) directed labs(A,B,C,D)
nwdropnodes dnet, nodes(2)
assert _rc == 0
nwname dnet
assert `"`r(directed)'"' == `"true"'
assert `"`r(labs)'"' == `"A,C,D"'
nwtomata dnet, mat(M3)
mata: assert(sum(M3[1,.]) == 0)
mata: assert(M3[2,3] == 1)

* --- downstream commands must correctly respect the network's own
* (now-shrunk) node count and labels, not the shared dataset's own
* row count (which can retain an inert, _nwinclude==0 leftover row for
* a dropped node - by design, since the same shared dataset can still
* be backing other currently-tracked networks that still use that
* node label; not itself a bug, see docs/CERTIFICATION.md's own note
* on this).
nwclear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(net4) undirected labs(A,B,C,D)
nwdropnodes net4, nodes(2)
nwsummarize net4
assert r(nodes) == 3
nwdegree net4
assert _degree[1] == 0

* --- generate(): leaves the source network untouched and produces the
* modified copy under a new name (found genuinely broken while dealing
* with xvars consistently project-wide - this always crashed with
* "option xvars not allowed", since the internal nwduplicate call this
* option relies on unconditionally passed a hardcoded xvars literal
* that nwduplicate.ado's own syntax has never accepted at all).
nwclear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) name(net5) undirected labs(A,B,C,D)
nwdropnodes net5, nodes(2) generate(net5_dropped)
assert _rc == 0
nwsummarize net5
assert r(nodes) == 4
nwsummarize net5_dropped
assert r(nodes) == 3

* --- alpha-audit regression: attributes() used to silently desync
* attribute values from the surviving nodes on any size-changing drop -
* nwreplacemat (called internally, just before this attribute-sync
* block) physically reorders the dataset's own rows to match the new
* node order, but the attribute values were read AFTER that reorder
* using a select-mask built against the OLD (pre-reorder) row order,
* pairing every surviving node with the wrong neighbor's original
* value. Confirmed fixed for a single attribute, multiple attributes at
* once, and via nwkeepnodes' own delegation to this same code path.
nwclear
nwset, mat((0,1,0,0\1,0,1,0\0,1,0,1\0,0,1,0)) undirected labs(A,B,C,D) name(attnet)
gen myattr = _n * 10
nwdropnodes attnet, nodes(2) attributes(myattr)
assert myattr[1] == 10
assert myattr[2] == 30
assert myattr[3] == 40
assert _nwnode[1] == "A"
assert _nwnode[2] == "C"
assert _nwnode[3] == "D"
di "=== attributes() desync REGRESSION VERIFIED ==="
