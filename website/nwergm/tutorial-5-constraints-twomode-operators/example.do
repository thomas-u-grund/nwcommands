* nwergm tutorial 5: constraints, two-mode networks and operators
* Requires the core nwcommands and the package nwergm.

* ---- a constraint: keep the number of ties fixed
nwwebuse florentine, nwclear
nwergm flomarriage, edges nodecov(wealth) gwesp(0.5) seed(1)
nwergm flomarriage, edges nodecov(wealth) gwesp(0.5) constraints(edges) seed(1)

* ---- a two-mode network: 30 people by 12 clubs (simulated for this tutorial)
clear
set seed 20261024
nwclear
mata:
g1 = (runiform(30,1) :> 0.5) :+ 1
g2 = (runiform(12,1) :> 0.5) :+ 1
P = J(30,12,0.08)
for (i=1;i<=30;i++) for (j=1;j<=12;j++) if (g1[i]==g2[j]) P[i,j] = 0.30
B = (runiform(30,12) :< P)
st_matrix("B", B')
end
nwset, mat(B) bipartite name(clubs)
set obs 42
generate byte kind = .
mata: st_store(., "kind", (g1 \ g2))
nwsummarize
nwergm clubs, edges nodemix(kind)
nwergm clubs, edges nodemix(kind) bgwdegree2(0.5) seed(1)

* ---- operators (development version): terms evaluated on a derived network
nwergm clubs, edges nodemix(kind) operators(Proj1(edges triangle)) seed(1)
nwwebuse lazega, nwclear
encode practice, generate(prac)
nwergm lazega_fr, edges mutual nodematch(prac) operators(Symmetrize(triangle, rule(strong))) seed(1)
