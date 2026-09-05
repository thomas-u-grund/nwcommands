cscript

do unw_core.do

* nwconstraint had zero test coverage and zero documentation before this
* session (nwalphabetical.sthlp/nwtopical.sthlp both listed it as "no
* help file yet"). Computes Burt's (1992) dyadic constraint matrix
* c_ij = (p_ij + sum_q p_iq*p_qj)^2, where p_ij = a_ij / rowsum(a_i.),
* and stores it as a NEW network (not a per-node Stata variable) via
* nwset, mat(c) - a real, if unusual, design choice, verified here and
* documented rather than silently assumed.

* --- star network: A is the center, tied to B, C, D; B/C/D have no
* direct ties to each other. Hand-computed (undirected, unweighted),
* p_ij = a_ij / rowsum(a_i.):
*   p_AB = p_AC = p_AD = 1/3 (A's degree is 3, split evenly)
*   p_BA = p_CA = p_DA = 1   (each leaf's only tie is to A)
* p2 = p*p (indirect two-step paths): A's row of p2 is all 0 (A's
* only neighbors B/C/D have no outgoing ties of their own besides
* back to A, which lands on the zeroed diagonal). But each leaf DOES
* pick up an indirect p2 term toward every other leaf via the shared
* hub A, e.g. p2[B,C] = p[B,A]*p[A,C] = 1*(1/3) = 1/3 - a length-2
* path B->A->C - even though B and C have no direct tie:
*   c_AB = c_AC = c_AD = (1/3 + 0)^2 = 1/9
*   c_BA = c_CA = c_DA = (1   + 0)^2 = 1
*   c_BC = c_BD = c_CD = (0 + 1/3)^2 = 1/9
* Textbook check: aggregate constraint of a node with n mutually
* disconnected direct contacts is 1/n (maximum structural holes),
* since only the direct term contributes to that node's own row; A's
* row sums to 3*(1/9) = 1/3, matching n=3.
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starnet) undirected labs(A,B,C,D)
nwconstraint starnet, name(starconstraint)
nwtomata starconstraint, mat(C1)
mata: assert(reldif(C1[1,2], 1/9) < 1e-8)
mata: assert(reldif(C1[1,3], 1/9) < 1e-8)
mata: assert(reldif(C1[1,4], 1/9) < 1e-8)
mata: assert(C1[2,1] == 1)
mata: assert(C1[3,1] == 1)
mata: assert(C1[4,1] == 1)
mata: assert(reldif(C1[2,3], 1/9) < 1e-8)
mata: assert(reldif(C1[2,4], 1/9) < 1e-8)
mata: assert(reldif(C1[3,4], 1/9) < 1e-8)
* the diagonal is not part of the stored network (no self-ties), and
* follows this package's standard convention of "." for such cells
* (see e.g. cscripts/test_nwsimindex.do)
mata: assert(C1[1,1] == .)
mata: assert(reldif(sum(C1[1,2..4]), 1/3) < 1e-8)

* --- directed star: A -> B, A -> C, A -> D only (leaves have no ties
* at all, not even back to A). The command uses the raw adjacency
* matrix directly (not symmetrized) for p_ij, so a purely outbound
* star gives A the same dyadic values as the undirected case (A's own
* row is identical to the undirected case above), while each leaf -
* now with rowsum 0 - gets p_leaf,* = 0/0, edited to 0 by
* _editmissing(), i.e. leaves show zero constraint toward A (not
* symmetric with the undirected case, since a leaf has no outgoing
* tie in the directed version at all). This is the command's actual,
* asymmetric treatment of directed input - documented, not silently
* assumed.
nwclear
nwset, mat((0,1,1,1\0,0,0,0\0,0,0,0\0,0,0,0)) name(dirstarnet) directed labs(A,B,C,D)
nwconstraint dirstarnet, name(dirconstraint)
nwtomata dirconstraint, mat(C2)
mata: assert(reldif(C2[1,2], 1/9) < 1e-8)
mata: assert(reldif(C2[1,3], 1/9) < 1e-8)
mata: assert(reldif(C2[1,4], 1/9) < 1e-8)
mata: assert(C2[2,1] == 0)
mata: assert(C2[3,1] == 0)
mata: assert(C2[4,1] == 0)

* --- weighted (valued) network: tie strength is used directly as
* investment proportion (W1, native - not treated as distance). A-B
* has weight 2, A-C has weight 1, A-D has weight 1 (rowsum for A = 4).
nwclear
nwset, mat((0,2,1,1\2,0,0,0\1,0,0,0\1,0,0,0)) name(wstarnet) undirected labs(A,B,C,D)
nwconstraint wstarnet, name(wconstraint)
nwtomata wconstraint, mat(C3)
mata: assert(reldif(C3[1,2], (2/4)^2) < 1e-8)
mata: assert(reldif(C3[1,3], (1/4)^2) < 1e-8)
mata: assert(reldif(C3[1,4], (1/4)^2) < 1e-8)

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwconstraint nonexistent
assert _rc == 482
