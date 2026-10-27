* nwsaom tutorial 7: changing actor sets and missing data
* Requires the core nwcommands and the package nwsaom.

nwwebuse glasgow, nwclear

* Baseline: the complete data
nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip seed(4)

* ---------------------------------------------------------------
* Part 1: composition change. We pretend that pupils 1-4 joined the
* school after wave 1 and that pupils 5-7 left after wave 2.
* An absent actor's ties must be coded 0 before the actor joins and
* kept at the last observed values after the actor leaves.
* ---------------------------------------------------------------
nwtomata glasgow1, mat(G1)
nwtomata glasgow2, mat(G2)
nwtomata glasgow3, mat(G3)
mata:
G1[1::4, .] = J(4, 50, 0)
G1[., 1::4] = J(50, 4, 0)
G3[5::7, .] = G2[5::7, .]
G3[., 5::7] = G2[., 5::7]
st_matrix("C1", G1)
st_matrix("C2", G2)
st_matrix("C3", G3)
end
nwset, mat(C1) directed name(comp1)
nwset, mat(C2) directed name(comp2)
nwset, mat(C3) directed name(comp3)

* One 0/1 variable per wave: is the pupil present?
generate byte pres1 = _n > 4
generate byte pres2 = 1
generate byte pres3 = !inrange(_n, 5, 7)
tabulate pres1
tabulate pres3

nwsaom, waves(comp1 comp2 comp3) outdegree reciprocity transtrip present(pres1 pres2 pres3) seed(4)

* What goes wrong if the model is not told about the changes
nwsaom, waves(comp1 comp2 comp3) outdegree reciprocity transtrip seed(4)

* Joiners and leavers at times inside a period (RSiena's time scale:
* wave 1 = time 1, wave 3 = time 3). Pupils 1-4 join at time 1.5,
* pupils 5-7 leave at time 2.5. An actor who is absent at a wave
* has no ties in that wave's data.
mata:
T1 = G1
T3 = G3
T3[5::7, .] = J(3, 50, 0)
T3[., 5::7] = J(50, 3, 0)
st_matrix("T1", T1)
st_matrix("T2", G2)
st_matrix("T3", T3)
end
nwset, mat(T1) directed name(timed1)
nwset, mat(T2) directed name(timed2)
nwset, mat(T3) directed name(timed3)
generate double jn = 1
replace jn = 1.5 if _n <= 4
generate double lv = 3
replace lv = 2.5 if inrange(_n, 5, 7)
nwsaom, waves(timed1 timed2 timed3) outdegree reciprocity transtrip joinat(jn) leaveat(lv) seed(4)

* ---------------------------------------------------------------
* Part 2: missing data. Pupils 8 and 9 did not answer in wave 2:
* their nominations are unknown (missnet), and so are their alcohol
* values (missbeh).
* ---------------------------------------------------------------
mata:
M2 = J(50, 50, 0)
M2[8::9, .] = J(2, 50, 1)
_diag(M2, 0)
st_matrix("miss1", J(50, 50, 0))
st_matrix("miss2", M2)
st_matrix("miss3", J(50, 50, 0))
end
generate byte mb1 = 0
generate byte mb2 = inlist(_n, 8, 9)
generate byte mb3 = 0

nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip missnet(miss1 miss2 miss3) seed(4)

nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt missbeh(mb1 mb2 mb3) seed(4)
