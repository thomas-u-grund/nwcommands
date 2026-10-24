* nwergm tutorial 2: terms and model specification
* Requires the core nwcommands and the package nwergm.

nwergm version

* ---- dyad-independent terms: the mesa high school friendship network
nwwebuse mesa, nwclear
describe
tabulate race
tabulate sex
tabulate grade

* node attributes in nwergm must be numeric: encode the string variables
encode race, generate(race_n)
encode sex, generate(sex_n)

nwergm mesa, edges
nwergm mesa, edges nodematch(grade)
nwergm mesa, edges nodematch(grade race_n sex_n)
nwergm mesa, edges nodematch(grade) nodematchdiff(sex_n)
nwergm mesa, edges nodematch(grade) nodefactor(race_n) nodemix(sex_n)

* ---- dyad-dependent terms: the Lazega lawyers' friendship network (directed)
nwwebuse lazega, nwclear
encode practice, generate(prac)
nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority)
nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority) gwesp(0.5) seed(1)
nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority) gwesp(1) seed(1)
nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority) gwesp(0.5) gwidegree(0.5) seed(1)
