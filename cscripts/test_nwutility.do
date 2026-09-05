cscript

do unw_core.do

* nwutility (Jackson & Wolinsky 1996 connections-model utility) had
* zero test coverage before this session, and did not work at all:
* nine distinct bugs, found and fixed together.
*
*  1-2. It used the deprecated _nwsyntax wrapper and then referenced
*       `nodes' (never re-exported by _nwsyntax - same bug class as
*       nwqap/nwcloseness/nworder this session), in both the default
*       and intrvalue()/intrcost() code paths. Fixed by switching to
*       _nwsyntax directly.
*  3.   intrvalue()/intrcost() called the separately-broken
*       _nwsyntax_other (incompatible with the modern architecture).
*       Fixed by switching to _nwsyntax there too - which also
*       exposed a real local-name collision (_nwsyntax's `netname'/
*       `nodes' exports would silently overwrite the main network's
*       own values when called a second time for intrvalue()/
*       intrcost()) - fixed by capturing the main network's name and
*       node count before any second call, and restoring the name
*       afterward.
*  4.   A genuine copy-paste bug: the intrcost() branch pulled its
*       matrix from `intrvalue' instead of `intrcost'.
*  5.   The geodesic-distance step called "_nwgeodesic" (underscore-
*       prefixed), which does not exist - the real command is
*       nwgeodesic - and routed the whole sub-command call through
*       nwgenerate's arithmetic-expression translator, which isn't
*       valid usage of that translator (the same misuse pattern
*       already found and fixed in nwkatz earlier this session).
*       Fixed by calling nwgeodesic directly, the same pattern
*       nwcloseness already uses.
*  6.   distance_distribution() computed max(geonet) to size its
*       result matrix, but the geodesic matrix's diagonal is missing
*       by this package's convention, and Mata's max() propagates a
*       missing value as the maximum - crashing with a conformability
*       error. Fixed by zeroing the diagonal before use (the
*       dist>0 check already correctly excludes it from the actual
*       tabulation).
*  7.   util_simple()'s loop used "i < cols(dd)" instead of
*       "i <= cols(dd)", silently dropping the longest-distance
*       bucket from every node's benefit sum.
*  8.   util_weighted() had the identical off-by-one in both its
*       loop bounds.
*  9.   util_weighted()'s inner loop used "geonet[i,j] >= 0" instead
*       of "> 0" - since the diagonal is 0 after the fix in #6, this
*       double-counted the self term (which is already added
*       separately via "+ diagonal(w)"), corrupting every row with a
*       missing value whenever the intrinsic-value network's own
*       diagonal was missing (the common case - see the selfloop
*       note below).
*
* Separately (not a code bug, but undocumented behavior worth
* stating plainly, per this package's harmonisation standard): the
* w_ii ("intrinsic self-value") term used by intrvalue() is read
* from that network's own diagonal, which nwset leaves missing
* unless the network was built with the selfloop option - documented
* in nwutility.sthlp, exercised explicitly below.

* --- default path (no intrvalue/intrcost): path-ish 4-node network
* A-B, A-C, B-C, C-D. Hand-computed with benefit=1, cost=1 (defaults):
*   dd[A,.] = {2 at dist 1 (B,C), 1 at dist 2 (D)} -> benefit=3, cost=2, util=1
*   dd[B,.] = {2 at dist 1 (A,C), 1 at dist 2 (D)} -> benefit=3, cost=2, util=1
*   dd[C,.] = {3 at dist 1 (A,B,D), 0 at dist 2}   -> benefit=3, cost=3, util=0
*   dd[D,.] = {1 at dist 1 (C),   2 at dist 2 (A,B)} -> benefit=3, cost=1, util=2
nwclear
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwutility net1
assert _benefit[1] == 3 & _cost[1] == 2 & _util[1] == 1
assert _benefit[2] == 3 & _cost[2] == 2 & _util[2] == 1
assert _benefit[3] == 3 & _cost[3] == 3 & _util[3] == 0
assert _benefit[4] == 3 & _cost[4] == 3 - 2
assert _util[4] == 2

* --- weighted path: intrvalue() (with selfloop, so w_ii is real, not
* missing) and intrcost(), benefit=1 so distance-decay is inert and
* every reachable dyad's raw intrinsic value counts once.
*   Row A: w[A,B]+w[A,C]+w[A,D] + w[A,A] = (2+3+0) + 5 = 10
*   Row B: w[B,A]+w[B,C]+w[B,D] + w[B,B] = (2+1+0) + 6 = 9
*   Row C: w[C,A]+w[C,B]+w[C,D] + w[C,C] = (3+1+4) + 7 = 15
*   Row D: w[D,A]+w[D,B]+w[D,C] + w[D,D] = (0+0+4) + 8 = 12
*   cost = rowsum(net1 :* costnet), costnet has the same 0/1 pattern
*   as net1, so cost = net1's own degree: A=2, B=2, C=3, D=1
nwclear
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwset, mat((5,2,3,0\2,6,1,0\3,1,7,4\0,0,4,8)) name(valnet) undirected labs(A,B,C,D) selfloop
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(costnet) undirected labs(A,B,C,D)
nwutility net1, intrvalue(valnet) intrcost(costnet)
assert _benefit[1] == 10 & _cost[1] == 2 & _util[1] == 8
assert _benefit[2] == 9  & _cost[2] == 2 & _util[2] == 7
assert _benefit[3] == 15 & _cost[3] == 3 & _util[3] == 12
assert _benefit[4] == 12 & _cost[4] == 1 & _util[4] == 11

* --- intrvalue() built WITHOUT selfloop: w_ii is missing by nwset's
* own default convention, and the command must say so loudly (a
* missing result), never substitute a plausible-looking wrong number
nwclear
nwset, mat((0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwset, mat((0,2,3,0\2,0,1,0\3,1,0,4\0,0,4,0)) name(valnet2) undirected labs(A,B,C,D)
nwutility net1, intrvalue(valnet2)
assert _benefit[1] == .
assert _util[1] == .


* --- alpha-audit regression: on a disconnected network, unreachable
* pairs are stored as MISSING geodesic distances - `dist[i,j] > 0' is
* TRUE for missing (Mata treats it as larger than any real value), so
* every unreachable pair was wrongly counted as reachable, and the
* missing VALUE itself was then used directly as a column index, which
* Mata silently interprets as the `.' (all-columns) selector instead of
* erroring - incrementing every distance bucket instead of one. Each
* node here (two disjoint dyads) has exactly 1 real neighbor at
* distance 1; the bug previously reported benefit=3/cost=3/util=0 for
* every node instead.
nwclear
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,1\0,0,1,0)) name(disconnnet) undirected
nwutility disconnnet
assert _benefit[1] == 1 & _cost[1] == 1 & _util[1] == 0
assert _benefit[2] == 1 & _cost[2] == 1 & _util[2] == 0
assert _benefit[3] == 1 & _cost[3] == 1 & _util[3] == 0
assert _benefit[4] == 1 & _cost[4] == 1 & _util[4] == 0

* same bug, weighted (intrvalue()/intrcost()) path: previously poisoned
* every node's result to missing instead of a wrong number.
nwclear
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,1\0,0,1,0)) name(disconnnet2) undirected
nwset, mat((5,2,3,0\2,6,1,0\3,1,7,4\0,0,4,8)) name(valnet3) undirected selfloop
nwset, mat((0,1,0,0\1,0,0,0\0,0,0,1\0,0,1,0)) name(costnet3) undirected
nwutility disconnnet2, intrvalue(valnet3) intrcost(costnet3)
assert _benefit[1] == 7  & _cost[1] == 1 & _util[1] == 6
assert _benefit[2] == 8  & _cost[2] == 1 & _util[2] == 7
assert _benefit[3] == 11 & _cost[3] == 1 & _util[3] == 10
assert _benefit[4] == 12 & _cost[4] == 1 & _util[4] == 11

* fully edgeless network: previously crashed outright ("subscript
* invalid"/conformability error) instead of the trivially-correct
* all-zero result (no ties anywhere, so benefit/cost/util are all 0).
nwclear
nwset, mat((0,0,0\0,0,0\0,0,0)) name(emptynet) undirected
nwutility emptynet
assert _rc == 0
assert _benefit[1] == 0 & _cost[1] == 0 & _util[1] == 0
assert _benefit[2] == 0 & _cost[2] == 0 & _util[2] == 0
assert _benefit[3] == 0 & _cost[3] == 0 & _util[3] == 0
di "=== DISCONNECTED/EDGELESS NETWORK REGRESSION VERIFIED ==="

* moderate-severity pass, stat_models group: a misspelled/nonexistent
* network name used to crash with a raw Mata error (r3301) instead of a
* clean message.
capture noisily nwutility typobogus
assert _rc == 482
di "=== misspelled network name REGRESSION VERIFIED ==="
