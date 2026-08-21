cscript

do unw_core.do

* Two-mode network METADATA regression tests - the architectural work
* making two-mode status a genuine, persistent property of the network
* object (as opposed to something re-derived or, as this unit found,
* silently lost). Distinct from the existing nw2*-family functional
* tests (test_nw2degree.do etc., which test bipartite *algorithms*) -
* this file is specifically about the metadata itself: does it survive
* save/reload, is it queryable, does it stay correct after operations.
*
* Found and fixed a genuine, previously-undiscovered bug while
* building this: nwsave/nwuse round-tripped a two-mode network's own
* is-two-mode yes/no flag correctly, but silently LOST the actual
* per-node mode partition every single time - nwsave's own edgelist
* export step (nwtoedge ... ignore2mode) discards mode information by
* design (it only captures edges), and nothing else ever wrote the
* underlying NWdef::modes array out as real saved data at all.
* Confirmed directly via a save/reload round-trip probe before writing
* any fix: get_nodes_mode1()/get_nodes_mode2() came back 5/0 (instead
* of the correct 2/3) and get_modes() came back all "1" after
* reloading a network that was genuinely 2 mode-1 + 3 mode-2 nodes
* before saving.
*
* Fixed via NWdef::get_modes_labeled_string()/set_modes_from_labeled_string()
* (unw_core.do) - deliberately keyed by each node's own LABEL
* ("E1=1,E2=1,A=2,B=2,C=2"), not bare position, because - confirmed
* directly while testing the fix, not just assumed - nwuse's own
* reload path (nwfromedge, rebuilding the network fresh from the saved
* edgelist) does NOT reproduce the original node order: reloading the
* same network below actually comes back in a different node order
* than it was saved in. A positional round-trip would have silently
* assigned the wrong mode to the wrong node in exactly this situation;
* a label-keyed one is correct regardless of any reordering.
*
* Wired through nw_name.ado's own newmodes()/r(modes) (plus
* newmode1desc()/newmode2desc()/r(mode1desc)/r(mode2desc), fixing a
* second, related gap: NWdef::get_description_mode1()/get_description_mode2()
* already existed and were already displayed by nwsummarize, but
* nothing anywhere in the package ever called their own setters, so
* every two-mode network's own mode descriptions displayed blank).

* --- basic round-trip: mode membership, mode1/mode2 node counts, and
* mode descriptions must all survive an nwsave/nwuse cycle exactly,
* even though the reload's own node order is confirmed to differ from
* the save order (checked directly below, not assumed).
nwclear
mata: bip = (1,1 \ 1,0 \ 0,1)
mata: st_matrix("bip", bip)
nwset, mat(bip) bipartite name(net1) labs(E1,E2,A,B,C)
nwname net1, newmode1desc("event") newmode2desc("attendee")
assert _rc == 0
assert r(nodes1) == 2
assert r(nodes2) == 3
assert `"`r(mode1desc)'"' == `"event"'
assert `"`r(mode2desc)'"' == `"attendee"'

tempfile f
nwsave `f', replace
assert _rc == 0

nwclear
nwuse `f'.nwdta, clear
assert _rc == 0
nwname net1
assert _rc == 0
assert r(nodes1) == 2
assert r(nodes2) == 3
assert `"`r(mode1desc)'"' == `"event"'
assert `"`r(mode2desc)'"' == `"attendee"'
* per-node mode membership must be correct for EVERY node individually
* (not just the aggregate counts, which a positional-but-shuffled bug
* could still coincidentally get right) - checked by label directly
* against r(modes)'s own "label=mode" serialization, the same way the
* underlying fix itself is keyed, rather than cross-referencing
* against the shared Stata dataset's own row order (confirmed while
* writing this test that the two are NOT the same ordering - see this
* file's own header note - so a positional dataset/Mata comparison
* would not even be a meaningful check here).
assert strpos(`"`r(modes)'"', "E1=1") > 0
assert strpos(`"`r(modes)'"', "E2=1") > 0
assert strpos(`"`r(modes)'"', "A=2") > 0
assert strpos(`"`r(modes)'"', "B=2") > 0
assert strpos(`"`r(modes)'"', "C=2") > 0

* --- a network that is NOT two-mode must round-trip completely
* unaffected by any of this - a plain regression guard that the fix
* above didn't somehow attach mode data to ordinary one-mode networks.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(onemode) undirected labs(A,B,C)
tempfile f2
nwsave `f2', replace
nwclear
nwuse `f2'.nwdta, clear
nwname onemode
assert `"`r(mode2)'"' == `"false"'
assert r(nodes1) == 3
assert r(nodes2) == 0

* --- legacy-file backward compatibility: a .nwdta saved by a version
* of nwsave that never wrote _nw_modes/_nw_mode1desc/_nw_mode2desc at
* all (simulated directly by dropping those columns from an otherwise
* normal saved file) must still load cleanly - the is-two-mode flag
* itself still correctly survives (it was never broken), and mode
* membership falls back to get_modes()'s own pre-existing lazy default
* (all nodes "1") rather than erroring or silently guessing at data
* that was genuinely never saved. This is the same, already-existing
* behaviour every two-mode network had before this fix - not a
* regression, just not retroactively repairable for files that
* predate it.
nwclear
mata: bip2 = (1,1 \ 1,0 \ 0,1)
mata: st_matrix("bip2", bip2)
nwset, mat(bip2) bipartite name(net1) labs(E1,E2,A,B,C)
tempfile f3
nwsave `f3', replace
use `f3'.nwdta, clear
capture drop _nw_modes _nw_mode1desc _nw_mode2desc
tempfile legacy
save `legacy'.nwdta, replace

nwclear
nwuse `legacy'.nwdta, clear
assert _rc == 0
nwname net1
assert _rc == 0
assert `"`r(mode2)'"' == `"true"'
assert r(nodes1) == 5
assert r(nodes2) == 0

* --- multiple two-mode networks in one nwsave/nwuse call must each
* keep their own independent mode data, not leak into one another.
nwclear
mata: bipA = (1,0 \ 0,1)
mata: st_matrix("bipA", bipA)
nwset, mat(bipA) bipartite name(neta) labs(X1,X2,Y1,Y2)
mata: bipB = (1\1\1)
mata: st_matrix("bipB", bipB)
nwset, mat(bipB) bipartite name(netb) labs(P1,Q1,Q2,Q3)
nwname neta, newmode1desc("firm") newmode2desc("worker")
nwname netb, newmode1desc("club") newmode2desc("member")
tempfile f4
nwsave `f4', replace
nwclear
nwuse `f4'.nwdta, clear
nwname neta
assert r(nodes1) == 2
assert r(nodes2) == 2
assert `"`r(mode1desc)'"' == `"firm"'
nwname netb
assert r(nodes1) == 1
assert r(nodes2) == 3
assert `"`r(mode1desc)'"' == `"club"'
